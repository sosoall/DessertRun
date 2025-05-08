import Foundation
import SwiftUI
import Combine

// 添加 Notification.Name 扩展
extension Notification.Name {
    static let userRegistered = Notification.Name("userRegistered")
    static let authStatusChanged = Notification.Name("authStatusChanged")
}

/// 认证服务，管理用户登录状态和数据
class AuthService: ObservableObject {
    
    // 用户状态
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var isNewUser: Bool = false
    @Published var isLoading = false
    @Published var error: String?
    
    // 存储Combine订阅
    var cancellables = Set<AnyCancellable>()
    
    // 本地存储键
    private enum StorageKeys {
        static let currentUser = "currentUser"
        static let isLoggedIn = "isLoggedIn"
        static let userCredentials = "userCredentials" // 存储用户凭证
    }
    
    // 单例实例
    static let shared = AuthService()
    
    private init() {
        DRInfo("AuthService 初始化")
        
        // 初始化时先验证token，然后再加载用户数据
        checkTokenValidity { [weak self] isValid in
            if isValid {
                DRInfo("Token有效，加载用户数据")
                self?.loadUserFromStorage()
            } else {
                DRInfo("Token无效或不存在，重置登录状态")
                self?.resetLoginState()
            }
        }
    }
    
    /// 处理token过期
    /// 在任何检测到token过期的地方调用此方法
    func handleTokenExpired() {
        DRInfo("处理Token过期")
        
        // 重置登录状态
        resetLoginState()
        
        // 通知AppState显示登录页面
        DispatchQueue.main.async {
            // 设置AppState的showLoginView为true
            AppState.shared.showLoginView = true
            DRInfo("已设置显示登录页面")
        }
    }
    
    /// 验证当前token是否有效
    /// - Parameter completion: 完成回调，参数为token是否有效
    private func checkTokenValidity(completion: @escaping (Bool) -> Void) {
        // 检查是否存在token
        guard let token = UserDefaults.standard.string(forKey: Config.UserData.tokenKey) else {
            DRInfo("Token不存在")
            completion(false)
            return
        }
        
        DRInfo("开始验证Token有效性: \(token.prefix(10))...")
        
        // 调用API服务获取用户资料，这将隐式验证token
        APIService.shared.getUserProfile()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { result in
                    switch result {
                    case .finished:
                        DRInfo("Token验证成功")
                        completion(true)
                    case .failure(let error):
                        if case .tokenExpired = error {
                            DRInfo("Token已过期")
                            // Token已过期，清除本地token
                            UserDefaults.standard.removeObject(forKey: Config.UserData.tokenKey)
                            UserDefaults.standard.removeObject(forKey: Config.UserData.userIdKey)
                            // 处理token过期
                            AuthService.shared.handleTokenExpired()
                        } else {
                            DRError("Token验证失败: \(error.errorMessage)")
                        }
                        completion(false)
                    }
                },
                receiveValue: { [weak self] apiUser in
                    DRInfo("成功获取用户信息，更新本地用户数据")
                    self?.currentUser = self?.mapToAppUser(apiUser: apiUser)
                    self?.isLoggedIn = true
                    self?.saveUserToStorage()
                    
                    // 确保AppState知道用户已登录，不应显示登录页面
                    DispatchQueue.main.async {
                        AppState.shared.isLoggedIn = true
                        AppState.shared.showLoginView = false
                        DRInfo("已更新AppState: 用户已登录，隐藏登录页面")
                        
                        // 发送认证状态变更通知
                        NotificationCenter.default.post(name: .authStatusChanged, object: nil)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 重置登录状态
    private func resetLoginState() {
        DRInfo("重置登录状态")
        self.currentUser = nil
        self.isLoggedIn = false
        self.isNewUser = false
        UserDefaults.standard.removeObject(forKey: StorageKeys.currentUser)
        UserDefaults.standard.set(false, forKey: StorageKeys.isLoggedIn)
    }
    
    /// 从本地存储加载用户
    private func loadUserFromStorage() {
        DRInfo("从本地存储加载用户数据")
        
        if let userData = UserDefaults.standard.data(forKey: StorageKeys.currentUser),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isLoggedIn = UserDefaults.standard.bool(forKey: StorageKeys.isLoggedIn)
            DRInfo("成功加载用户: \(user.phoneNumber)")
        } else {
            DRInfo("本地没有存储用户数据")
        }
    }
    
    /// 保存用户到本地存储
    func saveUserToStorage() {
        guard let user = currentUser else { 
            DRWarning("尝试保存nil用户")
            return
        }
        
        DRInfo("保存用户到本地存储: \(user.phoneNumber)")
        
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: StorageKeys.currentUser)
            UserDefaults.standard.set(isLoggedIn, forKey: StorageKeys.isLoggedIn)
        } else {
            DRError("用户数据编码失败")
        }
    }
    
    /// 将API用户转换为App用户模型
    private func mapToAppUser(apiUser: APIUser) -> User {
        // 将API用户转换为本地用户
        return apiUser.toLocalUser()
    }
    
    /// 发送验证码
    func sendVerificationCode(phoneNumber: String, completion: @escaping (Bool) -> Void) {
        DRInfo("开始发送验证码: \(phoneNumber)")
        isLoading = true
        error = nil
        
        APIService.shared.getVerificationCode(phone: phoneNumber)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isLoading = false
                    switch result {
                    case .finished:
                        DRInfo("验证码发送成功: \(phoneNumber)")
                        completion(true)
                    case .failure(let error):
                        DRError("验证码发送失败: \(error.errorMessage)")
                        self?.error = error.errorMessage
                        completion(false)
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    /// 使用验证码登录
    func loginWithVerificationCode(phoneNumber: String, code: String, completion: @escaping (Bool) -> Void) {
        DRInfo("开始验证码登录: \(phoneNumber)")
        isLoading = true
        error = nil
        
        APIService.shared.loginWithVerificationCode(phone: phoneNumber, code: code)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isLoading = false
                    switch result {
                    case .finished:
                        DRInfo("验证码登录成功: \(phoneNumber)")
                        self?.isLoggedIn = true
                        self?.saveUserToStorage()
                        
                        // 检查是否是新用户（自动注册）
                        if let isNewUser = self?.currentUser?.isNewUser, isNewUser {
                            DRInfo("新用户自动注册成功，准备收集个人信息")
                            NotificationCenter.default.post(name: .userRegistered, object: nil)
                        }
                        
                        completion(true)
                    case .failure(let error):
                        DRError("验证码登录失败: \(error.errorMessage)")
                        self?.error = error.errorMessage
                        completion(false)
                    }
                },
                receiveValue: { [weak self] apiUser in
                    DRInfo("获取到用户数据: \(apiUser.nickname ?? "未设置昵称")")
                    self?.currentUser = self?.mapToAppUser(apiUser: apiUser)
                }
            )
            .store(in: &cancellables)
    }
    
    /// 使用密码登录
    func loginWithPassword(phoneNumber: String, password: String, completion: @escaping (Bool) -> Void) {
        DRInfo("开始密码登录: \(phoneNumber)")
        isLoading = true
        error = nil
        
        APIService.shared.loginWithPassword(phone: phoneNumber, password: password)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isLoading = false
                    switch result {
                    case .finished:
                        DRInfo("密码登录成功: \(phoneNumber)")
                        self?.isLoggedIn = true
                        self?.saveUserToStorage()
                        completion(true)
                    case .failure(let error):
                        DRError("密码登录失败: \(error.errorMessage)")
                        self?.error = error.errorMessage
                        completion(false)
                    }
                },
                receiveValue: { [weak self] apiUser in
                    DRInfo("获取到用户数据: \(apiUser.nickname ?? "未设置昵称")")
                    self?.currentUser = self?.mapToAppUser(apiUser: apiUser)
                }
            )
            .store(in: &cancellables)
    }
    
    /// 注册新用户
    func register(phoneNumber: String, password: String, confirmPassword: String, code: String, nickname: String, completion: @escaping (Bool) -> Void) {
        DRInfo("开始注册新用户: \(phoneNumber), 昵称: \(nickname)")
        isLoading = true
        error = nil
        
        APIService.shared.register(phone: phoneNumber, password: password, confirmPassword: confirmPassword, code: code, nickname: nickname)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isLoading = false
                    switch result {
                    case .finished:
                        DRInfo("用户注册成功: \(phoneNumber)")
                        self?.isLoggedIn = true
                        self?.isNewUser = true
                        self?.saveUserToStorage()
                        completion(true)
                    case .failure(let error):
                        DRError("用户注册失败: \(error.errorMessage)")
                        self?.error = error.errorMessage
                        completion(false)
                    }
                },
                receiveValue: { [weak self] apiUser in
                    DRInfo("获取到新注册用户数据: \(apiUser.nickname ?? "未设置昵称")")
                    self?.currentUser = self?.mapToAppUser(apiUser: apiUser)
                }
            )
            .store(in: &cancellables)
    }
    
    /// 根据手机号查询用户（模拟数据库查询）
    private func fetchUserByPhone(_ phoneNumber: String) -> User? {
        DRInfo("通过手机号查询用户: \(phoneNumber)")
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
        guard let user = currentUser else { 
            DRWarning("尝试更新不存在的用户资料")
            return 
        }
        
        DRInfo("更新用户资料: \(user.phoneNumber)")
        
        // 创建身体数据对象（如果不存在）
        if user.bodyData == nil {
            user.bodyData = BodyData()
        }
        
        // 创建运动习惯对象（如果不存在）
        if user.exerciseHabit == nil {
            user.exerciseHabit = ExerciseHabit()
        }
        
        // 记录原始体重，用于检测变化
        let oldWeight = user.bodyData?.weight
        
        if let nickname = nickname { 
            DRInfo("更新昵称: \(nickname)")
            user.nickname = nickname 
        }
        if let gender = gender { 
            DRInfo("更新性别: \(gender.rawValue)")
            user.gender = gender 
        }
        if let height = height { 
            DRInfo("更新身高: \(height)")
            user.bodyData?.height = height 
        }
        if let weight = weight { 
            DRInfo("更新体重: \(weight)")
            user.bodyData?.weight = weight 
            
            // 如果体重有变化，清除运动计算缓存
            if oldWeight != weight {
                DRInfo("体重已变更，清除运动计算缓存")
                DessertToExerciseTransition.clearAllExerciseCalculationCaches()
            }
        }
        if let hasExerciseHabit = hasExerciseHabit { 
            DRInfo("更新运动习惯: \(hasExerciseHabit)")
            user.exerciseHabit?.hasExerciseHabit = hasExerciseHabit 
        }
        
        // 检查是否完成了个人资料填写
        if user.nickname != nil && user.gender != nil && 
           user.bodyData?.height != nil && user.bodyData?.weight != nil && 
           user.exerciseHabit?.hasExerciseHabit != nil {
            user.isProfileCompleted = true
            // 个人资料填写完成后，不再是新用户
            user.isNewUser = false
            DRInfo("用户资料已完成填写，标记为非新用户")
        }
        
        self.currentUser = user
        // 同步更新isNewUser状态
        self.isNewUser = user.isNewUser
        saveUserToStorage()
        
        // 如果已经通过API登录，更新用户资料到服务器
        if user.apiUserId != nil {
            DRInfo("同步用户资料到服务器")
            let updateRequest = user.prepareProfileUpdateRequest()
            
            APIService.shared.updateUserProfile(profile: updateRequest)
                .receive(on: DispatchQueue.main) // 确保在主线程接收结果
                .sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            DRError("更新用户资料到服务器失败: \(error.errorMessage)")
                        }
                    },
                    receiveValue: { updatedUser in
                        DRInfo("用户资料已同步到服务器")
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    /// 退出登录
    func logout() {
        DRInfo("用户退出登录")
        
        // 清除用户数据和登录状态
        self.currentUser = nil
        self.isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: StorageKeys.currentUser)
        UserDefaults.standard.set(false, forKey: StorageKeys.isLoggedIn)
        
        // 清除令牌
        UserDefaults.standard.removeObject(forKey: Config.UserData.tokenKey)
        UserDefaults.standard.removeObject(forKey: Config.UserData.userIdKey)
        
        // 发送通知登录状态已更改
        NotificationCenter.default.post(name: .authStatusChanged, object: nil)
    }
    
    /// 清除用户数据
    func clearUserData() {
        DRInfo("清除所有用户数据")
        
        // 彻底删除用户数据
        UserDefaults.standard.removeObject(forKey: StorageKeys.currentUser)
        UserDefaults.standard.removeObject(forKey: StorageKeys.isLoggedIn)
        
        // 清除token和用户ID
        UserDefaults.standard.removeObject(forKey: Config.UserData.tokenKey)
        UserDefaults.standard.removeObject(forKey: Config.UserData.userIdKey)
        
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
        
        DRInfo("所有用户数据已清除")
    }
    
    /// 彻底清除所有UserDefaults数据（慎用，仅用于开发测试）
    func deleteAllUserDefaults() {
        DRInfo("彻底清除所有应用数据")
        
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
            
            // 重置内存中的状态
            self.currentUser = nil
            self.isLoggedIn = false
            self.isNewUser = false
            
            DRInfo("已彻底清除所有应用数据")
        }
    }
    
    /// 为新用户自动填充个人信息
    func autoFillUserProfile() {
        guard let user = currentUser else { 
            DRWarning("尝试为不存在的用户自动填充资料")
            return 
        }
        
        DRInfo("为新用户自动填充个人信息: \(user.phoneNumber)")
        
        // 创建身体数据对象（如果不存在）
        if user.bodyData == nil {
            user.bodyData = BodyData()
        }
        
        // 创建运动习惯对象（如果不存在）
        if user.exerciseHabit == nil {
            user.exerciseHabit = ExerciseHabit()
        }
        
        user.nickname = "跑步达人"
        user.gender = .male
        user.bodyData?.height = 175
        user.bodyData?.weight = 65
        user.birthYear = 1990
        user.exerciseHabit?.hasExerciseHabit = true
        saveUserToStorage()
    }
    
    /// 清理应用所有状态，用于重置到初始未登录状态
    func resetAppToInitialState() {
        DRInfo("重置应用到初始状态")
        
        // 清理所有用户数据
        deleteAllUserDefaults()
        
        // 重置应用状态
        self.currentUser = nil
        self.isLoggedIn = false
        self.isNewUser = false
    }
} 