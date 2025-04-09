//
//  AppState.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI
import Combine

// 显式导入所需的模型
// 这些导入确保编译器知道该使用哪些类型定义
import Foundation

// 导入甜品券模型
// 注意: 在Swift中，这些导入实际上是不需要的，因为它们都在同一个模块中
// 但为了确保编译器能找到正确的类型，我们在这里显式声明
// 如果有其他方式访问DessertVoucher.swift中的定义，请使用该方式

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
    
    /// 当前选中的主标签索引（0：运动，1：统计，2：我的）
    @Published var selectedTabIndex = 0
    
    /// 用于标记是否需要重置导航状态
    @Published var shouldResetNavigation = false
    
    /// 统计页面当前选中的分段（0：运动日历，1：甜品券）
    @Published var statsSelectedSegment = 0
    
    // MARK: - 运动相关状态
    
    /// 当前选中的甜品
    @Published var selectedDessert: DessertItem?
    
    /// 当前选中的运动类型
    @Published var selectedExerciseType: ExerciseType?
    
    /// 当前正在进行的运动会话
    @Published var activeWorkoutSession: WorkoutSession?
    
    /// 用户获得的甜品券
    /// 使用完全限定类型路径解决歧义问题
    @Published var dessertVouchers: [DessertRun.DessertVoucher] = []
    
    /// 甜品网格的偏移量，用于保持拖动位置
    @Published var dessertGridOffset: CGPoint = .zero
    
    /// 是否隐藏TabBar（用于拖动时）
    @Published var hideTabBarForDrag = false
    
    /// 是否处于运动状态（运动状态下TabBar完全隐藏）
    @Published var isInWorkoutMode = false
    
    /// TabBar是否应该被隐藏
    var shouldHideTabBar: Bool {
        return hideTabBarForDrag || isInWorkoutMode
    }
    
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
    
    /// 完成工作的函数 - 优化版本
    func finishWorkout() {
        print("【调试】AppState.finishWorkout() 开始 - 优化版本")
        print("【调试】当前运动状态: activeWorkoutSession=\(activeWorkoutSession != nil ? "存在" : "nil"), inWorkoutMode=\(isInWorkoutMode)")
        print("【调试】当前标签页: \(selectedTabIndex)")
        
        // 立即清除活动会话引用 - 检查是否真正清除
        if let session = activeWorkoutSession {
            print("【调试】主动清理activeWorkoutSession: \(session.id)")
            // 确保会话被标记为完成
            if !session.isCompleted {
                session.completeWorkout()
            }
        }
        activeWorkoutSession = nil
        
        // 使用单一异步调用更新UI状态，避免多层嵌套
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 更新运动模式状态
            self.isInWorkoutMode = false
            
            // 切换到首页标签
            self.selectedTabIndex = 0
            
            // 标记需要重置导航
            self.shouldResetNavigation = true
            
            // 重置其他状态数据
            self.selectedDessert = nil
            self.selectedExerciseType = nil
            
            print("【调试】AppState - 已重置基本状态，等待导航刷新")
            
            // 延迟清除导航重置标志
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                self.shouldResetNavigation = false
                print("【调试】AppState.finishWorkout() 完成 - 所有状态已重置")
            }
        }
    }
    
    /// 强制重置所有状态（应急使用，用于解决应用状态不一致的问题）
    func forceResetAllStates() {
        print("【调试警告】AppState.forceResetAllStates() - 强制重置所有状态")
        
        // 使用主线程执行所有状态重置操作
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 重置所有状态变量
            self.selectedDessert = nil
            self.selectedExerciseType = nil
            self.activeWorkoutSession = nil
            self.isInWorkoutMode = false
            self.selectedTabIndex = 0
            self.hideTabBarForDrag = false
            
            // 确保任何导航重置标记被清除
            self.shouldResetNavigation = false
            
            print("【调试】AppState.forceResetAllStates() 完成 - 所有状态已强制重置")
        }
    }
}

/// 用户资料结构
struct UserProfile {
    var id: String
    var name: String
    var avatarName: String
} 