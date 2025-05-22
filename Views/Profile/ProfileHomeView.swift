//
//  ProfileHomeView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

/// 个人信息模块主页面
struct ProfileHomeView: View {
    // 全局应用状态
    @EnvironmentObject var appState: AppState
    
    // 认证服务
    @StateObject private var authService = AuthService.shared
    
    // 显示登录页的状态
    @State private var showLoginView = false
    
    // 用户信息设置视图的控制状态
    @State private var showBasicInfoSetup = false
    @State private var showBodyDataSetup = false
    @State private var showExerciseHabitSetup = false
    
    // 确认退出登录对话框状态
    @State private var showLogoutConfirm = false
    
    // API加载状态
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    // 设置项列表
    private let settingItems: [(icon: String, title: String, color: Color)] = [
        ("lock.shield.fill", "账户安全设置", Color.blue),
        ("lock.shield.fill", "隐私设置", Color.green),
        ("bell.fill", "通知设置", Color.orange),
        ("heart.fill", "健康数据集成", Color.red)
    ]
    
    // 关于项列表
    private let aboutItems: [(icon: String, title: String, color: Color)] = [
        ("doc.text.fill", "隐私政策", Color.purple),
        ("doc.plaintext.fill", "协议条款", Color.purple),
        ("info.circle.fill", "关于DessertRun", Color.blue),
        ("questionmark.circle.fill", "反馈与建议", Color.green)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 用户资料卡片
                userProfileCard
                
                // 用户信息部分
                userInfoSection
                
                // 设置部分
                settingsSection
                
                // 关于部分
                aboutSection
                
                // 退出登录或登录按钮
                if authService.isLoggedIn {
                    Button(action: {
                        showLogoutConfirm = true
                    }) {
                        Text("退出登录")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "FE2D55"))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                } else {
                    Button(action: {
                        showLoginView = true
                    }) {
                        Text("登录/注册")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "FE2D55"))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                
                // 开发测试功能
                #if DEBUG
                // 开发者工具部分
                VStack(alignment: .leading, spacing: 12) {
                    Text("开发者工具")
                        .font(.headline)
                        .foregroundColor(Color(hex: "61462C"))
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        // 环境设置
                        NavigationLink(destination: EnvironmentSettingsView()) {
                            HStack {
                                Image(systemName: "server.rack")
                                    .foregroundColor(Color.purple)
                                    .frame(width: 30, height: 30)
                                
                                Text("服务器环境设置")
                                    .font(.body)
                                
                                Spacer()
                                
                                Text(Config.API.environment.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color.white)
                        }
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        // 显示API地址
                        HStack {
                            Image(systemName: "network")
                                .foregroundColor(Color.blue)
                                .frame(width: 30, height: 30)
                            
                            Text("当前API地址")
                                .font(.body)
                            
                            Spacer()
                            
                            Text(Config.API.baseURL)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .padding()
                        .background(Color.white)
                        
                        Divider()
                            .padding(.leading, 56)
                        
                        // 清除测试数据
                        if authService.isLoggedIn {
                            Button(action: {
                                authService.clearUserData()
                                appState.updateLoginStatus()
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .foregroundColor(Color.red)
                                        .frame(width: 30, height: 30)
                                    
                                    Text("清除测试数据")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(Color.white)
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                }
                #endif
                
                Spacer()
                    .frame(height: 30)
            }
            .padding(.top, 16)
        }
        .background(Color(hex: "fae8c8").ignoresSafeArea())
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showLoginView) {
            LoginView()
        }
        .fullScreenCover(isPresented: $showBasicInfoSetup) {
            UserInfoSetupPage(currentStep: 0, onDismiss: {
                showBasicInfoSetup = false
                // 重新获取用户资料
                fetchUserProfile()
            })
        }
        .fullScreenCover(isPresented: $showBodyDataSetup) {
            UserInfoSetupPage(currentStep: 1, onDismiss: {
                showBodyDataSetup = false
                // 重新获取用户资料
                fetchUserProfile()
            })
        }
        .fullScreenCover(isPresented: $showExerciseHabitSetup) {
            UserInfoSetupPage(currentStep: 2, onDismiss: {
                showExerciseHabitSetup = false
                // 重新获取用户资料
                fetchUserProfile()
            })
        }
        .alert("确认退出登录", isPresented: $showLogoutConfirm) {
            Button("取消", role: .cancel) { }
            Button("确认退出", role: .destructive) {
                authService.logout()
                appState.updateLoginStatus()
                // 显示登录页面
                showLoginView = true
            }
        } message: {
            Text("退出登录后需要重新登录才能使用个人功能")
        }
        .onAppear {
            if authService.isLoggedIn {
                fetchUserProfile()
            }
        }
    }
    
    // 获取用户资料
    private func fetchUserProfile() {
        isLoading = true
        errorMessage = nil
        
        DRInfo("开始获取用户资料...")
        
        // 创建组，等待所有API调用完成
        let group = DispatchGroup()
        
        // 1. 获取基本用户资料
        group.enter()
        APIService.shared.getUserProfile()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        errorMessage = error.errorMessage
                        DRError("获取用户基本资料失败: \(error.errorMessage)")
                    }
                    group.leave()
                },
                receiveValue: { apiUser in
                    DRInfo("获取用户基本资料成功: \(apiUser.nickname ?? "未设置昵称")")
                    
                    // 更新本地用户数据 - 基本信息
                    if let currentUser = authService.currentUser {
                        // 将API返回的数据更新到现有用户对象
                        currentUser.nickname = apiUser.nickname
                        currentUser.avatar = apiUser.avatar
                        currentUser.gender = apiUser.gender.flatMap { User.Gender.fromApiString($0) }
                        currentUser.birthYear = apiUser.birthYear
                        currentUser.apiUserId = apiUser.id
                        currentUser.isNewUser = apiUser.isNewUser ?? false
                        currentUser.isProfileCompleted = apiUser.isProfileCompleted ?? false
                    } else {
                        // 如果没有当前用户，创建一个新的
                        authService.currentUser = apiUser.toLocalUser()
                    }
                }
            )
            .store(in: &authService.cancellables)
        
        // 2. 获取身体数据
        group.enter()
        APIService.shared.getUserBodyData()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        DRError("获取身体数据失败: \(error.errorMessage)")
                    }
                    group.leave()
                },
                receiveValue: { bodyData in
                    DRInfo("获取身体数据成功: 身高=\(bodyData.height ?? 0), 体重=\(bodyData.weight ?? 0)")
                    
                    // 更新本地用户数据 - 身体数据
                    if let currentUser = authService.currentUser {
                        // 如果没有身体数据对象，创建一个
                        if currentUser.bodyData == nil {
                            currentUser.bodyData = BodyData()
                        }
                        
                        // 更新身体数据
                        currentUser.bodyData?.height = bodyData.height
                        currentUser.bodyData?.weight = bodyData.weight
                    }
                }
            )
            .store(in: &authService.cancellables)
        
        // 3. 获取运动习惯
        group.enter()
        APIService.shared.getUserExerciseHabit()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        DRError("获取运动习惯失败: \(error.errorMessage)")
                    }
                    group.leave()
                },
                receiveValue: { exerciseHabit in
                    DRInfo("获取运动习惯成功: 是否有运动习惯=\(exerciseHabit.hasExerciseHabit ?? false)")
                    
                    // 更新本地用户数据 - 运动习惯
                    if let currentUser = authService.currentUser {
                        // 如果没有运动习惯对象，创建一个
                        if currentUser.exerciseHabit == nil {
                            currentUser.exerciseHabit = ExerciseHabit()
                        }
                        
                        // 更新运动习惯 - 确保hasExerciseHabit不为nil
                        currentUser.exerciseHabit?.hasExerciseHabit = exerciseHabit.hasExerciseHabit ?? false
                        currentUser.exerciseHabit?.exerciseFrequency = exerciseHabit.exerciseFrequency
                        currentUser.exerciseHabit?.exerciseDuration = exerciseHabit.exerciseDuration
                    }
                }
            )
            .store(in: &authService.cancellables)
        
        // 所有API调用完成后
        group.notify(queue: .main) {
            isLoading = false
            
            // 保存到本地存储
            authService.saveUserToStorage()
            
            // 更新AppState中的用户资料
            appState.updateLoginStatus()
            
            DRInfo("所有用户资料获取完成")
        }
    }
    
    // 获取钱包信息
    /* 星币功能已移除
    private func fetchWalletInfo() {
        APIService.shared.getWalletInfo()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        DRError("获取钱包信息失败: \(error.errorMessage)")
                    }
                },
                receiveValue: { wallet in
                    DRInfo("获取钱包信息成功: 星币余额=\(wallet.stars)")
                    self.walletInfo = wallet
                }
            )
            .store(in: &authService.cancellables)
    }
    */
    
    // 用户资料卡片
    var userProfileCard: some View {
        HStack(spacing: 16) {
            // 头像
            if authService.isLoggedIn {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "FE2D55"))
                    .frame(width: 80, height: 80)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.gray)
                    .frame(width: 80, height: 80)
            }
            
            // 用户信息
            VStack(alignment: .leading, spacing: 4) {
                if authService.isLoggedIn {
                    Text(authService.currentUser?.nickname ?? "甜品爱好者")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("甜品爱好者")
                        .font(.caption)
                        .foregroundColor(Color(hex: "FE2D55"))
                } else {
                    Text("未登录")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("登录后享受更多功能")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // 编辑按钮
            if authService.isLoggedIn {
                Button(action: {
                    showBasicInfoSetup = true
                }) {
                    Image(systemName: "pencil")
                        .font(.title3)
                        .foregroundColor(Color(hex: "FE2D55"))
                        .frame(width: 40, height: 40)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // 用户信息部分
    var userInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("用户信息")
                .font(.headline)
                .foregroundColor(Color(hex: "61462C"))
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                // 身体数据设置
                Button(action: {
                    showBodyDataSetup = true
                }) {
                    HStack {
                        Image(systemName: "figure.walk.circle.fill")
                            .foregroundColor(Color.orange)
                            .frame(width: 30, height: 30)
                        
                        Text("身体数据")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if authService.isLoggedIn, let user = authService.currentUser {
                            if let bodyData = user.bodyData, let height = bodyData.height, let weight = bodyData.weight {
                                Text("\(Int(height))厘米 / \(Int(weight))公斤")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else {
                                Text("未设置")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        } else {
                            Text("请先登录")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                }
                .disabled(!authService.isLoggedIn)
                
                Divider()
                    .padding(.leading, 56)
                
                // 运动偏好设置
                Button(action: {
                    showExerciseHabitSetup = true
                }) {
                    HStack {
                        Image(systemName: "heart.circle.fill")
                            .foregroundColor(Color.red)
                            .frame(width: 30, height: 30)
                        
                        Text("运动偏好设置")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if authService.isLoggedIn, let user = authService.currentUser {
                            if let exerciseHabit = user.exerciseHabit, let hasExerciseHabit = exerciseHabit.hasExerciseHabit {
                                Text(hasExerciseHabit ? "有运动习惯" : "无运动习惯")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else {
                                Text("未设置")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        } else {
                            Text("请先登录")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                }
                .disabled(!authService.isLoggedIn)
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
    
    // 设置部分
    var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("设置")
                .font(.headline)
                .foregroundColor(Color(hex: "61462C"))
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(0..<settingItems.count, id: \.self) { index in
                    HStack {
                        // 图标
                        Image(systemName: settingItems[index].icon)
                            .foregroundColor(settingItems[index].color)
                            .frame(width: 30, height: 30)
                        
                        // 标题
                        Text(settingItems[index].title)
                            .font(.body)
                        
                        Spacer()
                        
                        // 箭头
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    
                    if index < settingItems.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
    
    // 关于部分
    var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("关于")
                .font(.headline)
                .foregroundColor(Color(hex: "61462C"))
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(0..<aboutItems.count, id: \.self) { index in
                    HStack {
                        // 图标
                        Image(systemName: aboutItems[index].icon)
                            .foregroundColor(aboutItems[index].color)
                            .frame(width: 30, height: 30)
                        
                        // 标题
                        Text(aboutItems[index].title)
                            .font(.body)
                        
                        Spacer()
                        
                        // 箭头
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    
                    if index < aboutItems.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
}

// 用于单独编辑用户信息的包装视图
struct UserInfoSetupPage: View {
    var currentStep: Int
    var onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            UserInfoSetupView(initialStep: currentStep, isModal: true, onDismiss: onDismiss)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("关闭") {
                            onDismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    NavigationView {
        ProfileHomeView()
            .environmentObject(AppState.shared)
    }
} 