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
    }
}

// 用于锁定屏幕方向的AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // 应用启动时锁定为竖屏
        AppDelegate.lockOrientation(.portrait)
        
        // 应用启动时主动请求必要的权限
        requestPermissions()
        
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    /// 请求应用所需的权限
    private func requestPermissions() {
        // 请求位置权限
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        
        // 请求通知权限
        Task {
            _ = await UNUserNotificationCenter.requestPermission()
        }
        
        print("已请求应用所需的基本权限")
    }
    
    /// 设置屏幕方向锁定的辅助方法
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        // 设置支持的方向
        AppDelegate.orientationLock = orientation
        
        // 尝试使用现代API更新屏幕方向
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            // 使用现代API请求几何更新
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            
            // 通知所有视图控制器更新其支持的方向
            if let window = windowScene.windows.first {
                window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            }
        }
    }
}
