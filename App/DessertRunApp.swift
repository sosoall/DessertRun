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
    
    /// 注册AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    /// 场景管理
    @Environment(\.scenePhase) private var scenePhase
    
    /// 登录模态显示控制
    @State private var showLoginView = false
    
    init() {
        // 强制屏幕旋转为竖屏
        AppDelegate.lockOrientation(.portrait)
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .environmentObject(appState)
                    // 强制竖屏显示
                    .onAppear {
                        AppDelegate.lockOrientation(.portrait)
                        
                        // 如果未登录，显示登录视图
                        if !appState.isLoggedIn {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showLoginView = true
                            }
                        }
                    }
            }
            .fullScreenCover(isPresented: $showLoginView) {
                LoginView()
                    .environmentObject(appState)
            }
        }
        .onChange(of: scenePhase) { (oldPhase, newPhase) in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // 处理应用状态变化
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            print("应用进入前台")
            // MVP版本不再需要处理运动会话的恢复
            
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
