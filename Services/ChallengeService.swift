import Foundation
import Combine

/// 挑战活动API相关端点
struct ChallengeEndpoints {
    static let base = "/api/v1/challenges"
    static let list = base
    static let detail = base + "/"  // 需要附加ID
    static let enroll = base + "/"  // 需要附加ID + "/enroll"
    static let enrollments = base + "/enrolled"
    static let currentProgress = base + "/current/progress"
    static let progress = base + "/"  // 需要附加ID + "/progress" 
    static let redeem = base + "/"    // 需要附加ID + "/redeem"
    static let checkin = base + "/checkin"
}

/// 打卡请求参数
struct CheckinRequest: Codable {
    let checkinType: String
    let checkinId: String
    let exerciseTypeId: String?
    let dessertId: String?
    
    enum CodingKeys: String, CodingKey {
        case checkinType = "checkin_type"
        case checkinId = "checkin_id"
        case exerciseTypeId = "exercise_type_id"
        case dessertId = "dessert_id"
    }
}

/// 挑战服务，负责挑战活动相关API
class ChallengeService {
    static let shared = ChallengeService()
    private let networkManager = NetworkManager.shared
    
    private init() {}
    
    /// 获取挑战活动列表
    /// - Parameter completion: 完成回调，返回结果包含挑战列表或错误
    func getChallenges() -> AnyPublisher<[ChallengeActivity], NetworkError> {
        return networkManager.request(
            endpoint: ChallengeEndpoints.list,
            method: .get,
            requiresAuth: true
        )
    }
    
    /// 获取单个挑战活动详情
    /// - Parameters:
    ///   - id: 挑战ID
    ///   - completion: 完成回调，返回结果包含挑战详情或错误
    func getChallengeDetail(id: String) -> AnyPublisher<ChallengeActivity, NetworkError> {
        return networkManager.request(
            endpoint: ChallengeEndpoints.detail + id,
            method: .get,
            requiresAuth: true,
            responseType: ChallengeActivity.self
        )
    }
    
    /// 报名参加挑战
    /// - Parameters:
    ///   - id: 挑战ID
    ///   - completion: 完成回调，返回结果包含报名详情或错误
    func enrollChallenge(id: String) -> AnyPublisher<EmptyResponseData, NetworkError> {
        return networkManager.request(
            endpoint: ChallengeEndpoints.enroll + id + "/enroll",
            method: .post,
            requiresAuth: true
        )
    }
    
    /// 获取用户已报名的挑战列表
    /// - Parameter completion: 完成回调，返回结果包含报名列表或错误
    func getEnrollments() -> AnyPublisher<[EnrollmentWithChallenge], NetworkError> {
        return networkManager.request(
            endpoint: ChallengeEndpoints.enrollments,
            method: .get,
            requiresAuth: true
        )
    }
    
    /// 获取当前进行中挑战的进度
    /// - Parameter completion: 完成回调，返回结果包含挑战进度或错误
    func getCurrentProgress() -> AnyPublisher<ChallengeProgressResponse, NetworkError> {
        return networkManager.request(
            endpoint: ChallengeEndpoints.currentProgress,
            method: .get,
            requiresAuth: true
        )
    }
    
    /// 获取指定挑战的进度
    /// - Parameters:
    ///   - id: 挑战ID
    ///   - completion: 完成回调，返回结果包含挑战进度或错误
    func getProgress(id: String) -> AnyPublisher<ChallengeProgressResponse, NetworkError> {
        return networkManager.request(
            endpoint: ChallengeEndpoints.progress + id + "/progress",
            method: .get,
            requiresAuth: true
        )
    }
    
    /// 领取挑战奖励
    /// - Parameters:
    ///   - id: 挑战ID
    ///   - completion: 完成回调，返回结果包含操作结果或错误
    func redeemReward(id: String) -> AnyPublisher<EmptyResponseData, NetworkError> {
        return networkManager.request(
            endpoint: ChallengeEndpoints.redeem + id + "/redeem",
            method: .post,
            requiresAuth: true
        )
    }
    
    /// 向挑战核销打卡
    /// - Parameters:
    ///   - checkinType: 打卡类型 "exercise"运动打卡或"dessert"甜品打卡
    ///   - checkinId: 打卡记录ID
    ///   - exerciseTypeId: 运动类型ID（运动打卡时必填）
    ///   - dessertId: 甜品ID（甜品打卡时必填）
    ///   - completion: 完成回调，返回结果包含操作结果或错误
    func submitCheckin(
        checkinType: String,
        checkinId: String,
        exerciseTypeId: String? = nil,
        dessertId: String? = nil
    ) -> AnyPublisher<EmptyResponseData, NetworkError> {
        let params: [String: Any] = [
            "checkin_type": checkinType,
            "checkin_id": checkinId,
            "exercise_type_id": exerciseTypeId as Any,
            "dessert_id": dessertId as Any
        ]
        
        return networkManager.request(
            endpoint: ChallengeEndpoints.checkin,
            method: .post,
            parameters: params,
            requiresAuth: true
        )
    }
} 