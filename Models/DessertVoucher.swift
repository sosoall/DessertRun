//
//  DessertVoucher.swift
//  DessertRun
//
//  Created by Claude on 2025/4/8.
//

import Foundation

/// 美食券状态
enum VoucherStatus: String, Codable {
    case active = "active"     // 有效
    case used = "used"         // 已使用
    case expired = "expired"   // 已过期
}

/// 美食券模型
struct DessertVoucher: Identifiable, Codable, Equatable {
    /// 唯一标识符
    let id: String
    
    /// 用户ID
    let userId: String
    
    /// 甜品ID
    let dessertId: String
    
    /// 甜品名称
    let dessertName: String
    
    /// 等效美食数量
    let equivalentDessertCount: Double
    
    /// 卡路里价值
    let caloriesValue: Double
    
    /// 关联的打卡记录ID（可选）
    let workoutRecordId: String?
    
    /// 券状态
    let status: String
    
    /// 创建时间
    let createdAt: Date
    
    /// 更新时间
    let updatedAt: Date?
    
    /// 过期时间
    let expireAt: Date?
    
    /// 图片ID
    let imageId: String?
    
    /// 图片URL（API直接返回的URL）
    let imageURL: String?
    
    /// 运动类型
    let exerciseType: String?
    
    /// 运动名称
    let exerciseName: String?
    
    /// 获取格式化的卡路里价值
    var formattedCalories: String {
        return String(format: "%.0f卡路里", caloriesValue)
    }
    
    /// 获取格式化的等效美食数量
    var formattedEquivalentCount: String {
        if equivalentDessertCount >= 1 {
            return String(format: "%.1f个", equivalentDessertCount)
        } else {
            return String(format: "%.1f个", equivalentDessertCount)
        }
    }
    
    /// 获取券状态
    var voucherStatus: VoucherStatus {
        if let status = VoucherStatus(rawValue: status) {
            return status
        }
        
        return .active
    }
    
    /// 检查券是否可用
    var isUsable: Bool {
        return voucherStatus == .active
    }
    
    /// 获取剩余有效天数
    var remainingDays: Int {
        guard let expireDate = expireAt else {
            // 如果没有设置过期时间，假设有效期为30天
            let calendar = Calendar.current
            guard let defaultExpireDate = calendar.date(byAdding: .day, value: 30, to: createdAt) else {
                return 0
            }
            
            let days = calendar.dateComponents([.day], from: Date(), to: defaultExpireDate).day ?? 0
            return max(0, days)
        }
        
        // 计算当前时间与过期时间的天数差
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: expireDate).day ?? 0
        
        // 如果已过期，返回0
        return max(0, days)
    }
    
    /// 实现Equatable协议的静态==方法
    static func == (lhs: DessertVoucher, rhs: DessertVoucher) -> Bool {
        return lhs.id == rhs.id && 
               lhs.status == rhs.status &&
               lhs.createdAt == rhs.createdAt
    }
    
    /// 空的美食券实例，用于初始化
    static var empty: DessertVoucher {
        return DessertVoucher(
            id: UUID().uuidString,
            userId: "",
            dessertId: "",
            dessertName: "未知美食",
            equivalentDessertCount: 0,
            caloriesValue: 0,
            workoutRecordId: nil,
            status: VoucherStatus.active.rawValue,
            createdAt: Date(),
            updatedAt: nil,
            expireAt: nil,
            imageId: nil,
            imageURL: nil,
            exerciseType: nil,
            exerciseName: nil
        )
    }
    
    /// 创建示例券（用于预览）
    static func createSample() -> DessertVoucher {
        let now = Date()
        let calendar = Calendar.current
        let expireDate = calendar.date(byAdding: .day, value: 14, to: now)!
        
        return DessertVoucher(
            id: UUID().uuidString,
            userId: UUID().uuidString,
            dessertId: UUID().uuidString,
            dessertName: "巧克力蛋糕",
            equivalentDessertCount: 1.5,
            caloriesValue: 450,
            workoutRecordId: UUID().uuidString,
            status: VoucherStatus.active.rawValue,
            createdAt: now,
            updatedAt: nil,
            expireAt: expireDate,
            imageId: nil,
            imageURL: "https://example.com/cake.jpg",
            exerciseType: "running",
            exerciseName: "跑步"
        )
    }
    
    /// 定义CodingKeys枚举来处理字段名称映射
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case dessertId = "dessert_id"
        case dessertName = "dessert_name"
        case equivalentDessertCount = "equivalent_dessert_count"
        case caloriesValue = "calories_value"
        case workoutRecordId = "workout_record_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case expireAt = "expire_at"
        case imageId = "image_id"
        case imageURL = "image_url"
        case exerciseType = "exercise_type"
        case exerciseName = "exercise_name"
    }
} 