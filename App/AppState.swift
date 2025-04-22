//
//  AppState.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI
import Combine
import Foundation

/// 全局应用状态
class AppState: ObservableObject {
    /// 共享的单例实例
    static let shared = AppState()
    
    // MARK: - 用户相关状态
    
    /// 用户是否已登录
    @Published var isLoggedIn = false
    
    /// 用户信息（临时示例数据）
    @Published var userProfile = UserProfile(
        id: "temp_user_id",
        name: "测试用户",
        avatarName: "person.circle.fill"
    )
    
    // MARK: - 导航状态
    
    /// 当前选中的主标签索引（0：运动，1：甜品打卡，2：运动记录，3：我的）
    @Published var selectedTabIndex = 0
    
    /// 用于标记是否需要重置导航状态
    @Published var shouldResetNavigation = false
    
    /// 统计页面当前选中的分段（0：运动日历，1：甜品券）
    @Published var statsSelectedSegment = 0
    
    /// 标记是否刚完成打卡（用于动画）
    @Published var justCompletedWorkout = false
    
    // MARK: - 运动相关状态
    
    /// 当前选中的甜品
    @Published var selectedDessert: DessertItem?
    
    /// 当前选中的运动类型
    @Published var selectedExerciseType: ExerciseType?
    
    /// 甜品网格的偏移量，用于保持拖动位置
    @Published var dessertGridOffset: CGPoint = .zero
    
    /// 用户的运动记录
    @Published var workoutRecords: [WorkoutRecord] = []
    
    /// 是否隐藏TabBar（用于拖动时）
    @Published var hideTabBarForDrag = false
    
    /// TabBar是否应该被隐藏
    var shouldHideTabBar: Bool {
        return hideTabBarForDrag
    }
    
    // MARK: - 应用配置
    
    /// 是否显示新手引导
    @Published var showOnboarding = false
    
    /// 初始化
    private init() {
        // 加载示例运动记录数据
        loadSampleWorkoutRecords()
    }
    
    // MARK: - 状态重置
    
    /// 重置运动状态
    func resetWorkoutState() {
        selectedDessert = nil
        selectedExerciseType = nil
    }
    
    /// 添加新的运动记录
    func addWorkoutRecord(_ record: WorkoutRecord) {
        workoutRecords.append(record)
        
        // 模拟数据持久化
        print("【调试】已添加新的运动记录: \(record.dessert.name), 完成时间: \(record.formattedDate)")
        
        // 在真实应用中，这里应该同步到后端服务器
    }
    
    /// 导航到指定的屏幕
    func navigateToScreen(_ screen: AppScreen) {
        switch screen {
        case .home:
            // 回到主页
            selectedTabIndex = 0
            // 重置运动状态
            resetWorkoutState()
            
        case .stats:
            // 导航到统计页面
            selectedTabIndex = 1
            
        case .profile:
            // 导航到个人资料页面
            selectedTabIndex = 2
        }
    }
    
    /// 加载示例运动记录数据
    private func loadSampleWorkoutRecords() {
        // 创建一些示例运动记录
        var sampleRecords: [WorkoutRecord] = []
        
        // 添加10条示例记录
        for _ in 1...10 {
            sampleRecords.append(WorkoutRecord.createSample())
        }
        
        workoutRecords.append(contentsOf: sampleRecords)
    }
}

/// 应用屏幕枚举
enum AppScreen {
    case home     // 主页
    case stats    // 统计
    case profile  // 个人资料
}

/// 用户资料结构
struct UserProfile {
    var id: String
    var name: String
    var avatarName: String
}

// MARK: - 以下是被移除的功能，保留注释以便未来恢复
/* 
 // 运动会话相关
 @Published var activeWorkoutSession: WorkoutSession?
 @Published var isInWorkoutMode = false
 
 // 甜品券相关
 @Published var dessertVouchers: [DessertVoucher] = []
 
 // 完成工作的函数
 func finishWorkout() {
     // 创建并保存甜品券
     // 更新运动模式状态
     // 切换到统计标签页
 }
 
 // 强制重置所有状态
 func forceResetAllStates() {
     // 重置所有状态变量
 }
 
 // 兑换甜品券
 func redeemVoucher(_ voucherId: UUID) {
     // 更新甜品券状态
 }
*/ 