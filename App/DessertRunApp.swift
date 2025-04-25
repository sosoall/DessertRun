//
//  DessertRunApp.swift
//  DessertRun
//
//  Created by Claude on 2025/3/24.
//

import SwiftUI
import UIKit
import CoreLocation
import UserNotifications

/// 应用主入口
@main
struct DessertRunApp: App {
    /// 共享的应用状态
    @StateObject private var appState = AppState.shared
    
    /// 认证服务
    @StateObject private var authService = AuthService.shared
    
    /// 注册AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    /// 场景管理
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // 配置应用
        setupApp()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isFirstLaunch {
                    // 首次启动显示引导页
                    OnboardingView()
                } else if appState.showLoginView {
                    // 显示登录页面（token过期或需要登录时）
                    LoginView()
                        .transition(.opacity)
                } else {
                    // 直接显示主界面
                    MainTabView()
                        .transition(.opacity)
                }
            }
            .environmentObject(appState)
            .environmentObject(authService)
            .onAppear {
                DRInfo("应用启动完成")
                
                // 检查用户登录状态
                if let token = UserDefaults.standard.string(forKey: Config.UserData.tokenKey) {
                    DRInfo("找到已存储token: \(token.prefix(10))...")
                } else {
                    DRInfo("未找到token，用户未登录")
                }
                
                // 在这里可以添加任何应用启动后需要执行的逻辑
                // AuthService的初始化已经处理了token验证和用户状态加载
            }
        }
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // 处理应用状态变化
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            print("应用进入前台")
            // 更新登录状态
            appState.updateLoginStatus()
            
        case .background:
            print("应用进入后台")
            // MVP版本不再需要处理运动会话的暂停
            
        case .inactive:
            print("应用处于非活动状态")
            // 通常在应用切换时触发，可能不需要特殊处理
            
        @unknown default:
            print("未知的应用状态")
        }
    }
    
    private func setupApp() {
        // 设置应用的基本配置
        DRInfo("应用初始化开始")
        
        #if DEBUG
        // 仅在DEBUG模式下启用
        if CommandLine.arguments.contains("--reset") {
            DRInfo("检测到重置参数，清除所有用户数据")
            AuthService.shared.resetAppToInitialState()
        }
        #endif
        
        // 配置全局UI外观
        UINavigationBar.appearance().tintColor = UIColor(Color("Primary"))
        
        // 打印应用配置信息
        DRInfo("应用配置: API地址: \(Config.API.baseURL)")
        DRInfo("应用初始化完成")
    }
}
