import SwiftUI
import Combine

/// 运动视图模型，处理运动打卡相关的业务逻辑
class ExerciseViewModel: ObservableObject {
    // API服务实例
    private let apiService = APIService.shared
    
    // 应用状态
    private let appState: AppState
    
    // 取消订阅令牌
    private var cancellables = Set<AnyCancellable>()
    
    // 初始化
    init(appState: AppState) {
        self.appState = appState
    }
    
    /// 创建运动打卡记录
    /// - Parameter params: 打卡记录参数
    /// - Returns: 结果发布者
    func createWorkoutRecord(params: [String: Any]) -> AnyPublisher<(WorkoutRecord?, DessertVoucher?), APIServiceError> {
        return apiService.createWorkoutRecord(params: params)
            .handleEvents(receiveOutput: { responseData in
                // 解包响应，提取运动记录和美食券
                let (workoutRecord, dessertVoucher) = responseData
                
                // 处理打卡成功，使用后端返回的数据
                if let record = workoutRecord {
                    DRInfo("[ExerciseViewModel] 发送打卡成功通知 WorkoutCompleted")
                    
                    if let voucher = dessertVoucher {
                        // 同时有运动记录和美食券，打包发送通知
                        let notificationData: [String: Any] = [
                            "record": record,
                            "voucher": voucher
                        ]
                        NotificationCenter.default.post(
                            name: NSNotification.Name("WorkoutCompleted"),
                            object: notificationData
                        )
                        DRInfo("[ExerciseViewModel] 发送包含美食券的打卡成功通知")
                    } else {
                        // 仅有运动记录，发送原始通知
                        NotificationCenter.default.post(
                            name: NSNotification.Name("WorkoutCompleted"),
                            object: record
                        )
                        DRInfo("[ExerciseViewModel] 发送不含美食券的打卡成功通知")
                    }
                } else {
                    DRWarning("[ExerciseViewModel] 后端返回的记录数据为空，跳过发送通知")
                }
            })
            .eraseToAnyPublisher()
    }
    
    /// 批量获取运动记录
    func getWorkoutRecordsByIds(recordIds: String) -> AnyPublisher<[WorkoutRecord], APIServiceError> {
        return apiService.getWorkoutRecordsByIds(recordIds: recordIds)
    }
    
    /// 激活美食券（创建运动记录）
    func activateVoucher(voucherId: String, workoutData: [String: Any]) -> AnyPublisher<(WorkoutRecord, DessertVoucher, ChallengeProgressInfo?), APIServiceError> {
        return apiService.activateVoucher(voucherId: voucherId, workoutData: workoutData)
    }
} 