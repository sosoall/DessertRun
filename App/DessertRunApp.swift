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
                .background(Color.white) // 确保整个应用的背景是纯白色
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
            // 如果有活动的运动会话，恢复动画和UI更新
            if let session = appState.activeWorkoutSession, session.state == .active {
                session.resumeAnimations()
                print("恢复运动会话的UI更新和动画")
            }
            
        case .background:
            print("应用进入后台")
            // 如果有活动的运动会话，暂停动画但继续收集数据
            if let session = appState.activeWorkoutSession, session.state == .active {
                session.suspendAnimations()
                print("暂停运动会话的UI更新和动画，但保持数据收集")
            }
            
        case .inactive:
            print("应用处于非活动状态")
            // 通常在应用切换时触发，可能不需要特殊处理
            
        @unknown default:
            print("未知的应用状态")
        }
    }
}
