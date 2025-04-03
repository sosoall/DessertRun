//
//  DateExtension.swift
//  DessertRun
//
//  Created by Claude on 2025/4/3.
//

import Foundation

// MARK: - 日期扩展

extension Date {
    /// 格式化日期为指定格式字符串
    /// - Parameter format: 日期格式，默认为"yyyy-MM-dd"
    /// - Returns: 格式化后的日期字符串
    func formatted(format: String = "yyyy-MM-dd") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    /// 获取日期的年份
    var year: Int {
        return Calendar.current.component(.year, from: self)
    }
    
    /// 获取日期的月份
    var month: Int {
        return Calendar.current.component(.month, from: self)
    }
    
    /// 获取日期的日
    var day: Int {
        return Calendar.current.component(.day, from: self)
    }
    
    /// 获取与另一个日期相差的天数
    /// - Parameter date: 比较的日期
    /// - Returns: 相差的天数
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    
    /// 添加指定天数
    /// - Parameter days: 天数
    /// - Returns: 添加天数后的日期
    func adding(days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
} 