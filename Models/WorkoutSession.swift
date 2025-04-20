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
    
    // MARK: - 添加暂停时间相关属性
    private var pauseStartTime: Date?
    
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
        // 确保已经开始并且处于活动状态
        guard startTime != nil && state == .active else { return }
        
        print("【调试-暂停】开始暂停运动，当前卡路里:\(String(format: "%.2f", burnedCalories))卡")
        
        // 更新最终数据
        updateWorkoutData()
        
        // 设置状态为暂停
        state = .paused
        
        // 计算当前暂停时间
        pauseStartTime = Date()
        
        // 暂停位置追踪
        if exerciseType.requiresGPS {
            locationManager?.pauseTracking()
        }
        
        // 暂停运动追踪
        motionManager?.pauseTracking()
        
        // 保存暂停前的步数状态，确保恢复后不计算暂停期间的步数
        if let motionData = motionManager?.currentPedometer {
            lastRecordedSteps = motionData.numberOfSteps
            print("【调试-暂停】记录暂停时步数:\(lastRecordedSteps ?? 0)")
        }
        
        print("【调试-暂停】运动会话已暂停，当前卡路里:\(String(format: "%.2f", burnedCalories))卡")
    }
    
    /// 恢复运动
    func resumeWorkout() {
        // 确保已经开始并且处于暂停状态
        guard startTime != nil && state == .paused else { return }
        
        print("【调试-恢复】开始恢复运动，当前卡路里:\(String(format: "%.2f", burnedCalories))卡")
        
        // 如果有暂停时间，计算暂停持续时间
        if let pauseStart = pauseStartTime {
            let pauseDuration = Date().timeIntervalSince(pauseStart)
            totalPausedTime += pauseDuration
            pauseStartTime = nil
            print("【调试-恢复】暂停持续了\(String(format: "%.2f", pauseDuration))秒，总暂停时间:\(String(format: "%.2f", totalPausedTime))秒")
        }
        
        // 设置状态为活动
        state = .active
        
        // 重置最后更新时间为当前时间，确保暂停期间的运动不被计入
        lastDataUpdateTime = Date()
        print("【调试-恢复】重置最后更新时间为当前时间:\(lastDataUpdateTime!)")
        
        // 恢复位置追踪
        if exerciseType.requiresGPS {
            locationManager?.resumeTracking()
        }
        
        // 恢复运动追踪
        motionManager?.resumeTracking()
        
        print("【调试-恢复】运动会话已恢复，当前卡路里:\(String(format: "%.2f", burnedCalories))卡")
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
        // 确保运动会话在活动状态，如果是暂停状态则不做任何更新
        guard state == .active else {
            print("【调试-更新】运动会话处于非活动状态(state=\(state))，跳过数据更新")
            return
        }
        
        // 记录当前时间
        let now = Date()
        
        // 计算从上次更新到现在的时间间隔
        var timeElapsed: TimeInterval = 0
        if let lastTime = lastDataUpdateTime {
            timeElapsed = now.timeIntervalSince(lastTime)
            print("【调试-更新】距离上次更新经过了\(String(format: "%.2f", timeElapsed))秒")
        } else {
            print("【调试-更新】首次更新，没有上次更新时间")
        }
        
        // 更新最后更新时间
        lastDataUpdateTime = now
        
        // 计算累计运行时间（仅在活动状态下且时间间隔合理时累加）
        if timeElapsed > 0 && timeElapsed < 5.0 { // 防止异常大的时间间隔
            totalElapsedSeconds += timeElapsed
            print("【调试-更新】累计运行时间增加\(String(format: "%.2f", timeElapsed))秒，总计\(String(format: "%.2f", totalElapsedSeconds))秒")
        } else if timeElapsed >= 5.0 {
            print("【调试-更新】时间间隔异常大(\(String(format: "%.2f", timeElapsed))秒)，不计入累计时间")
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
                // 模拟距离计算，基于运动类型的典型速度
                let typicalSpeedMPS = getTypicalSpeed(for: exerciseType)
                let distanceDelta = typicalSpeedMPS * timeElapsed
                distanceInMeters += distanceDelta
                
                // 对GPS运动类型(散步、跑步等)，根据距离计算卡路里
                if exerciseType.requiresGPS {
                    // 使用根据距离计算卡路里的方法
                    let caloriesAdded = calculateCaloriesFromDistance(distance: distanceDelta, exerciseType: exerciseType)
                    burnedCalories += caloriesAdded
                    
                    print("【调试-卡路里】模拟数据(基于距离) - 距离增加:\(String(format: "%.2f", distanceDelta))米")
                    print("【调试-卡路里】卡路里增加:\(String(format: "%.2f", caloriesAdded))卡，总计:\(String(format: "%.2f", burnedCalories))卡")
                } else {
                    // 非GPS运动类型，仍使用MET和时间计算
                    let originalMet = exerciseType.metValue
                    let weight = UserDefaults.standard.double(forKey: "userWeight")
                    let userWeight = weight > 0 ? weight : 60.0
                    
                    // 使用标准MET公式：热量消耗（kcal/秒）= MET值 × 体重（kg）÷ 3600
                    let caloriesPerSecond = originalMet * userWeight / 3600.0
                    let caloriesAdded = caloriesPerSecond * timeElapsed
                    burnedCalories += caloriesAdded
                    
                    print("【调试-卡路里】模拟数据(基于时间) - MET:\(originalMet), 体重:\(userWeight)kg")
                    print("【调试-卡路里】正确公式：MET×体重÷3600，每秒消耗:\(String(format: "%.5f", caloriesPerSecond))卡，增加\(String(format: "%.2f", caloriesAdded))卡路里，总计\(String(format: "%.2f", burnedCalories))卡")
                }
                
                print("【调试-统一】当前总卡路里:\(String(format: "%.2f", burnedCalories))卡，目标卡路里:\(String(format: "%.2f", targetCalories))卡，完成比例:\(String(format: "%.2f", (burnedCalories / targetCalories) * 100))%")
            }
        } else {
            // 使用实际位置数据
            var gpsDistanceDelta: Double = 0
            var hasValidGPSMovement = false
            
            // 提取并处理GPS信息
            if let newLocation = locationManager?.currentLocation, 
               !locationHistory.isEmpty,
               let lastLoc = locationHistory.last?.coordinate {
                let newCoordinate = newLocation.coordinate
                let locationDelta = CLLocation(latitude: lastLoc.latitude, longitude: lastLoc.longitude)
                    .distance(from: CLLocation(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude))
                
                // 只有当检测到实际移动且值合理时
                if locationDelta > 0.5 && locationDelta < 100 { // 至少移动0.5米且不超过100米
                    gpsDistanceDelta = locationDelta
                    hasValidGPSMovement = true
                }
            }
            
            // 获取并处理步数信息
            var stepsDelta = 0
            var stepBasedDistance: Double = 0
            let averageStepLength = getAverageStepLength() // 根据用户高度或设置获取平均步长
            
            if let motionData = motionManager?.currentPedometer {
                let currentSteps = motionData.numberOfSteps
                if let lastSteps = lastRecordedSteps {
                    stepsDelta = currentSteps - lastSteps
                    if stepsDelta > 0 {
                        // 将步数转换为距离（米）
                        stepBasedDistance = Double(stepsDelta) * averageStepLength
                        print("【调试-步数】检测到\(stepsDelta)步，转换为\(String(format: "%.2f", stepBasedDistance))米")
                    } else if stepsDelta < 0 {
                        print("【调试-步数】检测到步数减少，可能是计步器重置：上次\(lastSteps)，当前\(currentSteps)")
                        stepsDelta = 0
                    }
                } else {
                    print("【调试-步数】首次获取步数，当前步数为\(currentSteps)")
                }
                lastRecordedSteps = currentSteps
            }
            
            // 融合GPS和步数数据计算最终距离
            var finalDistanceDelta = 0.0
            
            if hasValidGPSMovement && stepsDelta > 0 {
                // 同时有GPS和步数数据，进行加权融合
                // GPS信号强度越好，GPS权重越高
                let gpsConfidence = min(1.0, max(0.3, getGPSConfidence())) // 0.3-1.0之间
                let stepConfidence = 1.0 - gpsConfidence // 步数可信度为GPS可信度的补集
                
                // 加权平均
                finalDistanceDelta = gpsDistanceDelta * gpsConfidence + stepBasedDistance * stepConfidence
                print("【调试-距离】GPS数据(\(String(format: "%.2f", gpsDistanceDelta))米)和步数数据(\(stepsDelta)步，约\(String(format: "%.2f", stepBasedDistance))米)融合 - 最终增加\(String(format: "%.2f", finalDistanceDelta))米")
            } else if hasValidGPSMovement {
                // 只有GPS数据
                finalDistanceDelta = gpsDistanceDelta
                print("【调试-距离】仅GPS数据 - 增加\(String(format: "%.2f", finalDistanceDelta))米")
            } else if stepsDelta > 0 {
                // 只有步数数据 - 现在也计算距离
                // 在GPS未变化但有步数的情况下，我们依然根据步数计算距离
                finalDistanceDelta = stepBasedDistance
                print("【调试-距离】仅步数数据(\(stepsDelta)步) - 增加\(String(format: "%.2f", finalDistanceDelta))米")
            } else {
                print("【调试-距离】无移动，不增加距离")
            }
            
            // 更新总距离
            if finalDistanceDelta > 0 {
                distanceInMeters += finalDistanceDelta
                
                // 对GPS运动类型(散步、跑步等)，根据距离计算卡路里
                if exerciseType.requiresGPS {
                    // 使用根据距离计算卡路里的方法
                    let caloriesAdded = calculateCaloriesFromDistance(distance: finalDistanceDelta, exerciseType: exerciseType)
                    burnedCalories += caloriesAdded
                    
                    print("【调试-卡路里】基于距离计算 - 增加\(String(format: "%.2f", finalDistanceDelta))米")
                    print("【调试-卡路里】卡路里增加:\(String(format: "%.2f", caloriesAdded))卡，总计:\(String(format: "%.2f", burnedCalories))卡")
                } else {
                    // 非GPS运动类型，仍使用MET和时间计算
                    if timeElapsed > 0 {
                        let originalMet = exerciseType.metValue
                        let weight = UserDefaults.standard.double(forKey: "userWeight")
                        let userWeight = weight > 0 ? weight : 60.0
                        
                        // 使用标准MET公式：热量消耗（kcal/秒）= MET值 × 体重（kg）÷ 3600
                        let caloriesPerSecond = originalMet * userWeight / 3600.0
                        let caloriesAdded = caloriesPerSecond * timeElapsed
                        burnedCalories += caloriesAdded
                        
                        print("【调试-卡路里】基于时间计算 - MET:\(originalMet), 体重:\(userWeight)kg")
                        print("【调试-卡路里】正确公式：MET×体重÷3600，每秒消耗:\(String(format: "%.5f", caloriesPerSecond))卡，增加\(String(format: "%.2f", caloriesAdded))卡路里，总计\(String(format: "%.2f", burnedCalories))卡")
                    }
                }
                
                print("【调试-统一】当前总卡路里:\(String(format: "%.2f", burnedCalories))卡，目标卡路里:\(String(format: "%.2f", targetCalories))卡，完成比例:\(String(format: "%.2f", (burnedCalories / targetCalories) * 100))%")
            } else {
                print("【调试-卡路里】没有检测到移动，不增加卡路里")
            }
        }
    }
    
    /// 获取平均步长（米）
    private func getAverageStepLength() -> Double {
        // 可以根据用户身高或自定义设置计算
        // 默认值：男性约0.78米，女性约0.70米
        let defaultStepLength = 0.75 // 默认平均步长（米）
        
        // 从用户设置获取身高
        let height = UserDefaults.standard.double(forKey: "userHeight") // 单位：厘米
        if height > 0 {
            // 根据身高估算步长：身高的约0.43倍（经验值）
            return height * 0.0043 // 转换为米
        }
        
        return defaultStepLength
    }
    
    /// 获取GPS信号可信度（0-1）
    private func getGPSConfidence() -> Double {
        guard let location = locationManager?.currentLocation else {
            return 0.3 // 无GPS数据时的默认值
        }
        
        // 根据精度估算GPS可信度
        // horizontalAccuracy越小表示精度越高
        let accuracy = location.horizontalAccuracy
        
        if accuracy <= 0 {
            return 0.3 // 无效精度
        } else if accuracy < 5 {
            return 0.9 // 非常精确 (<=5米)
        } else if accuracy < 10 {
            return 0.8 // 很精确 (5-10米)
        } else if accuracy < 20 {
            return 0.7 // 相当精确 (10-20米)
        } else if accuracy < 50 {
            return 0.6 // 一般精确 (20-50米)
        } else if accuracy < 100 {
            return 0.5 // 不太精确 (50-100米)
        } else {
            return 0.4 // 很不精确 (>100米)
        }
    }
    
    /// 获取运动类型的典型速度（米/秒）
    private func getTypicalSpeed(for exerciseType: ExerciseType) -> Double {
        switch exerciseType {
        case .running:
            return 2.7 // ~10km/h
        case .walking:
            return 1.25 // ~4.5km/h (用户指定的默认散步速度)
        case .dogWalking:
            return 1.1 // ~4km/h
        default:
            return 1.0 // 默认速度
        }
    }
    
    /// 获取实际的MET消耗系数，考虑实际消耗情况进行调整
    private func getAdjustedMETValue(for exerciseType: ExerciseType) -> Double {
        // 根据用户要求，不再调整MET值，直接返回原始值
        return exerciseType.metValue
    }
    
    /// 根据距离计算卡路里消耗（用于GPS运动类型）
    private func calculateCaloriesFromDistance(distance: Double, exerciseType: ExerciseType) -> Double {
        // 获取用户体重
        let weight = UserDefaults.standard.double(forKey: "userWeight")
        let userWeight = weight > 0 ? weight : 60.0
        
        // 基于运动类型和距离计算卡路里
        // 不同运动类型每公里消耗的卡路里不同
        let caloriesPerKm: Double
        switch exerciseType {
        case .walking:
            // 散步每公里约消耗体重*0.5卡路里
            caloriesPerKm = userWeight * 0.5
        case .running:
            // 跑步每公里约消耗体重*1.0卡路里
            caloriesPerKm = userWeight * 1.0
        case .dogWalking:
            // 遛狗每公里约消耗体重*0.6卡路里
            caloriesPerKm = userWeight * 0.6
        default:
            // 其他GPS运动类型
            caloriesPerKm = userWeight * 0.7
        }
        
        // 距离单位是米，转换为公里进行计算
        let distanceInKm = distance / 1000.0
        let calories = distanceInKm * caloriesPerKm
        
        return calories
    }
    
    /// 完成百分比 (0-100)
    var completionPercentage: Double {
        let result: Double
        switch exerciseType {
        case .running, .walking, .dogWalking:
            // GPS运动类型：基于目标卡路里
            result = min(1.0, burnedCalories / targetCalories)
            print("【调试-百分比】GPS运动类型 - 当前卡路里:\(String(format: "%.2f", burnedCalories))卡，目标:\(String(format: "%.2f", targetCalories))卡，完成比例:\(String(format: "%.2f", result * 100))%")
        default:
            // 非GPS运动类型：基于目标时间
            result = min(1.0, totalElapsedSeconds / Double(targetTimeInMinutes * 60))
            print("【调试-百分比】非GPS运动类型 - 当前时间:\(String(format: "%.2f", totalElapsedSeconds))秒，目标:\(targetTimeInMinutes * 60)秒，完成比例:\(String(format: "%.2f", result * 100))%")
        }
        return result
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