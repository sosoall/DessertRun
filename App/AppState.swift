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
    
    // 用于管理取消订阅
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 用户相关状态
    
    /// 用户是否已登录
    @Published var isLoggedIn: Bool = false
    
    /// 用户信息（临时示例数据）
    @Published var userProfile = UserProfile(
        id: "temp_user_id",
        name: "测试用户",
        avatarName: "person.circle.fill"
    )
    
    // MARK: - 首次启动和登录状态
    
    /// 是否是首次启动应用
    var isFirstLaunch: Bool {
        return !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
    }
    
    /// 是否显示登录页面
    @Published var showLoginView: Bool = false
    
    /// 是否正在重置应用
    @Published var isResettingApp: Bool = false
    
    // MARK: - 导航状态
    
    /// 当前选中的主标签索引（0：运动，1：甜品打卡，2：运动记录，3：我的）
    @Published var selectedTabIndex: Int = 0
    
    /// 用于标记是否需要重置导航状态
    @Published var shouldResetNavigation = false
    
    /// 统计页面当前选中的分段（0：运动日历，1：甜品券）
    @Published var statsSelectedSegment = 0
    
    /// 标记是否刚完成打卡（用于动画）
    @Published var justCompletedWorkout: Bool = false
    
    // MARK: - 运动相关状态
    
    /// 当前选中的甜品
    @Published var selectedDessert: DessertItem?
    
    /// 当前选中的运动类型
    @Published var selectedExerciseType: ExerciseType?
    
    /// 甜品网格的偏移量，用于保持拖动位置
    @Published var dessertGridOffset: CGPoint = .zero
    
    /// 用户的运动记录
    @Published var workoutRecords: [WorkoutRecord] = []
    
    /// 美食券列表
    @Published var dessertVouchers: [DessertVoucher] = []
    
    /// 当前选中的任务卡（未激活美食券）
    @Published var selectedTaskVoucher: DessertVoucher? = nil
    
    /// 全局运动记录加载状态锁，防止多处同时请求
    @Published var isLoadingWorkoutRecords: Bool = false
    
    /// 最后一次加载运动记录的时间，用于限制频繁请求
    @Published var lastWorkoutLoadTime: Date? = nil
    
    /// 是否隐藏TabBar（用于拖动时）
    @Published var hideTabBarForDrag: Bool = false
    
    /// 是否隐藏状态栏
    @Published var hideStatusBar: Bool = false
    
    /// TabBar是否应该被隐藏
    var shouldHideTabBar: Bool {
        return hideTabBarForDrag
    }
    
    // MARK: - 应用配置
    
    /// 是否显示新手引导
    @Published var showOnboarding = false
    
    // MARK: - 挑战相关状态
    
    /// 当前选中的挑战活动ID
    @Published var selectedChallengeId: String? = nil
    
    /// 当前选中的挑战报名记录ID
    @Published var selectedEnrollmentId: String? = nil
    
    /// 缓存的挑战活动列表
    @Published var challengeActivities: [ChallengeActivity] = []
    
    /// 缓存的用户已报名挑战列表
    @Published var enrolledChallenges: [EnrollmentWithChallengeDetail] = []
    
    /// 挑战活动列表是否正在加载
    @Published var isLoadingChallenges: Bool = false
    
    /// 已报名挑战列表是否正在加载
    @Published var isLoadingEnrollments: Bool = false
    
    /// 最后一次加载挑战列表的时间
    @Published var lastChallengeLoadTime: Date? = nil
    
    /// 最后一次加载报名列表的时间
    @Published var lastEnrollmentLoadTime: Date? = nil
    
    /// 是否显示独立的运动打卡视图
    @Published var showWorkoutView: Bool = false
    
    /// 初始化
    private init() {
        // 登录状态应由AuthService确定，不应在这里强制设置
        self.isLoggedIn = false
        
        // 检查用户登录状态
        checkAndSetupLoginState()
        
        // 如果是首次启动，记录已启动标记
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
        
        // 监听登录状态变化通知
        setupNotificationObservers()
        
        // 预加载美食数据
        preloadDessertData()
    }
    
    /// 设置通知观察者
    private func setupNotificationObservers() {
        // 监听认证状态变化
        NotificationCenter.default.publisher(for: .authStatusChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                DRInfo("收到认证状态变化通知")
                self?.updateLoginStatus()
            }
            .store(in: &cancellables)
        
        // 监听任务卡去运动通知
        NotificationCenter.default.publisher(for: NSNotification.Name("GoWorkoutFromTaskCard"))
            .compactMap { $0.object as? DessertVoucher }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] voucher in
                self?.selectedTaskVoucher = voucher
                // 不再跳转Tab，改为显示独立的运动打卡视图
                self?.showWorkoutView = true
                DRInfo("[AppState] 接收到任务卡，开始运动打卡，voucherId=\(voucher.id)")
            }
            .store(in: &cancellables)
    }
    
    /// 检查登录状态并设置相应的应用状态
    private func checkAndSetupLoginState() {
        let authService = AuthService.shared
        
        // 如果已经有登录用户
        if authService.isLoggedIn, authService.currentUser != nil {
            self.isLoggedIn = true
            self.showLoginView = false
            self.selectedTabIndex = 0 // 直接设置首页为默认页
            DRInfo("AppState: 已检测到登录用户，设置登录状态")
        } else {
            // 未登录状态
            self.isLoggedIn = false
            // 修改：不立即显示登录页，等待AuthService.checkTokenValidity结果
            // self.showLoginView = true
            DRInfo("AppState: 未检测到登录用户，等待token验证")
        }
    }
    
    /// 更新登录状态（从AuthService获取）
    func updateLoginStatus() {
        let authService = AuthService.shared
        
        DispatchQueue.main.async {
            // 根据AuthService的状态更新
            self.isLoggedIn = authService.isLoggedIn
            
            // 如果已登录，关闭登录页面，否则显示登录页面
            if self.isLoggedIn {
                self.showLoginView = false
                DRInfo("AppState: 更新为已登录状态，关闭登录页面")
            } else {
                self.showLoginView = true
                DRInfo("AppState: 更新为未登录状态，显示登录页面")
                
                // 令牌过期时，重置导航状态
                if !authService.isLoggedIn {
                    self.resetNavigation()
                    DRInfo("AppState: 检测到登录失效，已重置导航状态")
                }
            }
        }
    }
    
    /// 重置导航状态
    private func resetNavigation() {
        selectedTabIndex = 0
        shouldResetNavigation = true
        // 延迟重置标志位，确保视图有时间响应
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.shouldResetNavigation = false
        }
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
    
    /// 添加新的美食券
    func addDessertVoucher(_ voucher: DessertVoucher) {
        // 检查是否已存在相同ID的美食券，避免重复
        if !dessertVouchers.contains(where: { $0.id == voucher.id }) {
            dessertVouchers.append(voucher)
            print("【调试】已添加新的美食券: \(voucher.dessertName), ID: \(voucher.id)")
        } else {
            print("【调试】美食券已存在，ID: \(voucher.id)")
        }
        
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
    
    /// 清理所有登录相关的状态
    func clearLoginState() {
        isLoggedIn = false
        showLoginView = true
        selectedTabIndex = 0
        DRInfo("AppState - 登录状态已清理")
    }
    
    /// 处理登出流程，确保UI和数据状态同步
    func handleLogout() {
        DRInfo("AppState - 处理退出登录")
        // 先更新UI状态
        isLoggedIn = false
        showLoginView = true
        
        // 确保状态更新传播到UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.selectedTabIndex = 0
            DRInfo("AppState - 退出登录处理完成")
        }
    }
    
    /// 预加载美食数据
    func preloadDessertData() {
        DRInfo("[AppState] 开始预加载美食数据")
        DessertData.getAllDesserts { desserts in
            DispatchQueue.main.async {
                DRInfo("[AppState] 美食数据预加载完成，共\(desserts.count)项")
            }
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

/// 重置应用扩展
extension AppState {
    /// 重置应用状态
    func resetApp() {
        DRInfo("开始重置应用状态...")
        
        // 显示重置中状态
        isResettingApp = true
        
        // 清除用户默认值
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        // 重置所有状态变量
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoggedIn = false
            self.showLoginView = true
            self.selectedTabIndex = 0
            self.workoutRecords = []
            self.justCompletedWorkout = false
            self.hideTabBarForDrag = false
            self.hideStatusBar = false
            
            // 清除认证服务状态
            AuthService.shared.resetLoginState()
            
            // 完成重置
            self.isResettingApp = false
            DRInfo("应用状态已重置")
        }
    }
} 