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
    
    // MARK: - 初始化
    init(targetDessert: DessertItem, exerciseType: ExerciseType) {
        self.targetDessert = targetDessert
        self.exerciseType = exerciseType
        
        // 创建位置管理器
        self.locationManager = LocationManager()
        
        // 检测设备是否支持运动传感器
        let motionMgr = MotionManager()
        if motionMgr.sensorsAvailable {
            // 使用真实的运动管理器
            self.motionManager = motionMgr
            print("使用真实运动数据")
        } else {
            // 使用模拟的运动管理器
            self.motionManager = MockMotionManager()
            print("使用模拟运动数据")
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
        
        // 如果是户外运动，启动位置追踪
        if exerciseType.requiresGPS {
            locationManager?.requestAuthorization()
            locationManager?.startTracking()
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
        guard let start = startTime else { return }
        
        // 计算总的持续时间
        let totalDuration = Date().timeIntervalSince(start)
        
        // 计算有效的运动时间（减去暂停时间）
        let effectiveDuration = totalDuration - totalPausedTime
        
        // 更新总经过时间
        totalElapsedSeconds = effectiveDuration
        
        // 如果是户外运动，更新从位置管理器获取的距离
        if exerciseType.requiresGPS, let locationMgr = locationManager {
            distanceInMeters = locationMgr.totalDistance
        }
        
        // 从运动管理器更新卡路里消耗
        if let motionMgr = motionManager {
            // 如果运动管理器有数据，使用运动管理器的卡路里估算
            burnedCalories = motionMgr.totalCalories
            
            // 如果数据不足，使用基于时间和MET值的粗略估算
            if burnedCalories < 10 && totalElapsedSeconds > 10 {
                // 使用MET值计算卡路里消耗
                // 公式: 卡路里 = MET值 * 体重(kg) * 时间(小时)
                let hours = effectiveDuration / 3600
                let userWeight = 65.0 // 默认用户体重65kg
                burnedCalories = exerciseType.metValue * userWeight * hours
            }
        } else {
            // 如果没有运动管理器，使用基本估算
            let hours = effectiveDuration / 3600
            let userWeight = 65.0 // 默认用户体重65kg
            burnedCalories = exerciseType.metValue * userWeight * hours
        }
        
        // 确保卡路里至少有一个最小值
        burnedCalories = max(burnedCalories, totalElapsedSeconds / 60) // 至少每分钟1卡路里
    }
    
    /// 完成百分比 (0-100)
    var completionPercentage: Double {
        guard targetCalories > 0 else { return 0 }
        return min((burnedCalories / targetCalories) * 100, 100)
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
        // 如果运动会话处于活动状态，暂时暂停但不改变状态
        if state == .active {
            // 暂停位置追踪但不改变状态
            locationManager?.pauseTracking()
            
            // 暂停运动追踪但不改变状态
            motionManager?.pauseTracking()
        }
        
        // 停止任何可能在运行的动画或GPU渲染操作
        // 这里不改变运动状态，只是暂停相关操作
        
        // 通知订阅者暂停动画
        let notificationName = Notification.Name("SuspendWorkoutAnimations")
        NotificationCenter.default.post(name: notificationName, object: nil)
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