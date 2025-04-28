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
    @State private var showUserInfoSetup = false
    @State private var userInfoEditPage = 0
    
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
        .fullScreenCover(isPresented: $showUserInfoSetup) {
            UserInfoSetupPage(currentStep: userInfoEditPage, onDismiss: {
                showUserInfoSetup = false
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
        
        APIService.shared.getUserProfile()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoading = false
                    if case let .failure(error) = completion {
                        errorMessage = error.errorMessage
                        DRError("获取用户资料失败: \(error.errorMessage)")
                        
                        // 如果是无法解析的错误，尝试显示一些详细的调试信息
                        if error.errorMessage.contains("数据解析失败") {
                            DRInfo("可能是服务端API格式与客户端定义不匹配，请检查APIUser模型")
                            DRInfo("API字段: id, phone_number, nickname, gender, height, weight, has_exercise_habit, created_at, updated_at, is_new_user, is_profile_completed")
                            DRInfo("APIUser模型字段检查: \(Mirror(reflecting: APIUser.self).description)")
                        }
                    } else {
                        DRInfo("获取用户资料请求完成")
                    }
                },
                receiveValue: { apiUser in
                    DRInfo("获取用户资料成功: \(apiUser.nickname ?? "未设置昵称")")
                    DRInfo("用户详情: id=\(apiUser.id), phone=\(apiUser.phone), gender=\(apiUser.gender ?? "未设置"), height=\(apiUser.height ?? 0), weight=\(apiUser.weight ?? 0)")
                    
                    // 更新本地用户数据
                    authService.currentUser = apiUser.toLocalUser()
                    authService.saveUserToStorage()
                    
                    // 更新AppState中的用户资料
                    appState.updateLoginStatus()
                }
            )
            .store(in: &authService.cancellables)
    }
    
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
                    userInfoEditPage = 0 // 跳转到第一页（名称和性别）
                    showUserInfoSetup = true
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
                    userInfoEditPage = 1 // 跳转到第二页（身高和体重）
                    showUserInfoSetup = true
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
                            if let height = user.height, let weight = user.weight {
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
                    userInfoEditPage = 2 // 跳转到第三页（运动习惯）
                    showUserInfoSetup = true
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
                            if let hasExerciseHabit = user.hasExerciseHabit {
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