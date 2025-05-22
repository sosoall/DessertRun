import SwiftUI
import Combine

/// 运动流程协调器，管理打卡完成后的导航流程
class WorkoutFlowCoordinator: ObservableObject {
    // 单例
    static let shared = WorkoutFlowCoordinator()
    
    // 状态变量
    @Published var latestWorkoutRecord: WorkoutRecord? = nil
    @Published var latestDessertVoucher: DessertVoucher? = nil
    @Published var showCompletionView: Bool = false
    @Published var shouldNavigateToFoodCheckIn: Bool = false
    
    // 用于存储取消订阅
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // 监听打卡成功通知
        setupNotificationObservers()
    }
    
    // 设置通知观察者
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: NSNotification.Name("WorkoutCompleted"))
            .sink { [weak self] notification in
                // 从通知中获取运动记录
                if let record = notification.object as? WorkoutRecord {
                    self?.handleWorkoutCompletion(record: record)
                } else if let data = notification.object as? [String: Any],
                          let record = data["record"] as? WorkoutRecord,
                          let voucher = data["voucher"] as? DessertVoucher {
                    self?.handleWorkoutCompletionWithVoucher(record: record, voucher: voucher)
                }
            }
            .store(in: &cancellables)
    }
    
    // 处理运动完成 (旧方法，为兼容性保留)
    func handleWorkoutCompletion(record: WorkoutRecord) {
        DispatchQueue.main.async {
            // 设置最新记录
            self.latestWorkoutRecord = record
            self.latestDessertVoucher = nil // 清空可能存在的美食券
            
            // 设置应用状态
            AppState.shared.justCompletedWorkout = true
            
            // 显示完成视图
            self.showCompletionView = true
            
            // 重置导航标志
            self.shouldNavigateToFoodCheckIn = false
            
            DRInfo("[WorkoutFlowCoordinator] 显示打卡完成页面，记录ID: \(record.id)")
        }
    }
    
    // 处理运动完成，并包含美食券信息
    func handleWorkoutCompletionWithVoucher(record: WorkoutRecord, voucher: DessertVoucher) {
        DispatchQueue.main.async {
            // 设置最新记录和美食券
            self.latestWorkoutRecord = record
            self.latestDessertVoucher = voucher
            
            // 设置应用状态
            AppState.shared.justCompletedWorkout = true
            
            // 显示完成视图
            self.showCompletionView = true
            
            // 重置导航标志
            self.shouldNavigateToFoodCheckIn = false
            
            DRInfo("[WorkoutFlowCoordinator] 显示打卡完成页面，记录ID: \(record.id)，美食券ID: \(voucher.id)")
        }
    }
    
    // 关闭完成视图并导航到美食券页面
    func completeAndNavigateToFoodCheckIn() {
        DispatchQueue.main.async {
            self.showCompletionView = false
            
            // 延迟导航以等待动画完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // 导航到美食券页面
                self.shouldNavigateToFoodCheckIn = true
                
                // 设置选中的标签页为美食券页面
                AppState.shared.selectedTabIndex = 1
                
                DRInfo("[WorkoutFlowCoordinator] 导航到美食券页面")
            }
        }
    }
    
    // 手动触发完成流程（用于测试）
    func triggerCompletionFlow(record: WorkoutRecord) {
        handleWorkoutCompletion(record: record)
    }
    
    // 手动触发完成流程（用于测试）,包含美食券
    func triggerCompletionFlow(record: WorkoutRecord, voucher: DessertVoucher) {
        handleWorkoutCompletionWithVoucher(record: record, voucher: voucher)
    }
    
    // 重置状态
    func reset() {
        latestWorkoutRecord = nil
        latestDessertVoucher = nil
        showCompletionView = false
        shouldNavigateToFoodCheckIn = false
    }
} 