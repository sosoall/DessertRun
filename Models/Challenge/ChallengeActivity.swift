import Foundation

/// 挑战活动类型枚举
enum ActivityType: String, Codable {
    case free = "free"
    case paid = "paid"
}

/// 奖励类型枚举
enum RewardType: String, Codable {
    case dessertBox = "dessert_box" // 美食盲盒
    case coupon = "coupon"         // 优惠券
    case badge = "badge"           // 徽章
    case stars = "stars"           // 星星
}

/// 挑战活动模型
struct ChallengeActivity: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let requirement: String
    let activityType: ActivityType
    
    // 活动时间
    let startDate: Date
    let endDate: Date
    
    // 活动要求
    let requiredCheckins: Int
    let requiredExerciseTypeId: String?
    let foodRestrictionType: String
    let requiredFoodCategoryIds: [String]?
    let requiredFoodIds: [String]?
    let requiredDifferentFoodTypes: Bool
    let requiredDifferentExerciseTypes: Bool
    
    // 排序
    let displayOrder: Int
    
    // 价格信息（付费活动）
    let price: Int?
    let vipOnly: Bool
    
    // 奖励信息
    let rewardType: RewardType
    let rewardAmount: Int
    let rewardDescription: String
    
    // 活动状态
    let isActive: Bool
    
    // 是否为新手活动
    let isForBeginner: Bool
    
    // 创建和更新时间
    let createdAt: Date
    let updatedAt: Date
    
    // 图片URL
    var imageURL: String?
    var bannerURL: String?
    
    // CodingKeys
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case requirement
        case activityType = "activity_type"
        case startDate = "start_date"
        case endDate = "end_date"
        case requiredCheckins = "required_checkins"
        case requiredExerciseTypeId = "required_exercise_type_id"
        case foodRestrictionType = "food_restriction_type"
        case requiredFoodCategoryIds = "required_food_category_ids"
        case requiredFoodIds = "required_food_ids"
        case requiredDifferentFoodTypes = "required_different_food_types"
        case requiredDifferentExerciseTypes = "required_different_exercise_types"
        case displayOrder = "display_order"
        case price
        case vipOnly = "vip_only"
        case rewardType = "reward_type"
        case rewardAmount = "reward_amount"
        case rewardDescription = "reward_description"
        case isActive = "is_active"
        case isForBeginner = "is_for_beginner"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case imageURL = "image_url"
        case bannerURL = "banner_url"
    }
    
    // Equatable实现
    static func == (lhs: ChallengeActivity, rhs: ChallengeActivity) -> Bool {
        return lhs.id == rhs.id
    }
    
    // 计算属性
    
    /// 格式化的活动持续时间
    var formattedDuration: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
    
    /// 格式化的奖励信息
    var formattedReward: String {
        switch rewardType {
        case .dessertBox:
            return "美食盲盒 x \(rewardAmount)"
        case .coupon:
            return "优惠券 x \(rewardAmount)"
        case .badge:
            return "徽章 x \(rewardAmount)"
        case .stars:
            return "星星 x \(rewardAmount)"
        }
    }
    
    /// 活动状态文本
    var statusText: String {
        if !isActive {
            return "未上线"
        }
        
        let now = Date()
        if now < startDate {
            return "即将开始"
        } else if now > endDate {
            return "已结束"
        } else {
            return "进行中"
        }
    }
    
    /// 判断活动是否进行中
    var isInProgress: Bool {
        let now = Date()
        return isActive && now >= startDate && now <= endDate
    }
    
    /// 判断活动是否免费
    var isFree: Bool {
        return activityType == .free
    }
    
    /// 获取活动剩余天数
    var remainingDays: Int {
        let now = Date()
        if now > endDate {
            return 0
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: now, to: endDate)
        return components.day ?? 0
    }
} 