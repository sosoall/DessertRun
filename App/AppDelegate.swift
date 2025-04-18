import UIKit
import BackgroundTasks
import UserNotifications
import CoreLocation

class AppDelegate: NSObject, UIApplicationDelegate {
    // 屏幕方向控制
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("应用已启动")
        
        // 注册后台任务
        registerBackgroundTasks()
        
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
        
        // 如果有活动的运动会话，安排后台任务
        if let session = AppState.shared.activeWorkoutSession, session.state == .active {
            scheduleBackgroundWorkoutTask()
        }
    }
    
    // 注册后台任务
    private func registerBackgroundTasks() {
        // 注册一个处理任务，用于后台运动数据处理
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.dessertrun.workoutprocessing",
            using: nil
        ) { task in
            self.handleWorkoutProcessingTask(task: task as! BGProcessingTask)
        }
        
        print("后台任务已注册")
    }
    
    // 安排后台运动任务
    private func scheduleBackgroundWorkoutTask() {
        let request = BGProcessingTaskRequest(identifier: "com.dessertrun.workoutprocessing")
        
        // 设置网络不是必须的
        request.requiresNetworkConnectivity = false
        
        // 设置电源不是必须的
        request.requiresExternalPower = false
        
        // 尽早执行
        request.earliestBeginDate = Date(timeIntervalSinceNow: 1)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("后台运动处理任务已安排")
        } catch {
            print("无法安排后台任务: \(error)")
        }
    }
    
    // 处理后台运动任务
    private func handleWorkoutProcessingTask(task: BGProcessingTask) {
        print("正在后台执行运动数据处理任务")
        
        // 创建一个进度指示器来更新任务进度
        let progress = Progress(totalUnitCount: 100)
        
        // 设置任务过期处理程序
        task.expirationHandler = {
            print("后台任务即将过期，正在保存数据")
            progress.cancel()
        }
        
        // 创建一个数据处理操作
        let operation = BlockOperation {
            // 更新运动数据（如果存在活动的运动会话）
            if let session = AppState.shared.activeWorkoutSession, session.state == .active {
                session.updateWorkoutData()
                print("已在后台更新运动数据")
            }
            
            // 更新进度
            progress.completedUnitCount = 100
        }
        
        // 操作完成时通知任务系统
        operation.completionBlock = {
            // 完成任务
            task.setTaskCompleted(success: !progress.isCancelled)
            
            // 重新安排下一个后台任务
            self.scheduleBackgroundWorkoutTask()
        }
        
        // 开始操作
        OperationQueue.main.addOperation(operation)
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