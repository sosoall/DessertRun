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

// MARK: - 新的后端接口适配模型

/// 报名挑战详情（新后端格式）
struct EnrollmentWithChallengeDetail: Codable, Equatable {
    let enrollment: ChallengeEnrollmentDetail
    let challenge: ChallengeDetail
    let voucherList: VoucherList
    let progress: ProgressInfo
    
    enum CodingKeys: String, CodingKey {
        case enrollment
        case challenge
        case voucherList = "voucher_list"
        case progress
    }
    
    static func == (lhs: EnrollmentWithChallengeDetail, rhs: EnrollmentWithChallengeDetail) -> Bool {
        return lhs.enrollment.id == rhs.enrollment.id
    }
}

/// 挑战报名详情（新格式）
struct ChallengeEnrollmentDetail: Codable, Equatable {
    let id: String
    let userId: String
    let activityId: String
    let enrolledAt: Date
    let deadline: Date
    let completedCheckins: Int
    let status: String
    let completedAt: Date?
    let redeemedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case activityId = "activity_id"
        case enrolledAt = "enrolled_at"
        case deadline
        case completedCheckins = "completed_checkins"
        case status
        case completedAt = "completed_at"
        case redeemedAt = "redeemed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    static func == (lhs: ChallengeEnrollmentDetail, rhs: ChallengeEnrollmentDetail) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// 转换为EnrollmentStatus枚举
    var enrollmentStatus: EnrollmentStatus {
        return EnrollmentStatus(rawValue: status) ?? .ongoing
    }
    
    /// 判断是否已完成
    var isCompleted: Bool {
        return status == "completed"
    }
    
    /// 获取完成时间
    var completionDate: Date? {
        return completedAt
    }
    
    /// 获取奖励领取时间
    var redemptionDate: Date? {
        return redeemedAt
    }
}

/// 挑战详情（新格式）
struct ChallengeDetail: Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let requiredCheckins: Int
    let rewardType: String
    let rewardDescription: String
    let activityType: String
    let startDate: Date
    let endDate: Date
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case requiredCheckins = "required_checkins"
        case rewardType = "reward_type"
        case rewardDescription = "reward_description"
        case activityType = "activity_type"
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
    }
    
    static func == (lhs: ChallengeDetail, rhs: ChallengeDetail) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// 格式化活动时间
    var formattedDuration: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    /// 格式化奖励
    var formattedReward: String {
        return rewardDescription
    }
}

/// 美食券列表
struct VoucherList: Codable, Equatable {
    let vouchers: [ChallengeVoucherDetail]
    
    static func == (lhs: VoucherList, rhs: VoucherList) -> Bool {
        return lhs.vouchers == rhs.vouchers
    }
}

/// 挑战美食券详情
struct ChallengeVoucherDetail: Codable, Equatable {
    let id: String
    let userId: String
    let challengeEnrollmentId: String?
    let workoutRecordId: String?
    let dessertId: String?
    let dessertName: String
    let dessertIconURL: String
    let voucherImageURL: String
    let allowedCategoryIds: [String]
    let equivalentDessertCount: Double
    let caloriesValue: Double
    let status: String
    let activatedAt: Date?
    let createdAt: Date
    let expireAt: Date?
    let exerciseType: String
    let exerciseName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case challengeEnrollmentId = "challenge_enrollment_id"
        case workoutRecordId = "workout_record_id"
        case dessertId = "dessert_id"
        case dessertName = "dessert_name"
        case dessertIconURL = "dessert_icon_url"
        case voucherImageURL = "voucher_image_url"
        case allowedCategoryIds = "allowed_category_ids"
        case equivalentDessertCount = "equivalent_dessert_count"
        case caloriesValue = "calories_value"
        case status
        case activatedAt = "activated_at"
        case createdAt = "created_at"
        case expireAt = "expire_at"
        case exerciseType = "exercise_type"
        case exerciseName = "exercise_name"
    }
    
    static func == (lhs: ChallengeVoucherDetail, rhs: ChallengeVoucherDetail) -> Bool {
        return lhs.id == rhs.id
    }
}

/// 进度信息
struct ProgressInfo: Codable, Equatable {
    let completionPercent: Double
    let remainingDays: Int
    let isCompleted: Bool
    let canRedeem: Bool
    
    enum CodingKeys: String, CodingKey {
        case completionPercent = "completion_percent"
        case remainingDays = "remaining_days"
        case isCompleted = "is_completed"
        case canRedeem = "can_redeem"
    }
    
    static func == (lhs: ProgressInfo, rhs: ProgressInfo) -> Bool {
        return lhs.completionPercent == rhs.completionPercent &&
               lhs.remainingDays == rhs.remainingDays &&
               lhs.isCompleted == rhs.isCompleted &&
               lhs.canRedeem == rhs.canRedeem
    }
}

/// 分页信息
struct PaginationInfo: Codable {
    let page: Int
    let limit: Int
    let total: Int64
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case page
        case limit
        case total
        case totalPages = "total_pages"
    }
}

/// 已报名挑战响应（新格式）
struct EnrolledChallengesResponse: Codable {
    let code: Int
    let message: String
    let data: EnrolledChallengesData
}

/// 已报名挑战数据
struct EnrolledChallengesData: Codable {
    let challenges: [EnrollmentWithChallengeDetail]
    let pagination: PaginationInfo
}