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
        // 强制屏幕旋转为竖屏
        AppDelegate.lockOrientation(.portrait)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isFirstLaunch {
                    // 首次启动显示引导页
                    OnboardingView()
                } else {
                    // 直接显示主界面，跳过登录流程
                    MainTabView()
                        .transition(.opacity)
                }
            }
            .environmentObject(appState)
            .environmentObject(authService)
            .onAppear {
                AppDelegate.lockOrientation(.portrait)
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
}
