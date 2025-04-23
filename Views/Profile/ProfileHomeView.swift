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
    
    // 设置项列表
    private let settingItems: [(icon: String, title: String, color: Color)] = [
        ("bell.fill", "通知设置", Color.orange),
        ("heart.fill", "健康数据授权", Color.red),
        ("location.fill", "位置服务", Color.blue),
        ("cloud.fill", "数据同步", Color.purple),
        ("gear", "应用设置", Color.gray),
        ("questionmark.circle.fill", "帮助与反馈", Color.green),
        ("info.circle.fill", "关于我们", Color.blue)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 用户资料卡片
                userProfileCard
                
                // 分割线
                Divider()
                    .padding(.horizontal)
                
                // 运动成就
                achievementSection
                
                // 分割线
                Divider()
                    .padding(.horizontal)
                
                // 设置列表
                settingsSection
                
                // 退出登录按钮
                if appState.isLoggedIn {
                    Button(action: {
                        // 退出登录逻辑
                        appState.isLoggedIn = false
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
                        // 登录逻辑
                        appState.isLoggedIn = true
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
                
                Spacer()
                    .frame(height: 30)
            }
            .padding(.top, 16)
        }
        .background(Color(hex: "fae8c8").ignoresSafeArea())
        .navigationBarHidden(true)
    }
    
    // 用户资料卡片
    var userProfileCard: some View {
        HStack(spacing: 16) {
            // 头像
            if appState.isLoggedIn {
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
                if appState.isLoggedIn {
                    Text(appState.userProfile.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // 显示性别和运动习惯
                    HStack(spacing: 8) {
                        Text(appState.userProfile.gender.rawValue)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(hex: "FE2D55").opacity(0.8))
                            .cornerRadius(10)
                        
                        Text(appState.userProfile.exerciseLevel.rawValue)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(hex: "FF9901").opacity(0.8))
                            .cornerRadius(10)
                    }
                    
                    // 身高体重信息
                    if let height = appState.userProfile.height, let weight = appState.userProfile.weight {
                        Text("\(Int(height))cm / \(String(format: "%.1f", weight))kg")
                            .font(.caption)
                            .foregroundColor(Color(hex: "666666"))
                    }
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
            if appState.isLoggedIn {
                NavigationLink(destination: ProfileEditView()) {
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
    
    // 成就部分
    var achievementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("运动成就")
                .font(.headline)
                .foregroundColor(Color(hex: "61462C"))
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                // 累计运动
                VStack {
                    Text("25")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "FE2D55"))
                    Text("累计运动\n(天)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                // 累计距离
                VStack {
                    Text("103")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "FE2D55"))
                    Text("累计距离\n(千米)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 40)
                
                // 甜品券
                VStack {
                    Text("32")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "FE2D55"))
                    Text("获得甜品券\n(张)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
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
                    NavigationLink(destination: getSettingsDestination(for: index)) {
                        HStack {
                            // 图标
                            Image(systemName: settingItems[index].icon)
                                .foregroundColor(settingItems[index].color)
                                .frame(width: 30, height: 30)
                            
                            // 标题
                            Text(settingItems[index].title)
                                .font(.body)
                                .foregroundColor(Color(hex: "333333"))
                            
                            Spacer()
                            
                            // 箭头
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                    }
                    
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
    
    // 根据索引获取对应的设置目标页面
    @ViewBuilder
    private func getSettingsDestination(for index: Int) -> some View {
        switch index {
        case 0: // 通知设置
            Text("通知设置页面")
                .navigationTitle("通知设置")
        case 1: // 健康数据授权
            Text("健康数据授权页面")
                .navigationTitle("健康数据授权")
        case 2: // 位置服务
            Text("位置服务页面")
                .navigationTitle("位置服务")
        case 3: // 数据同步
            Text("数据同步页面")
                .navigationTitle("数据同步")
        case 4: // 应用设置
            Text("应用设置页面")
                .navigationTitle("应用设置")
        case 5: // 帮助与反馈
            Text("帮助与反馈页面")
                .navigationTitle("帮助与反馈")
        case 6: // 关于我们
            AboutView()
                .navigationTitle("关于我们")
        default:
            EmptyView()
        }
    }
}

#Preview {
    NavigationView {
        ProfileHomeView()
            .environmentObject(AppState.shared)
    }
} 