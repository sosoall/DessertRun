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
        // 使用更健壮的日期解析方法
        func parseISODate(_ dateString: String) -> Date? {
            // 1. 首先尝试使用完整ISO8601格式（带毫秒和时区）
            let fullFormatter = ISO8601DateFormatter()
            fullFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fullFormatter.date(from: dateString) {
                return date
            }
            
            // 2. 尝试不带毫秒的ISO8601格式
            let simpleFormatter = ISO8601DateFormatter()
            simpleFormatter.formatOptions = [.withInternetDateTime]
            if let date = simpleFormatter.date(from: dateString) {
                return date
            }
            
            // 3. 尝试手动解析常见的日期格式
            let dateFormats = [
                "yyyy-MM-dd'T'HH:mm:ssZ",         // 基本ISO8601，带时区
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",     // 带毫秒和时区
                "yyyy-MM-dd'T'HH:mm:ssZZZZZ",     // 带扩展时区格式(+08:00)
                "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ", // 带毫秒和扩展时区
                "yyyy-MM-dd HH:mm:ss",            // 简单格式，无T分隔符和时区
                "yyyy-MM-dd"                      // 仅日期
            ]
            
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")  // 使用标准区域设置
            
            for format in dateFormats {
                formatter.dateFormat = format
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }
            
            // 所有尝试都失败
            DRError("[BatchVoucherResponse] 所有日期格式解析尝试失败: \(dateString)")
            return nil
        }
        
        // 解析创建日期
        let createdAtDate = parseISODate(createdAt) ?? Date()
        
        // 解析过期日期
        var expireAtDate: Date? = nil
        if let expireAt = expireAt {
            expireAtDate = parseISODate(expireAt)
        }
        
        // 解析核销日期
        var redeemedAtDate: Date? = nil
        if let redeemedAt = redeemedAt {
            redeemedAtDate = parseISODate(redeemedAt)
        }
        
        // 记录解析成功的创建日期，便于调试
        DRInfo("[BatchVoucherResponse] 解析美食券日期成功: \(createdAt) -> \(createdAtDate)")
        
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