import UIKit
import BackgroundTasks
import UserNotifications
import CoreLocation

class AppDelegate: NSObject, UIApplicationDelegate {
    // 屏幕方向控制
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // 设置CoreGraphics数值错误忽略
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        print("应用已启动")
        
        // 应用启动时主动请求必要的权限
        requestPermissions()
        
        return true
    }
    
    // 屏幕方向控制
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("应用进入后台")
        // MVP版本不需要处理运动会话
    }
    
    /// 请求应用所需的权限
    private func requestPermissions() {
        // 请求位置权限
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        
        // 请求通知权限
        Task {
            try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
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