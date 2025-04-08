//
//  DessertRunApp.swift
//  DessertRun
//
//  Created by Claude on 2025/3/24.
//

import SwiftUI
import UIKit

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
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    /// 设置屏幕方向锁定的辅助方法
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        // 直接设置方向锁定
        AppDelegate.orientationLock = orientation
        
        // 强制当前屏幕为竖屏 - iOS 16兼容方式
        // 设置首选方向
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        
        // 使用场景API更新方向
        if #available(iOS 16.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
                
                if let window = windowScene.windows.first {
                    window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
                }
            }
        } else {
            // iOS 16以下版本，使用传统方式锁定方向
            // 这种方式在某些情况下可能不如iOS 16+的API有效
            // 但对于大部分情况来说足够用了
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
}
