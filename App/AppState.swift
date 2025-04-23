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
        // 不自动加载示例数据，由StatsViewModel负责加载
    }
    
    // MARK: - 用户认证方法
    
    /// 模拟一键登录/注册
    func quickLogin(phoneNumber: String, completion: @escaping (Bool) -> Void) {
        // 模拟网络延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 检查是否为首次登录 - 使用真实存储模拟
            // 在实际应用中，这里应该调用服务器API检查用户是否存在
            let isFirstLogin = !UserDefaults.standard.bool(forKey: "hasCompletedUserSetup")
            
            // 创建新的用户资料或更新现有资料
            if isFirstLogin {
                // 创建新用户（首次登录）
                let userId = UUID().uuidString
                self.userProfile = UserProfile(
                    id: userId,
                    name: "新用户\(Int.random(in: 1000...9999))",
                    avatarName: "person.fill"
                )
                self.userProfile.phoneNumber = phoneNumber
                
                // 记录此次登录的电话号码
                UserDefaults.standard.set(phoneNumber, forKey: "lastLoginPhone")
            } else {
                // 更新现有用户（非首次登录）
                self.userProfile.phoneNumber = phoneNumber
                
                // 可能的话，从UserDefaults中加载一些基本信息
                if let name = UserDefaults.standard.string(forKey: "userName") {
                    self.userProfile.name = name
                }
                
                // 如果有保存的性别数据，恢复它
                if let genderRawValue = UserDefaults.standard.string(forKey: "userGender"),
                   let gender = Gender.allCases.first(where: { $0.rawValue == genderRawValue }) {
                    self.userProfile.gender = gender
                }
                
                // 如果有保存的身高和体重数据，恢复它们
                self.userProfile.height = UserDefaults.standard.double(forKey: "userHeight")
                self.userProfile.weight = UserDefaults.standard.double(forKey: "userWeight")
                
                // 如果有保存的运动习惯数据，恢复它
                if let levelRawValue = UserDefaults.standard.string(forKey: "userExerciseLevel"),
                   let level = ExerciseLevel.allCases.first(where: { $0.rawValue == levelRawValue }) {
                    self.userProfile.exerciseLevel = level
                }
            }
            
            // 更新登录状态
            self.isLoggedIn = true
            
            // 返回结果，首次登录需要收集用户信息
            completion(isFirstLogin)
            
            // 提供反馈
            print("【调试】用户登录状态：\(isFirstLogin ? "首次登录" : "非首次登录")")
        }
    }
    
    /// 注销登录
    func logout() {
        // 清除用户登录状态
        isLoggedIn = false
        
        // 在真实应用中，这里应该清除令牌和敏感信息
    }
    
    /// 更新用户信息
    func updateUserProfile(name: String? = nil, gender: Gender? = nil, height: Double? = nil, 
                         weight: Double? = nil, exerciseLevel: ExerciseLevel? = nil) {
        // 更新非空字段
        if let name = name { 
            userProfile.name = name 
            UserDefaults.standard.set(name, forKey: "userName")
        }
        
        if let gender = gender { 
            userProfile.gender = gender 
            UserDefaults.standard.set(gender.rawValue, forKey: "userGender")
        }
        
        if let height = height { 
            userProfile.height = height 
            UserDefaults.standard.set(height, forKey: "userHeight")
        }
        
        if let weight = weight { 
            userProfile.weight = weight 
            UserDefaults.standard.set(weight, forKey: "userWeight")
        }
        
        if let exerciseLevel = exerciseLevel { 
            userProfile.exerciseLevel = exerciseLevel 
            UserDefaults.standard.set(exerciseLevel.rawValue, forKey: "userExerciseLevel")
        }
        
        // 在真实应用中，这里应该同步到后端服务器
        print("【调试】用户资料已更新: \(userProfile.name)")
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
}

/// 应用屏幕枚举
enum AppScreen {
    case home     // 主页
    case stats    // 统计
    case profile  // 个人资料
}

/// 用户资料结构
struct UserProfile: Codable {
    var id: String
    var name: String
    var avatarName: String
    var phoneNumber: String?
    var gender: Gender
    var height: Double?  // 厘米
    var weight: Double?  // 公斤
    var exerciseLevel: ExerciseLevel
    var registerDate: Date
    
    init(id: String, name: String, avatarName: String) {
        self.id = id
        self.name = name
        self.avatarName = avatarName
        self.gender = .other
        self.exerciseLevel = .beginner
        self.registerDate = Date()
    }
}

enum Gender: String, Codable, CaseIterable {
    case male = "男"
    case female = "女"
    case other = "不愿透露"
}

enum ExerciseLevel: String, Codable, CaseIterable {
    case beginner = "初学者"
    case intermediate = "有经验"
    case advanced = "专业人士"
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