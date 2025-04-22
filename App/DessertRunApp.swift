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
    
    init() {
        // 强制屏幕旋转为竖屏
        AppDelegate.lockOrientation(.portrait)
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                // 移除整个应用的背景色设置
                // 强制竖屏显示
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
