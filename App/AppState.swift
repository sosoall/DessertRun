//
//  AppState.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI
import Combine

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
    
    // MARK: - 运动相关状态
    
    /// 当前选中的甜品
    @Published var selectedDessert: DessertItem?
    
    /// 当前选中的运动类型
    @Published var selectedExerciseType: ExerciseType?
    
    /// 当前正在进行的运动会话
    @Published var activeWorkoutSession: WorkoutSession?
    
    /// 用户获得的甜品券
    @Published var dessertVouchers: [DessertVoucher] = []
    
    /// 甜品网格的偏移量，用于保持拖动位置
    @Published var dessertGridOffset: CGPoint = .zero
    
    /// 是否隐藏TabBar（用于拖动时）
    @Published var hideTabBarForDrag = false
    
    /// 是否隐藏顶部标题（用于转场动画）
    @Published var shouldHideTitle = false
    
    /// 是否处于运动状态（运动状态下TabBar完全隐藏）
    @Published var isInWorkoutMode = false
    
    /// TabBar是否应该被隐藏
    var shouldHideTabBar: Bool {
        return hideTabBarForDrag || isInWorkoutMode
    }
    
    // MARK: - 页面过渡动画相关状态
    
    /// 用于匹配几何效果的过渡ID标识符
    @Published var transitionDessertID: String = ""
    
    /// 是否正在执行甜品到运动类型的过渡动画
    @Published var isTransitioningToExerciseType: Bool = false
    
    /// 选中的甜品在网格中的原始位置
    @Published var selectedDessertOriginalFrame: CGRect = .zero
    
    /// 甜品在运动类型页中的目标位置
    @Published var targetDessertFrame: CGRect = .zero
    
    // MARK: - 应用配置
    
    /// 是否显示新手引导
    @Published var showOnboarding = false
    
    /// 初始化
    private init() {
        // 这里可以添加读取持久化数据的逻辑
    }
    
    // MARK: - 状态重置
    
    /// 重置运动状态
    func resetWorkoutState() {
        selectedDessert = nil
        selectedExerciseType = nil
        activeWorkoutSession = nil
    }
}

/// 用户资料结构
struct UserProfile {
    var id: String
    var name: String
    var avatarName: String
} 