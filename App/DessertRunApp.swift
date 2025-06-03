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
    
    /// 显示用户信息设置页面
    @State private var showUserInfoSetup = false
    
    /// 是否已添加观察者
    @State private var observerAdded = false
    
    /// 显示启动页
    @State private var showSplash = true
    
    init() {
        // 设置全局设置，避免UI和输入系统警告
        // 这些设置不会修复根本问题，但会减少不必要的警告日志
        #if DEBUG
        // 仅在调试模式下执行，避免影响生产性能
        UserDefaults.standard.set(false, forKey: "UIInputViewInsetNoncontentRegionNeedsReverseSwizzle")
        UserDefaults.standard.set(false, forKey: "UIViewShowAlignmentRects")
        #endif
        
        // 配置应用
        setupApp()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .onAppear {
                            // 2.0 秒后自动隐藏
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation {
                                    showSplash = false
                                }
                            }
                        }
                } else if appState.isResettingApp {
                    ProgressView("重置应用中...")
                        .onAppear {
                            // 应用重置逻辑
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                appState.isResettingApp = false
                            }
                        }
                } else if showUserInfoSetup {
                    UserInfoSetupView()
                        .environmentObject(appState)
                } else if appState.showLoginView && !appState.isLoggedIn {
                    LoginView()
                        .environmentObject(appState)
                } else {
                    MainTabView()
                        .environmentObject(appState)
                }
            }
            .onAppear {
                // 应用首次启动检查登录状态
                appState.updateLoginStatus()
                
                // 设置监听，处理需要登录的情况
                setupNotificationObservers()
                
                // 打印应用配置信息
                DRInfo("应用配置: API地址: \(Config.API.baseURL)")
                
                // 注册监听新用户通知
                if !observerAdded {
                    NotificationCenter.default.addObserver(forName: .userRegistered, object: nil, queue: .main) { [self] _ in
                        showUserInfoSetup = true // 注册后显示完整的信息设置流程
                    }
                    observerAdded = true
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
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
    
    /// 设置通知监听器
    private func setupNotificationObservers() {
        // 监听退出登录通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("LogoutNotification"),
            object: nil,
            queue: .main
        ) { [self] _ in
            // 重置应用状态
            DRInfo("收到退出登录通知，重置应用状态")
            // 使用AppState的方法处理退出登录
            appState.handleLogout()
        }
        
        // 监听新用户完成资料填写后的通知
        // ... existing code ...
    }
}
