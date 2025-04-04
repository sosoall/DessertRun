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
    case notStarted    // 未开始
    case active        // 进行中
    case paused        // 已暂停
    case completed     // 已完成
    case abandoned     // 已放弃
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
    @Published var state: WorkoutState = .notStarted
    
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
        guard state == .notStarted else { return }
        
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
    func complete() {
        state = .completed
        
        // 创建甜品券，使用完全限定类型名称解决歧义
        let voucher = DessertRun.DessertVoucher(
            dessert: targetDessert,
            completionPercentage: completionPercentage,
            workoutSessionId: id
        )
        AppState.shared.dessertVouchers.append(voucher)
    }
    
    /// 放弃会话
    func abandon() {
        state = .abandoned
    }
    
    // MARK: - 数据更新
    
    /// 更新时间和卡路里
    func updateTimeAndCalories() {
        guard state == .active else { return }
        
        // 增加总时长
        totalElapsedSeconds += 1
        
        // 增加活动时长
        activeElapsedSeconds += 1
        
        // 根据运动类型和时间计算卡路里
        // 卡路里 = 每分钟消耗卡路里 * 分钟数
        let additionalCalories = exerciseType.caloriesPerMinute / 60.0
        burnedCalories += additionalCalories
        
        // 更新平均速度
        if distanceInMeters > 0 && activeElapsedSeconds > 0 {
            averageSpeed = distanceInMeters / Double(activeElapsedSeconds)
        }
    }
} 