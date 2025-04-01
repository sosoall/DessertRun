//
//  DessertVoucher.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import Foundation
import SwiftUI

/// 甜品券状态
enum VoucherStatus: String, Codable {
    case active = "有效"   // 有效
    case used = "已使用"   // 已使用
    case expired = "已过期" // 已过期
}

/// 甜品券
struct DessertVoucher: Identifiable, Codable {
    /// 唯一标识
    let id: UUID
    
    /// 相关甜品
    let dessert: DessertItem
    
    /// 获得日期
    let earnedDate: Date
    
    /// 过期日期（默认30天后过期）
    let expiryDate: Date
    
    /// 完成百分比 (0-100)
    let completionPercentage: Double
    
    /// 券状态
    var status: VoucherStatus
    
    /// 使用日期
    var usedDate: Date?
    
    /// 相关运动会话ID
    let workoutSessionId: UUID
    
    /// 初始化
    init(dessert: DessertItem, completionPercentage: Double, workoutSessionId: UUID) {
        self.id = UUID()
        self.dessert = dessert
        self.earnedDate = Date()
        self.expiryDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        self.completionPercentage = min(max(completionPercentage, 0), 100)
        self.status = .active
        self.workoutSessionId = workoutSessionId
    }
    
    /// 是否为部分完成券
    var isPartial: Bool {
        return completionPercentage < 100
    }
    
    /// 是否已过期
    var isExpired: Bool {
        return Date() > expiryDate
    }
    
    /// 获取剩余有效天数
    var remainingDays: Int {
        guard status == .active else { return 0 }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expiryDate)
        return max(components.day ?? 0, 0)
    }
    
    /// 使用此券
    mutating func redeem() {
        status = .used
        usedDate = Date()
    }
    
    /// 检查过期状态并更新
    mutating func checkExpiration() {
        if status == .active && isExpired {
            status = .expired
        }
    }
}

/// 甜品券样例数据
struct DessertVoucherData {
    /// 获取示例甜品券
    static func getSampleVouchers() -> [DessertVoucher] {
        let desserts = DessertData.getSampleDesserts()
        
        var vouchers: [DessertVoucher] = []
        
        // 添加几个样例券
        if let dessert1 = desserts.first {
            let voucher1 = DessertVoucher(
                dessert: dessert1,
                completionPercentage: 100,
                workoutSessionId: UUID()
            )
            vouchers.append(voucher1)
        }
        
        if desserts.count > 1 {
            let voucher2 = DessertVoucher(
                dessert: desserts[1],
                completionPercentage: 75,
                workoutSessionId: UUID()
            )
            vouchers.append(voucher2)
        }
        
        if desserts.count > 2 {
            var voucher3 = DessertVoucher(
                dessert: desserts[2],
                completionPercentage: 100,
                workoutSessionId: UUID()
            )
            voucher3.redeem()
            vouchers.append(voucher3)
        }
        
        if desserts.count > 3 {
            var voucher4 = DessertVoucher(
                dessert: desserts[3],
                completionPercentage: 100,
                workoutSessionId: UUID()
            )
            // 设置为已过期
            voucher4.status = .expired
            vouchers.append(voucher4)
        }
        
        return vouchers
    }
} 