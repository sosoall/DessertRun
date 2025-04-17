//
//  WorkoutSession.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI
import Combine

/// 运动状态枚举
enum WorkoutState {
    case inactive   // 不活跃状态(包含未开始和已完成)
    case active     // 进行中
    case paused     // 已暂停
}

/// 运动会话
class WorkoutSession: ObservableObject {
    // MARK: - 会话基本信息
    
    /// 会话唯一ID
    let id: UUID = UUID()
    
    /// 目标甜品
    let targetDessert: DessertItem
    
    /// 运动类型
    let exerciseType: ExerciseType
    
    /// 目标卡路里
    let targetCalories: Double
    
    /// 当前状态
    @Published var state: WorkoutState = .inactive
    
    /// 是否已完成
    @Published var isCompleted: Bool = false
    
    // MARK: - 运动数据
    
    /// 已燃烧的卡路里
    @Published var burnedCalories: Double = 0
    
    /// 开始时间
    @Published var startTime: Date? = nil
    
    /// 运动总时长（秒）
    @Published var totalElapsedSeconds: Int = 0
    
    /// 活动时长（秒）- 不包括暂停时间
    @Published var activeElapsedSeconds: Int = 0
    
    /// 总距离（米）
    @Published var distanceInMeters: Double = 0
    
    /// 平均速度（米/秒）
    @Published var averageSpeed: Double = 0
    
    /// 当前速度（米/秒）
    @Published var currentSpeed: Double = 0
    
    /// 暂停开始时间
    private var pauseStartTime: Date? = nil
    
    /// 计时器
    private var timer: Timer?
    
    /// 取消所有订阅
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 计算属性
    
    /// 完成百分比
    var completionPercentage: Double {
        return min(burnedCalories / targetCalories * 100, 100)
    }
    
    /// 格式化的总时间
    var formattedTotalTime: String {
        let minutes = totalElapsedSeconds / 60
        let seconds = totalElapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - 初始化
    
    /// 初始化运动会话
    /// - Parameters:
    ///   - targetDessert: 目标甜品
    ///   - exerciseType: 运动类型
    init(targetDessert: DessertItem, exerciseType: ExerciseType) {
        self.targetDessert = targetDessert
        self.exerciseType = exerciseType
        
        // 解析目标卡路里
        if let calories = Double(targetDessert.calories.replacingOccurrences(of: "kcal", with: "")) {
            self.targetCalories = calories
        } else {
            self.targetCalories = 300 // 默认值
        }
    }
    
    /// 初始化运动会话（带额外参数）
    /// - Parameters:
    ///   - dessert: 目标甜品
    ///   - exerciseType: 运动类型
    ///   - targetCalories: 目标卡路里
    ///   - startTime: 开始时间
    init(dessert: DessertItem, exerciseType: ExerciseType, targetCalories: Double, startTime: Date) {
        self.targetDessert = dessert
        self.exerciseType = exerciseType
        self.targetCalories = targetCalories
        self.startTime = startTime
        self.state = .active
    }
    
    // MARK: - 会话控制
    
    /// 开始会话
    func start() {
        guard state == .inactive else { return }
        
        startTime = Date()
        state = .active
    }
    
    /// 暂停会话
    func pause() {
        guard state == .active else { return }
        
        pauseStartTime = Date()
        state = .paused
    }
    
    /// 继续会话
    func resume() {
        guard state == .paused, let pauseStart = pauseStartTime else { return }
        
        // 计算暂停的时间但不使用，使用下划线避免编译警告
        _ = Int(-pauseStart.timeIntervalSinceNow)
        
        // 不计入活动时间
        pauseStartTime = nil
        state = .active
    }
    
    /// 完成会话
    func completeWorkout() {
        print("【调试】WorkoutSession.completeWorkout() 被调用")
        print("【调试】当前状态: \(state), 燃烧卡路里: \(burnedCalories)/\(targetCalories)")
        
        // 设置状态为不活跃并标记为已完成
        state = .inactive
        isCompleted = true
        
        // 停止计时器
        timer?.invalidate()
        timer = nil
        
        // 调用complete方法生成甜品券
        complete()
        
        print("【调试】WorkoutSession完成状态: state=\(state), isCompleted=\(isCompleted)")
    }
    
    /// 重置会话
    func resetWorkout() {
        print("【调试】WorkoutSession.resetWorkout() 被调用")
        
        // 重置状态为不活跃
        state = .inactive
        isCompleted = false
        
        // 停止计时器
        timer?.invalidate()
        timer = nil
        
        // 重置数据
        burnedCalories = 0
        totalElapsedSeconds = 0
        distanceInMeters = 0
        currentSpeed = 0
        
        print("【调试】WorkoutSession已重置")
    }
    
    /// 完成会话并生成甜品券
    func complete() {
        print("【调试】WorkoutSession.complete() 被调用")
        
        // 创建甜品券，使用完全限定类型名称解决歧义
        let voucher = DessertRun.DessertVoucher(
            dessert: targetDessert,
            completionPercentage: completionPercentage,
            workoutSessionId: id
        )
        
        // 如果没有已存在的相同ID的券，才添加新的
        if !AppState.shared.dessertVouchers.contains(where: { $0.workoutSessionId == id }) {
            print("【调试】添加新的甜品券: \(voucher.dessert.name), \(Int(voucher.completionPercentage))%完成")
            AppState.shared.dessertVouchers.append(voucher)
        } else {
            print("【调试】甜品券已存在，跳过添加")
        }
    }
    
    /// 数据更新
    
    /// 更新时间和卡路里
    func updateTimeAndCalories() {
        guard state == .active else { return }
        
        // 增加总时长
        totalElapsedSeconds += 1
        
        // 增加活动时长
        activeElapsedSeconds += 1
        
        // 根据MET值计算卡路里消耗
        let weight = 70.0 // 默认体重70kg
        // 每秒消耗的卡路里 = 体重(kg) × MET值 × (1秒/3600秒)
        let additionalCalories = weight * exerciseType.metValue / 3600.0
        burnedCalories += additionalCalories
        
        // 更新平均速度
        if distanceInMeters > 0 && activeElapsedSeconds > 0 {
            averageSpeed = distanceInMeters / Double(activeElapsedSeconds)
        }
    }
    
    // MARK: - 简化视图调用的方法
    
    /// 暂停运动 - 视图层调用简化包装
    func pauseWorkout() {
        pause()
    }
    
    /// 恢复运动 - 视图层调用简化包装
    func resumeWorkout() {
        resume()
    }
    
    /// 开始运动 - 视图层调用简化包装
    func startWorkout() {
        start()
    }
    
    /// 更新运动数据 - 视图层调用简化包装
    func updateWorkoutData() {
        updateTimeAndCalories()
    }
    
    /// 判断运动是否处于活动状态
    var isActive: Bool {
        return state == .active
    }
} 