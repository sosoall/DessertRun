import Foundation

/// 挑战奖励状态枚举
enum RewardStatus: String, Codable {
    case pending = "pending"         // 待处理
    case processing = "processing"   // 处理中
    case completed = "completed"     // 已完成
    case failed = "failed"           // 失败
}

/// 挑战奖励模型
struct ChallengeReward: Identifiable, Codable {
    let id: String
    let enrollmentId: String
    let userId: String
    let activityId: String
    
    // 奖励信息
    let rewardType: RewardType
    let rewardAmount: Int
    let rewardData: [String: Any]?
    
    // 状态
    let status: RewardStatus
    let claimedAt: Date
    let completedAt: Date?
    
    // 物流信息（实物奖励）
    let shippingRequired: Bool
    let shippingInfo: [String: Any]?
    let trackingNumber: String?
    
    // 创建和更新时间
    let createdAt: Date
    let updatedAt: Date
    
    // CodingKeys
    enum CodingKeys: String, CodingKey {
        case id
        case enrollmentId = "enrollment_id"
        case userId = "user_id"
        case activityId = "activity_id"
        case rewardType = "reward_type"
        case rewardAmount = "reward_amount"
        case rewardData = "reward_data"
        case status
        case claimedAt = "claimed_at"
        case completedAt = "completed_at"
        case shippingRequired = "shipping_required"
        case shippingInfo = "shipping_info"
        case trackingNumber = "tracking_number"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // 由于JSON中的字典类型字段需要特殊处理，这里重写编解码方法
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        enrollmentId = try container.decode(String.self, forKey: .enrollmentId)
        userId = try container.decode(String.self, forKey: .userId)
        activityId = try container.decode(String.self, forKey: .activityId)
        rewardType = try container.decode(RewardType.self, forKey: .rewardType)
        rewardAmount = try container.decode(Int.self, forKey: .rewardAmount)
        
        // 尝试解码JSON对象
        if let rewardDataString = try? container.decode(String.self, forKey: .rewardData),
           let rewardDataData = rewardDataString.data(using: .utf8),
           let rewardDataDict = try? JSONSerialization.jsonObject(with: rewardDataData) as? [String: Any] {
            rewardData = rewardDataDict
        } else {
            rewardData = nil
        }
        
        status = try container.decode(RewardStatus.self, forKey: .status)
        claimedAt = try container.decode(Date.self, forKey: .claimedAt)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        shippingRequired = try container.decode(Bool.self, forKey: .shippingRequired)
        
        // 尝试解码物流信息的JSON对象
        if let shippingInfoString = try? container.decode(String.self, forKey: .shippingInfo),
           let shippingInfoData = shippingInfoString.data(using: .utf8),
           let shippingInfoDict = try? JSONSerialization.jsonObject(with: shippingInfoData) as? [String: Any] {
            shippingInfo = shippingInfoDict
        } else {
            shippingInfo = nil
        }
        
        trackingNumber = try container.decodeIfPresent(String.self, forKey: .trackingNumber)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    // 实现Encodable协议的encode方法
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(enrollmentId, forKey: .enrollmentId)
        try container.encode(userId, forKey: .userId)
        try container.encode(activityId, forKey: .activityId)
        try container.encode(rewardType, forKey: .rewardType)
        try container.encode(rewardAmount, forKey: .rewardAmount)
        
        // 特殊处理rewardData
        if let rewardData = rewardData, 
           let rewardDataData = try? JSONSerialization.data(withJSONObject: rewardData),
           let rewardDataString = String(data: rewardDataData, encoding: .utf8) {
            try container.encode(rewardDataString, forKey: .rewardData)
        } else {
            try container.encodeNil(forKey: .rewardData)
        }
        
        try container.encode(status, forKey: .status)
        try container.encode(claimedAt, forKey: .claimedAt)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encode(shippingRequired, forKey: .shippingRequired)
        
        // 特殊处理shippingInfo
        if let shippingInfo = shippingInfo,
           let shippingInfoData = try? JSONSerialization.data(withJSONObject: shippingInfo),
           let shippingInfoString = String(data: shippingInfoData, encoding: .utf8) {
            try container.encode(shippingInfoString, forKey: .shippingInfo)
        } else {
            try container.encodeNil(forKey: .shippingInfo)
        }
        
        try container.encodeIfPresent(trackingNumber, forKey: .trackingNumber)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
    
    // 计算属性
    
    /// 格式化的奖励状态文本
    var statusText: String {
        switch status {
        case .pending:
            return "待处理"
        case .processing:
            return "处理中"
        case .completed:
            return "已完成"
        case .failed:
            return "处理失败"
        }
    }
    
    /// 格式化的奖励类型文本
    var typeText: String {
        switch rewardType {
        case .dessertBox:
            return "美食盲盒"
        case .coupon:
            return "优惠券"
        case .badge:
            return "徽章"
        case .stars:
            return "星星"
        }
    }
} 