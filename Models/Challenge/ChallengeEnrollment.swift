import Foundation

/// 挑战报名状态枚举
enum EnrollmentStatus: String, Codable {
    case ongoing = "ongoing"     // 进行中
    case completed = "completed" // 已完成 
    case failed = "failed"       // 失败
}

/// 挑战报名记录模型
struct ChallengeEnrollment: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let activityId: String
    
    // 报名信息
    let enrolledAt: Date
    
    // 进度追踪
    let completedCheckins: Int
    let redeemedVouchers: [String]?
    
    // 状态
    let status: EnrollmentStatus
    let completedAt: Date?
    
    // 奖励核销时间
    let redeemedAt: Date?
    
    // 创建和更新时间
    let createdAt: Date
    let updatedAt: Date
    
    // CodingKeys
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case activityId = "activity_id"
        case enrolledAt = "enrolled_at"
        case completedCheckins = "completed_checkins"
        case redeemedVouchers = "redeemed_vouchers"
        case status
        case completedAt = "completed_at"
        case redeemedAt = "redeemed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Equatable实现
    static func == (lhs: ChallengeEnrollment, rhs: ChallengeEnrollment) -> Bool {
        return lhs.id == rhs.id
    }
    
    // 计算属性
    
    /// 进度百分比
    var progressPercent: Double {
        guard let activity = challenge else { return 0 }
        if activity.requiredCheckins <= 0 { return 0 }
        return min(Double(completedCheckins) / Double(activity.requiredCheckins), 1.0)
    }
    
    /// 进度格式化文本
    var progressText: String {
        guard let activity = challenge else { return "0/0" }
        return "\(completedCheckins)/\(activity.requiredCheckins)"
    }
    
    /// 活动详情引用（由外部设置）
    var challenge: ChallengeActivity?
    
    /// 判断是否已完成
    var isCompleted: Bool {
        return status == .completed
    }
    
    /// 判断是否已领取奖励
    var hasRedeemedReward: Bool {
        return redeemedAt != nil
    }
}

/// 包含挑战详情的报名记录
struct EnrollmentWithChallenge: Codable, Equatable {
    let enrollment: ChallengeEnrollment
    let challenge: ChallengeActivity
    
    static func == (lhs: EnrollmentWithChallenge, rhs: EnrollmentWithChallenge) -> Bool {
        return lhs.enrollment.id == rhs.enrollment.id && 
               lhs.challenge.id == rhs.challenge.id
    }
}

/// 挑战进度响应
struct ChallengeProgressResponse: Codable {
    let enrollment: ChallengeEnrollment
    let challenge: ChallengeActivity
    let completionPercent: Double
    let remainingDays: Int
} 