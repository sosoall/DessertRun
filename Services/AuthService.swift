import Foundation
import Combine

/// 认证服务，管理用户登录状态和数据
class AuthService: ObservableObject {
    
    // 用户状态
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var isNewUser: Bool = false
    
    // 本地存储键
    private enum StorageKeys {
        static let currentUser = "currentUser"
        static let isLoggedIn = "isLoggedIn"
    }
    
    // 测试手机号
    static let testPhoneNumber = "15010209342"
    
    // 单例实例
    static let shared = AuthService()
    
    private init() {
        loadUserFromStorage()
        
        // 如果没有用户登录，自动登录测试用户并填充资料
        if currentUser == nil || !isLoggedIn {
            autoLoginTestUser()
        }
    }
    
    /// 从本地存储加载用户
    private func loadUserFromStorage() {
        if let userData = UserDefaults.standard.data(forKey: StorageKeys.currentUser),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isLoggedIn = UserDefaults.standard.bool(forKey: StorageKeys.isLoggedIn)
        }
    }
    
    /// 保存用户到本地存储
    private func saveUserToStorage() {
        guard let user = currentUser else { return }
        
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: StorageKeys.currentUser)
            UserDefaults.standard.set(isLoggedIn, forKey: StorageKeys.isLoggedIn)
        }
    }
    
    /// 自动登录测试用户
    private func autoLoginTestUser() {
        let phoneNumber = AuthService.testPhoneNumber
        
        // 创建测试用户
        let testUser = User(phoneNumber: phoneNumber)
        testUser.nickname = "测试用户"
        testUser.gender = .male
        testUser.height = 175.0
        testUser.weight = 70.0
        testUser.hasExerciseHabit = true
        testUser.isProfileCompleted = true
        
        self.currentUser = testUser
        self.isLoggedIn = true
        self.isNewUser = false
        saveUserToStorage()
        
        print("已自动登录测试用户并填充个人信息")
    }
    
    /// 模拟一键登录认证
    /// - Returns: 是否为新用户
    func oneClickLogin() -> Bool {
        // 模拟从运营商获取手机号
        let phoneNumber = AuthService.testPhoneNumber
        
        // 检查是否已存在该用户
        if let existingUser = fetchUserByPhone(phoneNumber) {
            self.currentUser = existingUser
            self.isLoggedIn = true
            self.isNewUser = false
            saveUserToStorage()
            return false
        } else {
            // 创建新用户
            let newUser = User(phoneNumber: phoneNumber)
            self.currentUser = newUser
            self.isLoggedIn = true
            self.isNewUser = true
            saveUserToStorage()
            return true
        }
    }
    
    /// 根据手机号查询用户（模拟数据库查询）
    private func fetchUserByPhone(_ phoneNumber: String) -> User? {
        // 在实际项目中，这里应该从服务器获取用户信息
        // 这里仅通过本地存储模拟
        if let userData = UserDefaults.standard.data(forKey: StorageKeys.currentUser),
           let user = try? JSONDecoder().decode(User.self, from: userData),
           user.phoneNumber == phoneNumber {
            return user
        }
        return nil
    }
    
    /// 更新用户信息
    func updateUserProfile(
        nickname: String? = nil,
        gender: User.Gender? = nil,
        height: Double? = nil, 
        weight: Double? = nil,
        hasExerciseHabit: Bool? = nil
    ) {
        guard var user = currentUser else { return }
        
        if let nickname = nickname { user.nickname = nickname }
        if let gender = gender { user.gender = gender }
        if let height = height { user.height = height }
        if let weight = weight { user.weight = weight }
        if let hasExerciseHabit = hasExerciseHabit { user.hasExerciseHabit = hasExerciseHabit }
        
        // 检查是否完成了个人资料填写
        if user.nickname != nil && user.gender != nil && 
           user.height != nil && user.weight != nil && 
           user.hasExerciseHabit != nil {
            user.isProfileCompleted = true
        }
        
        self.currentUser = user
        saveUserToStorage()
    }
    
    /// 为测试用户自动填充个人信息（开发阶段使用）
    func autoFillTestUserProfile() {
        guard var user = currentUser, user.phoneNumber == AuthService.testPhoneNumber else { return }
        
        // 设置默认个人信息
        user.nickname = "测试用户"
        user.gender = .male
        user.height = 175.0
        user.weight = 70.0
        user.hasExerciseHabit = true
        user.isProfileCompleted = true
        
        self.currentUser = user
        self.isNewUser = false
        saveUserToStorage()
        
        print("已为测试用户自动填充个人信息")
    }
    
    /// 退出登录
    func logout() {
        self.currentUser = nil
        self.isLoggedIn = false
        self.isNewUser = false
        UserDefaults.standard.removeObject(forKey: StorageKeys.currentUser)
        UserDefaults.standard.set(false, forKey: StorageKeys.isLoggedIn)
    }
    
    /// 清除测试用户数据（用于测试）
    func clearTestUserData() {
        // 彻底删除用户数据
        UserDefaults.standard.removeObject(forKey: StorageKeys.currentUser)
        UserDefaults.standard.removeObject(forKey: StorageKeys.isLoggedIn)
        
        // 清除所有与用户相关的数据
        // 查找所有以user_开头的键值对并删除
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        for key in allKeys {
            if key.hasPrefix("user_") || key.contains("login") || key.contains("auth") {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        
        // 重置内存中的状态
        self.currentUser = nil
        self.isLoggedIn = false
        self.isNewUser = false
        
        print("已清除测试用户数据")
    }
    
    /// 彻底清除所有UserDefaults数据（慎用，仅用于开发测试）
    func deleteAllUserDefaults() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
            
            // 重置内存中的状态
            self.currentUser = nil
            self.isLoggedIn = false
            self.isNewUser = false
            
            print("已彻底清除所有应用数据")
        }
    }
    
    /// 为新用户自动填充个人信息
    func autoFillUserProfile() {
        if let user = currentUser {
            user.nickname = "跑步达人"
            user.gender = .male
            user.height = 175
            user.weight = 65
            user.birthYear = 1990
            user.exerciseFrequency = .threeToFive
            user.exerciseDuration = .thirtyToSixty
            saveUserToStorage()
        }
    }
} 