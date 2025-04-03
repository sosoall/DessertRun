//
//  NumberExtension.swift
//  DessertRun
//
//  Created by Claude on 2025/4/3.
//

import Foundation

// MARK: - 整数扩展
extension Int {
    /// 将整数转换为带有前导零的字符串
    /// - Parameter length: 总长度，如不足将添加前导零
    /// - Returns: 格式化后的字符串
    func paddedWithZero(length: Int) -> String {
        return String(format: "%0\(length)d", self)
    }
    
    /// 获取随机整数
    /// - Parameter max: 最大值（包含）
    /// - Returns: 随机整数
    static func random(max: Int) -> Int {
        return Int.random(in: 0...max)
    }
}

// MARK: - 浮点数扩展
extension Double {
    /// 将浮点数四舍五入到指定小数位
    /// - Parameter places: 小数位数
    /// - Returns: 四舍五入后的浮点数
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    /// 返回格式化的字符串，保留指定小数位
    /// - Parameter places: 小数位数
    /// - Returns: 格式化后的字符串
    func formatted(toPlaces places: Int) -> String {
        return String(format: "%.\(places)f", self)
    }
    
    /// 将公里转换为米
    var kilometersToMeters: Double {
        return self * 1000
    }
    
    /// 将米转换为公里
    var metersToKilometers: Double {
        return self / 1000
    }
    
    /// 将千卡转换为卡路里
    var kilocaloriesToCalories: Double {
        return self * 1000
    }
} 