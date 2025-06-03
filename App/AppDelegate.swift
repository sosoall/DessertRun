import UIKit
import BackgroundTasks
import UserNotifications
import CoreData

class AppDelegate: NSObject, UIApplicationDelegate {

    var window: UIWindow?
    
    // 屏幕方向控制
    static var orientationLock = UIInterfaceOrientationMask.portrait

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // 设置CoreGraphics数值错误忽略
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        // 配置日志过滤，禁用美食券和图片缓存的调试日志
        configureLogging()
        
        // 设置摇一摇菜单（仅Debug模式生效）
        application.setupShakeGestureMenu()
        
        // 初始化网络缓存
        setupNetworkCache()
        
        // 初始化图片缓存
        _ = ImageCacheService.shared
        
        // 开始预加载美食数据和图片
        preloadData()
        
        // 应用启动时主动请求必要的权限
        requestPermissions()
        
        DRInfo("[AppDelegate] 应用已启动")
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // 屏幕方向控制
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        DRInfo("[AppDelegate] 应用进入后台")
        // MVP版本不需要处理运动会话
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation creates and returns a container, having loaded the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "DessertRun")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

// MARK: - 私有辅助方法
extension AppDelegate {
    /// 配置日志过滤器
    private func configureLogging() {
        // 默认禁用美食券和图片缓存的调试日志，减少日志输出
        LogModuleFilter.enableFoodVoucherDebugLogs = false
        LogModuleFilter.enableImageCacheDebugLogs = false
        DRInfo("[AppDelegate] 已配置日志过滤器: 美食券调试日志:\(LogModuleFilter.enableFoodVoucherDebugLogs), 图片缓存调试日志:\(LogModuleFilter.enableImageCacheDebugLogs)")
    }
    
    /// 设置网络缓存
    private func setupNetworkCache() {
        // 设置URLCache
        let cacheSizeMemory = 50 * 1024 * 1024 // 50MB内存缓存
        let cacheSizeDisk = 200 * 1024 * 1024   // 200MB磁盘缓存
        let cache = URLCache(memoryCapacity: cacheSizeMemory, diskCapacity: cacheSizeDisk, diskPath: "URLCache")
        URLCache.shared = cache
        
        DRInfo("[AppDelegate] 设置网络缓存: 内存\(cacheSizeMemory/1024/1024)MB, 磁盘\(cacheSizeDisk/1024/1024)MB")
    }
    
    /// 预加载数据
    private func preloadData() {
        // 异步预加载美食数据，但不启动图片预加载
        DispatchQueue.global(qos: .utility).async {
            DRInfo("[AppDelegate] 开始预加载应用数据")
            
            // 仅在首次启动时预加载数据样本，避免图片预加载导致的问题
            DessertData.getAllDesserts { _ in 
                DRInfo("[AppDelegate] 美食数据预加载完成")
            }
        }
    }
    
    /// 请求应用所需的权限
    private func requestPermissions() {
        // 请求通知权限
        Task {
            try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        }
        
        DRInfo("[AppDelegate] 已请求应用所需的基本权限")
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