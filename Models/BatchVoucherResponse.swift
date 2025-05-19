import Foundation

/// 批量美食券响应
struct BatchVoucherResponse: Codable {
    /// 总数
    let total: Int
    
    /// 页码
    let page: Int
    
    /// 每页数量
    let limit: Int
    
    /// 美食券列表
    let vouchers: [VoucherWithImages]
    
    /// 美食券图片URL映射 (image_id -> url)
    let images: [String: String]
    
    /// 甜品图标URL映射 (dessert_id -> url)
    let dessertIcons: [String: String]
    
    /// 记录图片URL映射 (record_id -> url)
    let recordImages: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case total, page, limit, vouchers, images
        case dessertIcons = "dessert_icons"
        case recordImages = "record_images"
    }
}

/// 带图片信息的美食券
struct VoucherWithImages: Codable, Identifiable {
    /// 美食券ID
    let id: String
    
    /// 用户ID
    let userID: String
    
    /// 运动记录ID
    let workoutRecordID: String?
    
    /// 甜品ID
    let dessertID: String
    
    /// 甜品名称
    let dessertName: String
    
    /// 图片ID
    let imageID: String?
    
    /// 等效甜品数量
    let equivalentDessertCount: Double
    
    /// 卡路里价值
    let caloriesValue: Double
    
    /// 状态: active, used, expired
    let status: String
    
    /// 核销时间
    let redeemedAt: String?
    
    /// 创建时间
    let createdAt: String
    
    /// 过期时间
    let expireAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case workoutRecordID = "workout_record_id"
        case dessertID = "dessert_id"
        case dessertName = "dessert_name"
        case imageID = "image_id"
        case equivalentDessertCount = "equivalent_dessert_count"
        case caloriesValue = "calories_value"
        case status
        case redeemedAt = "redeemed_at"
        case createdAt = "created_at"
        case expireAt = "expire_at"
    }
    
    /// 将VoucherWithImages转换为DessertVoucher
    func toDessertVoucher(imageURLs: [String: String], iconURLs: [String: String]) -> DessertVoucher {
        // 处理日期
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // 确保日期解析正确，如果解析失败则打印错误，不使用当前日期作为默认值
        var createdAtDate: Date
        if let date = dateFormatter.date(from: createdAt) {
            createdAtDate = date
        } else {
            DRError("[BatchVoucherResponse] 无法解析美食券创建日期: \(createdAt)")
            // 尝试使用没有毫秒的格式再解析一次
            let simpleFormatter = ISO8601DateFormatter()
            if let date = simpleFormatter.date(from: createdAt) {
                createdAtDate = date
            } else {
                // 如果仍然解析失败，打印详细错误并使用服务器当前时间
                DRError("[BatchVoucherResponse] 第二次尝试解析美食券创建日期失败: \(createdAt)，使用当前日期")
                createdAtDate = Date()
            }
        }
        
        var expireAtDate: Date? = nil
        if let expireAt = expireAt {
            if let date = dateFormatter.date(from: expireAt) {
                expireAtDate = date
            } else {
                DRError("[BatchVoucherResponse] 无法解析美食券过期日期: \(expireAt)")
                // 尝试使用没有毫秒的格式再解析一次
                let simpleFormatter = ISO8601DateFormatter()
                if let date = simpleFormatter.date(from: expireAt) {
                    expireAtDate = date
                }
            }
        }
        
        var redeemedAtDate: Date? = nil
        if let redeemedAt = redeemedAt {
            if let date = dateFormatter.date(from: redeemedAt) {
                redeemedAtDate = date
            } else {
                DRError("[BatchVoucherResponse] 无法解析美食券核销日期: \(redeemedAt)")
                // 尝试使用没有毫秒的格式再解析一次
                let simpleFormatter = ISO8601DateFormatter()
                if let date = simpleFormatter.date(from: redeemedAt) {
                    redeemedAtDate = date
                }
            }
        }
        
        // 记录日期解析结果，方便调试
        DRDebug("[BatchVoucherResponse] 解析美食券日期: 创建时间=\(createdAt) -> \(createdAtDate)")
        
        // 确定图片URL
        let imageURL: String
        if let imageID = imageID, let url = imageURLs[imageID] {
            imageURL = url
        } else if let iconURL = iconURLs[dessertID] {
            imageURL = iconURL
        } else {
            imageURL = ""
        }
        
        return DessertVoucher(
            id: id,
            userId: userID,
            dessertId: dessertID,
            dessertName: dessertName,
            equivalentDessertCount: equivalentDessertCount,
            caloriesValue: caloriesValue,
            workoutRecordId: workoutRecordID,
            status: status,
            createdAt: createdAtDate,
            updatedAt: nil,
            expireAt: expireAtDate,
            imageId: imageID,
            imageURL: imageURL
        )
    }
} 