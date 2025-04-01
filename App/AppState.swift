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