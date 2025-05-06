import Foundation

// MARK: - 钱包信息
struct UserWallet: Codable {
    let userID: String
    let stars: Int
    let totalEarned: Int
    let totalSpent: Int
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case stars
        case totalEarned = "total_earned"
        case totalSpent = "total_spent"
        case updatedAt = "updated_at"
    }
}

// MARK: - 交易记录
struct Transaction: Identifiable, Codable {
    let id: String
    let userID: String
    let amount: Int
    let balance: Int
    let type: String
    let description: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case amount
        case balance
        case type
        case description
        case createdAt = "created_at"
    }
}

// MARK: - VIP信息
struct VIPInfo: Codable {
    let isVIP: Bool
    let userLevel: Int
    let remainingDays: Int?
    let expireDate: String?
    
    enum CodingKeys: String, CodingKey {
        case isVIP = "is_vip"
        case userLevel = "user_level"
        case remainingDays = "remaining_days"
        case expireDate = "expire_date"
    }
}

// MARK: - VIP套餐
struct VIPPackage: Identifiable, Codable {
    let id: String
    let name: String
    let durationDays: Int
    let price: Float
    let rewardStars: Int
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case durationDays = "duration_days"
        case price
        case rewardStars = "reward_stars"
        case description
    }
}

// MARK: - API响应包装类
struct WalletResponse: Codable {
    let code: Int
    let message: String
    let data: UserWallet?
}

struct TransactionsResponse: Codable {
    let code: Int
    let message: String
    let data: TransactionsListResponse?
}

struct TransactionsListResponse: Codable {
    let total: Int
    let transactions: [Transaction]
}

struct VIPInfoResponse: Codable {
    let code: Int
    let message: String
    let data: VIPInfo?
}

struct VIPPackagesResponse: Codable {
    let code: Int
    let message: String
    let data: [VIPPackage]?
}

struct VIPPurchaseResponse: Codable {
    let code: Int
    let message: String
    let data: VIPPurchaseResult?
}

struct VIPPurchaseResult: Codable {
    let success: Bool
    let message: String
    let vipExpireDate: String
    let rewardStars: Int
    let currentStars: Int
    
    enum CodingKeys: String, CodingKey {
        case success
        case message
        case vipExpireDate = "vip_expire_date"
        case rewardStars = "reward_stars"
        case currentStars = "current_stars"
    }
}

// 星币交易类型
enum TransactionType: String, Codable {
    case recharge = "recharge"         // 充值
    case reward = "reward"             // 奖励
    case refund = "refund"             // 退款
    case adminAdd = "admin_add"        // 管理员添加
    case systemAdd = "system_add"      // 系统添加
    case workoutAdd = "workout_add"    // 运动奖励
    case challengeAdd = "challenge_add" // 挑战奖励
    
    case consume = "consume"           // 消费
    case vipPurchase = "vip_purchase"  // VIP购买
    case giftSend = "gift_send"        // 赠送他人
    case adminDeduct = "admin_deduct"  // 管理员扣除
    case expire = "expire"             // 过期
    
    var displayName: String {
        switch self {
        case .recharge:
            return "充值"
        case .reward:
            return "奖励"
        case .refund:
            return "退款"
        case .adminAdd:
            return "管理员添加"
        case .systemAdd:
            return "系统添加"
        case .workoutAdd:
            return "运动奖励"
        case .challengeAdd:
            return "挑战奖励"
        case .consume:
            return "消费"
        case .vipPurchase:
            return "VIP购买"
        case .giftSend:
            return "赠送他人"
        case .adminDeduct:
            return "管理员扣除"
        case .expire:
            return "过期"
        }
    }
    
    var isIncome: Bool {
        switch self {
        case .recharge, .reward, .refund, .adminAdd, .systemAdd, .workoutAdd, .challengeAdd:
            return true
        case .consume, .vipPurchase, .giftSend, .adminDeduct, .expire:
            return false
        }
    }
} 