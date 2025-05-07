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
struct DessertVoucher: Identifiable, Codable {
    /// 唯一标识符
    let id: UUID
    
    /// 用户ID
    let userID: UUID
    
    /// 关联的打卡记录ID（可选）
    let workoutRecordID: UUID?
    
    /// 美食ID
    let dessertID: UUID
    
    /// 美食名称
    let dessertName: String
    
    /// 等效美食数量
    let equivalentDessertCount: Double
    
    /// 卡路里价值
    let caloriesValue: Double
    
    /// 券状态
    let status: String
    
    /// 创建时间
    let createdAt: Date
    
    /// 过期时间
    let expireAt: Date?
    
    /// 核销时间
    let redeemedAt: Date?
    
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
        
        // 检查是否已过期
        if let expireDate = expireAt, expireDate < Date() {
            return .expired
        }
        
        return .active
    }
    
    /// 检查券是否可用
    var isUsable: Bool {
        return voucherStatus == .active && (expireAt == nil || expireAt! > Date())
    }
} 