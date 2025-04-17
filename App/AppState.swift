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
    @Published var selectedExerciseType: DessertRun.ExerciseType?
    
    /// 当前正在进行的运动会话
    @Published var activeWorkoutSession: DessertRun.WorkoutSession?
    
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
        // 加载示例甜品券数据
        loadSampleVouchers()
    }
    
    // MARK: - 状态重置
    
    /// 重置运动状态
    func resetWorkoutState() {
        selectedDessert = nil as DessertItem?
        selectedExerciseType = nil as DessertRun.ExerciseType?
        activeWorkoutSession = nil as DessertRun.WorkoutSession?
    }
    
    /// 完成工作的函数 - 优化版本
    func finishWorkout() {
        print("【调试】AppState.finishWorkout() 开始")
        
        // 立即清除活动会话引用
        if let session = activeWorkoutSession {
            // 确保会话被完全重置
            session.cancelWorkout()
        }
        
        // 创建并保存甜品券（如果满足条件）
        if let session = activeWorkoutSession, session.isCompleted {
            // 生成并添加新甜品券
            let voucher = session.generateVoucher()
            dessertVouchers.append(voucher)
            print("【调试】生成了新的甜品券: \(voucher.dessert.name)")
        }
        
        activeWorkoutSession = nil as DessertRun.WorkoutSession?
        
        // 使用单一异步调用更新UI状态，避免多层嵌套
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 更新运动模式状态
            self.isInWorkoutMode = false
            
            // 清除所有运动相关状态
            self.selectedDessert = nil as DessertItem?
            self.selectedExerciseType = nil as DessertRun.ExerciseType?
            
            // 切换到统计标签页
            self.selectedTabIndex = 1
            
            // 标记需要重置导航
            self.shouldResetNavigation = true
            
            print("【调试】状态已完全重置：selectedDessert=nil, selectedExerciseType=nil, isInWorkoutMode=false")
            print("【调试】已切换到统计页面(index=1)，并触发导航重置")
            
            // 延迟清除导航重置标志
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                self.shouldResetNavigation = false
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
            self.selectedDessert = nil as DessertItem?
            self.selectedExerciseType = nil as DessertRun.ExerciseType?
            
            if let session = self.activeWorkoutSession {
                session.cancelWorkout()
            }
            self.activeWorkoutSession = nil as DessertRun.WorkoutSession?
            
            self.isInWorkoutMode = false
            self.selectedTabIndex = 0
            self.hideTabBarForDrag = false
            
            // 确保任何导航重置标记被清除
            self.shouldResetNavigation = false
            
            print("【调试】AppState.forceResetAllStates() 完成 - 所有状态已强制重置")
        }
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
    
    /// 加载示例甜品券数据
    private func loadSampleVouchers() {
        let sampleVouchers = DessertVoucherData.getSampleVouchers()
        
        // 将示例甜品券添加到应用状态
        dessertVouchers.append(contentsOf: sampleVouchers)
    }
    
    /// 兑换甜品券
    func redeemVoucher(_ voucherId: UUID) {
        if let index = dessertVouchers.firstIndex(where: { $0.id == voucherId }) {
            // 使用临时变量修改甜品券状态
            var voucher = dessertVouchers[index]
            voucher.status = .used
            
            // 更新数组中的元素
            dessertVouchers[index] = voucher
            
            print("【调试】甜品券已兑换: \(voucher.dessert.name)")
        }
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