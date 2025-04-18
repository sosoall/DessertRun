//
//  WorkoutSession.swift
//  DessertRun
//
//  Created by Claude on 2023/5/25.
//

import SwiftUI
import Combine
import CoreLocation
import CoreMotion

// 导入LocationPoint类型
// 注意：Swift项目中通常需要确保LocationPoint类型的导入

// 让LocationPoint遵循Equatable协议，以便可以在数组上使用onChange(of:)
extension LocationPoint: Equatable {
    static func == (lhs: LocationPoint, rhs: LocationPoint) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude &&
               lhs.timestamp == rhs.timestamp
    }
}

/// 运动会话的状态
enum WorkoutSessionState {
    case inactive  // 未开始或已结束
    case active    // 活动中
    case paused    // 暂停中
}

/// 运动会话模型
class WorkoutSession: ObservableObject {
    // MARK: - 发布属性
    @Published var state: WorkoutSessionState = .inactive
    @Published var isCompleted: Bool = false
    
    @Published var totalElapsedSeconds: TimeInterval = 0
    @Published var distanceInMeters: Double = 0
    @Published var burnedCalories: Double = 0
    @Published var repetitionCount: Int = 0
    
    @Published var currentLocation: LocationPoint?
    @Published var currentSpeed: Double = 0
    @Published var locationHistory: [LocationPoint] = []
    
    /// 结束时间 - 用于判断运动是否结束
    @Published var endTime: Date?
    
    // MARK: - 公开属性
    let id = UUID()
    let targetDessert: DessertItem
    let exerciseType: ExerciseType
    
    /// 总距离（米）- 提供与 distanceInMeters 相同的值，用于兼容
    var totalDistance: Double {
        get { return distanceInMeters }
        set { distanceInMeters = newValue }
    }
    
    /// 总卡路里 - 提供与 burnedCalories 相同的值，用于兼容
    var totalCalories: Double {
        get { return burnedCalories }
        set { burnedCalories = newValue }
    }
    
    var targetCalories: Double {
        // 转换甜品卡路里字符串为Double类型
        if let caloriesDouble = Double(targetDessert.calories) {
            return caloriesDouble
        } else if let caloriesString = targetDessert.calories as? String,
                  let caloriesValue = Double(caloriesString.replacingOccurrences(of: "kcal", with: "").trimmingCharacters(in: .whitespaces)) {
            return caloriesValue
        }
        // 默认返回值，避免计算错误
        return 100.0
    }
    
    // MARK: - 私有属性
    private var startTime: Date?
    private var lastPausedTime: Date?
    private var totalPausedTime: TimeInterval = 0
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 管理器
    var locationManager: LocationManager?
    var motionManager: (any MotionManaging)?
    
    // MARK: - 添加状态标记，表示是否使用模拟数据
    @Published var isUsingSimulatedData: Bool = false
    
    // MARK: - 添加必要的成员变量
    private var lastDataUpdateTime: Date?
    
    // MARK: - 记录上次的步数，用于检测步数变化
    private var lastRecordedSteps: Int?
    
    // MARK: - 初始化
    init(targetDessert: DessertItem, exerciseType: ExerciseType) {
        self.targetDessert = targetDessert
        self.exerciseType = exerciseType
        
        print("【初始化】创建运动会话 - 目标甜品:\(targetDessert.name), 运动类型:\(exerciseType.name)")
        print("【初始化】运动数据 - MET值:\(exerciseType.metValue), 需要GPS:\(exerciseType.requiresGPS), 目标卡路里:\(targetCalories)")
        
        // 创建位置管理器
        self.locationManager = LocationManager()
        
        // 检测设备是否支持运动传感器
        let motionMgr = MotionManager()
        if motionMgr.sensorsAvailable {
            // 使用真实的运动管理器
            self.motionManager = motionMgr
            print("【初始化】使用真实运动数据 - 设备支持运动传感器")
        } else {
            // 使用模拟的运动管理器
            self.motionManager = MockMotionManager()
            print("【初始化】使用模拟运动数据 - 设备不支持运动传感器或权限不足")
        }
        
        // 打印关键配置
        if exerciseType.requiresGPS {
            print("【初始化】户外运动 - 将使用GPS记录路线和距离")
        } else {
            print("【初始化】室内运动 - 将使用计步器和动作感测")
        }
    }
    
    // MARK: - 公开方法
    /// 开始运动
    func startWorkout() {
        guard state == .inactive else { return }
        
        // 设置为活动状态
        state = .active
        
        // 设置开始时间
        startTime = Date()
        
        // 重置数据
        totalElapsedSeconds = 0
        distanceInMeters = 0
        burnedCalories = 0
        totalPausedTime = 0
        lastPausedTime = nil
        locationHistory = []
        endTime = nil  // 重置结束时间
        
        // 如果是户外运动，请求权限并启动位置追踪
        if exerciseType.requiresGPS {
            // 先请求权限
            locationManager?.requestAuthorization()
            // 确保在请求权限后再开始跟踪
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.locationManager?.startTracking()
            }
        }
        
        // 启动运动传感器追踪
        motionManager?.startTracking()
        
        // 设置监听器
        setupListeners()
    }
    
    /// 暂停运动
    func pauseWorkout() {
        guard state == .active else { return }
        
        // 设置状态为暂停
        state = .paused
        
        // 记录暂停时间
        lastPausedTime = Date()
        
        // 暂停位置追踪
        if exerciseType.requiresGPS {
            locationManager?.pauseTracking()
        }
        
        // 暂停运动追踪
        motionManager?.pauseTracking()
        
        print("运动会话已暂停")
    }
    
    /// 恢复运动
    func resumeWorkout() {
        guard state == .paused else { return }
        
        // 如果有上次暂停时间，计算暂停持续时间
        if let pausedTime = lastPausedTime {
            totalPausedTime += Date().timeIntervalSince(pausedTime)
            lastPausedTime = nil
        }
        
        // 设置状态为活动
        state = .active
        
        // 恢复位置追踪
        if exerciseType.requiresGPS {
            locationManager?.resumeTracking()
        }
        
        // 恢复运动追踪
        motionManager?.resumeTracking()
        
        print("运动会话已恢复")
    }
    
    /// 完成运动
    func completeWorkout() {
        // 确保已经开始
        guard startTime != nil else { return }
        
        // 更新最终数据
        updateWorkoutData()
        
        // 设置状态为不活动
        state = .inactive
        
        // 标记为已完成
        isCompleted = true
        
        // 设置结束时间
        endTime = Date()
        
        // 停止位置追踪
        locationManager?.stopTracking()
        
        // 停止运动追踪
        motionManager?.stopTracking()
        
        print("运动会话已完成")
    }
    
    /// 取消运动
    func cancelWorkout() {
        // 设置状态为不活动
        state = .inactive
        
        // 不标记为已完成
        isCompleted = false
        
        // 重置结束时间
        endTime = nil
        
        // 停止所有追踪
        locationManager?.stopTracking()
        motionManager?.stopTracking()
        
        print("运动会话已取消")
    }
    
    /// 更新运动数据
    func updateWorkoutData() {
        // 确保运动会话在活动状态
        guard state == .active else { return }
        
        // 记录当前时间
        let now = Date()
        
        // 计算从上次更新到现在的时间间隔
        var timeElapsed: TimeInterval = 0
        if let lastTime = lastDataUpdateTime {
            timeElapsed = now.timeIntervalSince(lastTime)
        }
        
        // 更新最后更新时间
        lastDataUpdateTime = now
        
        // 计算累计运行时间（仅在活动状态下且时间间隔合理时累加）
        if timeElapsed > 0 && timeElapsed < 5.0 { // 防止异常大的时间间隔
            totalElapsedSeconds += timeElapsed
        }
        
        // 根据运动类型处理不同的数据更新逻辑
        if exerciseType.requiresGPS {
            // GPS运动类型（如跑步、散步等）
            handleGPSBasedExercise(timeElapsed: timeElapsed)
        } else {
            // 非GPS运动类型（如室内锻炼）
            handleNonGPSExercise(timeElapsed: timeElapsed)
        }
    }
    
    private func handleGPSBasedExercise(timeElapsed: TimeInterval) {
        // 检查位置权限和数据可用性
        let hasLocationAccess = locationManager?.authorizationStatus == .authorizedWhenInUse || 
                               locationManager?.authorizationStatus == .authorizedAlways
        let hasValidLocationData = locationManager?.currentLocation != nil
        
        if hasLocationAccess {
            if hasValidLocationData {
                // 正常使用位置数据，不使用兜底 - 即使信号弱也如实记录
                isUsingSimulatedData = false
                updateDistanceAndCalories(timeElapsed: timeElapsed, useSimulatedData: false)
            } else {
                // 有授权但还没有数据，仍然使用实际记录（不用兜底）
                isUsingSimulatedData = false
                print("有位置授权但暂无数据，如实记录（可能会很少或没有）")
                updateDistanceAndCalories(timeElapsed: timeElapsed, useSimulatedData: false)
            }
        } else {
            // 无位置授权，使用模拟数据并标记
            isUsingSimulatedData = true
            print("无位置授权，使用MET模拟数据")
            updateDistanceAndCalories(timeElapsed: timeElapsed, useSimulatedData: true)
        }
    }
    
    private func handleNonGPSExercise(timeElapsed: TimeInterval) {
        if exerciseType.name.lowercased().contains("楼梯") {
            // 爬楼梯：基于步数和楼层高度计算，不使用兜底
            isUsingSimulatedData = false
            
            if let motionData = motionManager?.currentPedometer {
                // 检查是否有踏步数据
                let recentSteps = motionData.numberOfSteps
                
                // 更新重复次数
                repetitionCount = recentSteps
                
                // 爬楼时，不计算距离，只计算卡路里消耗和时间
                if timeElapsed > 0 {
                    // 基于MET值计算卡路里
                    let metValue = exerciseType.metValue
                    let weight = UserDefaults.standard.double(forKey: "userWeight") // 读取用户体重，默认60kg
                    let userWeight = weight > 0 ? weight : 60.0
                    let caloriesPerSecond = (metValue * 3.5 * userWeight) / 200.0 // 每分钟消耗÷60
                    burnedCalories += caloriesPerSecond * timeElapsed
                }
            } else {
                // 没有踏步数据时，仍使用基本MET值计算卡路里，但不使用兜底
                if timeElapsed > 0 {
                    let metValue = exerciseType.metValue
                    let weight = UserDefaults.standard.double(forKey: "userWeight")
                    let userWeight = weight > 0 ? weight : 60.0
                    let caloriesPerSecond = (metValue * 3.5 * userWeight) / 200.0
                    burnedCalories += caloriesPerSecond * timeElapsed
                }
            }
        } else {
            // 其他室内运动：直接使用MET值计算，不需要真实数据
            isUsingSimulatedData = true
            
            if timeElapsed > 0 {
                let metValue = exerciseType.metValue
                let weight = UserDefaults.standard.double(forKey: "userWeight")
                let userWeight = weight > 0 ? weight : 60.0
                let caloriesPerSecond = (metValue * 3.5 * userWeight) / 200.0
                burnedCalories += caloriesPerSecond * timeElapsed
            }
        }
    }
    
    private func updateDistanceAndCalories(timeElapsed: TimeInterval, useSimulatedData: Bool) {
        if useSimulatedData {
            // 使用MET值模拟数据
            if timeElapsed > 0 {
                // 基于MET值和用户体重计算卡路里
                let metValue = exerciseType.metValue
                let weight = UserDefaults.standard.double(forKey: "userWeight")
                let userWeight = weight > 0 ? weight : 60.0
                let caloriesPerSecond = (metValue * 3.5 * userWeight) / 200.0
                burnedCalories += caloriesPerSecond * timeElapsed
                
                // 模拟距离计算，基于运动类型的典型速度
                let typicalSpeedMPS = getTypicalSpeed(for: exerciseType)
                distanceInMeters += typicalSpeedMPS * timeElapsed
                
                print("【调试-卡路里】模拟数据 - 增加\(String(format: "%.2f", caloriesPerSecond * timeElapsed))卡路里，总计\(String(format: "%.2f", burnedCalories))卡")
            }
        } else {
            // 使用实际位置数据
            if let newLocation = locationManager?.currentLocation, 
               !locationHistory.isEmpty,
               let lastLoc = locationHistory.last?.coordinate {
                let newCoordinate = newLocation.coordinate
                let locationDelta = CLLocation(latitude: lastLoc.latitude, longitude: lastLoc.longitude)
                    .distance(from: CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude))
                
                // 只有当检测到实际移动时才更新卡路里
                if locationDelta > 0.5 { // 至少移动0.5米才计算
                    // 更新总距离，但要排除异常值
                    if locationDelta < 100 { // 假设用户不会在一秒内移动超过100米
                        distanceInMeters += locationDelta
                        
                        // 更新卡路里消耗
                        if timeElapsed > 0 {
                            // 基于MET值、距离和用户体重计算卡路里
                            let metValue = exerciseType.metValue
                            let weight = UserDefaults.standard.double(forKey: "userWeight")
                            let userWeight = weight > 0 ? weight : 60.0
                            let caloriesPerSecond = (metValue * 3.5 * userWeight) / 200.0
                            let caloriesAdded = caloriesPerSecond * timeElapsed
                            burnedCalories += caloriesAdded
                            
                            print("【调试-卡路里】GPS移动\(String(format: "%.2f", locationDelta))米 - 增加\(String(format: "%.2f", caloriesAdded))卡路里，总计\(String(format: "%.2f", burnedCalories))卡")
                        }
                    }
                } else {
                    // 如果GPS没有显示移动，检查是否有步数变化
                    if let motionData = motionManager?.currentPedometer {
                        // 检查是否有步数数据变化
                        let currentSteps = motionData.numberOfSteps
                        if let lastSteps = lastRecordedSteps {
                            let stepsDelta = currentSteps - lastSteps
                            if stepsDelta > 0 && timeElapsed > 0 {
                                // 基于MET值和步数变化计算卡路里
                                let metValue = exerciseType.metValue
                                let weight = UserDefaults.standard.double(forKey: "userWeight")
                                let userWeight = weight > 0 ? weight : 60.0
                                let caloriesPerSecond = (metValue * 3.5 * userWeight) / 200.0
                                let caloriesAdded = caloriesPerSecond * timeElapsed
                                burnedCalories += caloriesAdded
                                
                                print("【调试-卡路里】检测到\(stepsDelta)步变化 - 增加\(String(format: "%.2f", caloriesAdded))卡路里，总计\(String(format: "%.2f", burnedCalories))卡")
                            } else {
                                print("【调试-卡路里】没有检测到移动或步数变化，不增加卡路里")
                            }
                        }
                        lastRecordedSteps = currentSteps
                    } else {
                        print("【调试-卡路里】没有检测到移动，没有步数数据，不增加卡路里")
                    }
                }
            } else if let motionData = motionManager?.currentPedometer {
                // 没有GPS数据但有步数数据
                let currentSteps = motionData.numberOfSteps
                if let lastSteps = lastRecordedSteps {
                    let stepsDelta = currentSteps - lastSteps
                    if stepsDelta > 0 && timeElapsed > 0 {
                        // 基于MET值和步数变化计算卡路里
                        let metValue = exerciseType.metValue
                        let weight = UserDefaults.standard.double(forKey: "userWeight")
                        let userWeight = weight > 0 ? weight : 60.0
                        let caloriesPerSecond = (metValue * 3.5 * userWeight) / 200.0
                        let caloriesAdded = caloriesPerSecond * timeElapsed
                        burnedCalories += caloriesAdded
                        
                        print("【调试-卡路里】仅步数数据，检测到\(stepsDelta)步变化 - 增加\(String(format: "%.2f", caloriesAdded))卡路里，总计\(String(format: "%.2f", burnedCalories))卡")
                    } else {
                        print("【调试-卡路里】没有位置变化或步数变化，不增加卡路里")
                    }
                }
                lastRecordedSteps = currentSteps
            } else {
                print("【调试-卡路里】无GPS数据且无步数数据，不增加卡路里")
            }
        }
    }
    
    private func getTypicalSpeed(for exerciseType: ExerciseType) -> Double {
        switch exerciseType {
        case .running:
            return 2.7 // ~10km/h
        case .walking:
            return 1.4 // ~5km/h
        case .dogWalking:
            return 1.1 // ~4km/h
        default:
            return 1.0 // 默认速度
        }
    }
    
    /// 完成百分比 (0-100)
    var completionPercentage: Double {
        switch exerciseType {
        case .running, .walking, .dogWalking:
            // GPS运动类型：基于目标卡路里
            return min(1.0, burnedCalories / targetCalories)
        default:
            // 非GPS运动类型：基于目标时间
            return min(1.0, totalElapsedSeconds / Double(targetTimeInMinutes * 60))
        }
    }
    
    /// 是否处于活动状态
    var isActive: Bool {
        return state == .active
    }
    
    /// 设置监听器
    private func setupListeners() {
        // 设置位置更新监听器
        if exerciseType.requiresGPS {
            locationManager?.locationUpdatePublisher
                .sink { [weak self] locationData in
                    guard let self = self else { return }
                    
                    // 只有在活动状态下才更新位置
                    if self.state == .active {
                        // 更新当前位置
                        self.currentLocation = locationData
                        
                        // 添加到位置历史
                        self.locationHistory.append(locationData)
                        
                        // 设置当前速度
                        self.currentSpeed = max(locationData.speed, 0)
                    }
                }
                .store(in: &cancellables)
        }
        
        // 设置运动数据更新监听器
        motionManager?.pedometerUpdatePublisher
            .sink { [weak self] pedometerData in
                guard let self = self else { return }
                
                // 只有在活动状态下才更新数据
                if self.state == .active {
                    // 更新重复次数（可以用步数表示）
                    if !self.exerciseType.requiresGPS {
                        self.repetitionCount = pedometerData.numberOfSteps
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    /// 生成甜品券
    func generateVoucher() -> DessertVoucher {
        let completionPercentage = min((burnedCalories / targetCalories) * 100, 100)
        
        return DessertVoucher(
            dessert: targetDessert,
            completionPercentage: completionPercentage,
            workoutSessionId: id
        )
    }
    
    /// 暂时挂起运动动画（例如，当应用进入后台时）
    func suspendAnimations() {
        print("【后台模式】暂停视图更新和动画，但继续收集运动数据")
        
        // 如果运动会话处于活动状态，继续收集数据但暂停UI更新
        if state == .active {
            // 位置追踪继续运行，但可能降低精度以节省电量
            locationManager?.pauseUIUpdates()
            
            // 运动追踪继续运行
            motionManager?.pauseUIUpdates()
            
            // 通知订阅者暂停所有动画和视图更新
            let notificationName = Notification.Name("SuspendWorkoutAnimations")
            NotificationCenter.default.post(name: notificationName, object: nil)
            
            print("【后台模式】已切换到后台数据收集模式，UI更新已暂停")
        }
    }
    
    /// 恢复运动动画（当应用回到前台时）
    func resumeAnimations() {
        print("【后台模式】恢复视图更新和动画")
        
        // 如果运动会话处于活动状态，恢复UI更新
        if state == .active {
            // 恢复位置追踪的UI更新
            locationManager?.resumeUIUpdates()
            
            // 恢复运动追踪的UI更新
            motionManager?.resumeUIUpdates()
            
            // 通知订阅者恢复所有动画和视图更新
            let notificationName = Notification.Name("ResumeWorkoutAnimations")
            NotificationCenter.default.post(name: notificationName, object: nil)
            
            print("【后台模式】已恢复UI更新模式")
        }
    }
    
    /// 目标时间（分钟），用于非GPS运动
    var targetTimeInMinutes: Int {
        // 基于目标卡路里和MET值计算预计所需时间
        let weight = UserDefaults.standard.double(forKey: "userWeight")
        let userWeight = weight > 0 ? weight : 60.0
        let caloriesPerMinute = (exerciseType.metValue * 3.5 * userWeight) / 200.0 * 60.0
        let minutes = max(10, Int(ceil(targetCalories / caloriesPerMinute)))
        return minutes
    }
}

/// 美食券所需的运动统计信息
struct WorkoutVoucherStats: Codable {
    /// 运动持续时间（秒）
    let duration: TimeInterval
    
    /// 运动距离（公里）
    let distance: Double
    
    /// 消耗的卡路里
    let calories: Double
} 