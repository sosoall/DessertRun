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
    
    // 确认退出登录对话框状态
    @State private var showLogoutConfirm = false
    
    // 设置项列表
    private let settingItems: [(icon: String, title: String, color: Color)] = [
        ("person.text.rectangle.fill", "账户安全设置", Color.blue),
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
                if authService.isLoggedIn {
                    Button(action: {
                        authService.clearUserData()
                        appState.updateLoginStatus()
                    }) {
                        Text("清除测试数据")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.vertical, 8)
                    }
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
        .alert("确认退出登录", isPresented: $showLogoutConfirm) {
            Button("取消", role: .cancel) { }
            Button("确认退出", role: .destructive) {
                authService.logout()
                appState.updateLoginStatus()
            }
        } message: {
            Text("退出登录后需要重新登录才能使用个人功能")
        }
    }
    
    // 用户资料卡片
    var userProfileCard: some View {
        HStack(spacing: 16) {
            // 头像
            if authService.isLoggedIn {
                Image(systemName: appState.userProfile.avatarName)
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
                    Text(appState.userProfile.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    if let phoneNumber = authService.currentUser?.phoneNumber {
                        Text(phoneNumber)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
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
                Image(systemName: "pencil")
                    .font(.title3)
                    .foregroundColor(Color(hex: "FE2D55"))
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
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
                // 个人资料
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(Color.blue)
                        .frame(width: 30, height: 30)
                    
                    Text("个人资料")
                        .font(.body)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                
                Divider()
                    .padding(.leading, 56)
                
                // 身体数据
                HStack {
                    Image(systemName: "figure.stand")
                        .foregroundColor(Color.orange)
                        .frame(width: 30, height: 30)
                    
                    Text("身体数据")
                        .font(.body)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                
                Divider()
                    .padding(.leading, 56)
                
                // 运动偏好
                HStack {
                    Image(systemName: "figure.run")
                        .foregroundColor(Color.green)
                        .frame(width: 30, height: 30)
                    
                    Text("运动偏好设置")
                        .font(.body)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                
                Divider()
                    .padding(.leading, 56)
                
                // 运动成就
                HStack {
                    Image(systemName: "medal.fill")
                        .foregroundColor(Color(hex: "FE2D55"))
                        .frame(width: 30, height: 30)
                    
                    Text("运动成就")
                        .font(.body)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
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

#Preview {
    NavigationView {
        ProfileHomeView()
            .environmentObject(AppState.shared)
    }
} 