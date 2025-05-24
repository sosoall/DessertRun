import Foundation

/// 挑战报名状态枚举
enum EnrollmentStatus: String, Codable {
    case ongoing = "ongoing"     // 进行中
    case completed = "completed" // 已完成 
    case failed = "failed"       // 失败
}

/// 用于处理Go后端的sql.NullString类型
struct NullString: Codable {
    let String: String?
    let Valid: Bool
    
    var value: String? {
        return Valid ? String : nil
    }
}

/// 用于处理Go后端的sql.NullTime类型
struct NullTime: Codable {
    let Time: String
    let Valid: Bool
    
    var date: Date? {
        guard Valid else { return nil }
        
        // 解析ISO8601格式的时间字符串
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: Time)
    }
}

/// 挑战报名记录模型
struct ChallengeEnrollment: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let activityId: String
    
    // 报名信息
    let enrolledAt: Date
    let deadline: Date
    
    // 进度追踪
    let completedCheckins: Int
    let redeemedVouchers: NullString?
    
    // 状态
    let status: EnrollmentStatus
    let completedAt: NullTime?
    
    // 奖励核销时间
    let redeemedAt: NullTime?
    
    // 创建和更新时间
    let createdAt: Date
    let updatedAt: Date
    
    // CodingKeys
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case activityId = "activity_id"
        case enrolledAt = "enrolled_at"
        case deadline
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
        return redeemedAt?.Valid == true
    }
    
    /// 获取完成时间
    var completionDate: Date? {
        return completedAt?.date
    }
    
    /// 获取奖励领取时间
    var redemptionDate: Date? {
        return redeemedAt?.date
    }
    
    /// 已核销的优惠券数组
    var voucherArray: [String] {
        if let vouchers = redeemedVouchers?.value, !vouchers.isEmpty {
            return vouchers.components(separatedBy: ",")
        }
        return []
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
    
    enum CodingKeys: String, CodingKey {
        case enrollment
        case challenge
        case completionPercent = "completion_percent"
        case remainingDays = "remaining_days"
    }
}