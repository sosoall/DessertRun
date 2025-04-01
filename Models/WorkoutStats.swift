//
//  WorkoutStats.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import Foundation

/// 运动统计周期
enum StatsPeriod {
    case day
    case week
    case month
    case year
}

/// 单日运动记录
struct DailyWorkoutRecord: Identifiable {
    /// 唯一标识
    let id: UUID = UUID()
    
    /// 日期
    let date: Date
    
    /// 总运动时间（分钟）
    let totalMinutes: Int
    
    /// 总运动距离（米）
    let totalDistance: Double
    
    /// 消耗的总卡路里
    let totalCalories: Double
    
    /// 获得的甜品券数量
    let vouchersEarned: Int
    
    /// 运动会话ID列表
    let workoutSessionIds: [UUID]
    
    /// 初始化
    init(date: Date, totalMinutes: Int, totalDistance: Double, totalCalories: Double, vouchersEarned: Int, workoutSessionIds: [UUID]) {
        self.date = date
        self.totalMinutes = totalMinutes
        self.totalDistance = totalDistance
        self.totalCalories = totalCalories
        self.vouchersEarned = vouchersEarned
        self.workoutSessionIds = workoutSessionIds
    }
    
    /// 获取格式化的日期字符串
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
    
    /// 获取格式化的运动时间
    var formattedTime: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    /// 获取格式化的距离
    var formattedDistance: String {
        if totalDistance >= 1000 {
            return String(format: "%.2f千米", totalDistance / 1000)
        } else {
            return String(format: "%.0f米", totalDistance)
        }
    }
    
    /// 获取格式化的卡路里
    var formattedCalories: String {
        return String(format: "%.0f卡路里", totalCalories)
    }
}

/// 运动统计管理器
class WorkoutStatsManager {
    /// 获取指定日期的运动记录
    /// - Parameter date: 日期
    /// - Returns: 运动记录（如果有）
    func getRecordForDate(_ date: Date) -> DailyWorkoutRecord? {
        // 在实际实现中，这里应该从数据库或API获取数据
        // 目前返回模拟数据
        return getSampleDailyRecord(for: date)
    }
    
    /// 获取指定月份的所有记录
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份
    /// - Returns: 记录数组
    func getRecordsForMonth(year: Int, month: Int) -> [DailyWorkoutRecord] {
        // 在实际实现中，这里应该从数据库或API获取数据
        // 目前返回模拟数据
        return getSampleMonthlyRecords(year: year, month: month)
    }
    
    /// 计算指定周期的累计统计数据
    /// - Parameter period: 统计周期
    /// - Returns: 汇总统计数据
    func calculateStats(for period: StatsPeriod) -> (totalMinutes: Int, totalDistance: Double, totalCalories: Double, vouchersEarned: Int) {
        // 在实际实现中，这里应该从数据库或API获取数据，然后计算统计值
        // 目前返回模拟数据
        switch period {
        case .day:
            return (45, 2500, 280, 1)
        case .week:
            return (210, 12000, 1300, 5)
        case .month:
            return (840, 48000, 5200, 18)
        case .year:
            return (9600, 560000, 62400, 210)
        }
    }
    
    // MARK: - 样例数据生成
    
    /// 获取某日的样例记录
    /// - Parameter date: 日期
    /// - Returns: 样例记录
    private func getSampleDailyRecord(for date: Date) -> DailyWorkoutRecord? {
        // 这里简单模拟一下，随机返回一些记录
        let dayOfMonth = Calendar.current.component(.day, from: date)
        
        // 对于当前月的一些日期返回记录，其他返回nil
        if dayOfMonth % 3 == 0 {
            return DailyWorkoutRecord(
                date: date,
                totalMinutes: Int.random(in: 20...60),
                totalDistance: Double.random(in: 1000...3000),
                totalCalories: Double.random(in: 150...350),
                vouchersEarned: Int.random(in: 0...2),
                workoutSessionIds: [UUID()]
            )
        }
        
        return nil
    }
    
    /// 获取月度样例记录
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份
    /// - Returns: 记录数组
    private func getSampleMonthlyRecords(year: Int, month: Int) -> [DailyWorkoutRecord] {
        var records: [DailyWorkoutRecord] = []
        
        // 创建日历用于日期计算
        let calendar = Calendar.current
        
        // 创建指定年月的日期组件
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        
        guard let startDate = calendar.date(from: dateComponents) else { return [] }
        
        // 计算该月有多少天
        let range = calendar.range(of: .day, in: .month, for: startDate)!
        let numDays = range.count
        
        // 为该月的一些日期生成记录
        for day in 1...numDays {
            dateComponents.day = day
            
            if let date = calendar.date(from: dateComponents) {
                // 随机决定是否有记录（约40%的天数有记录）
                if Int.random(in: 1...10) <= 4 {
                    let record = DailyWorkoutRecord(
                        date: date,
                        totalMinutes: Int.random(in: 20...60),
                        totalDistance: Double.random(in: 1000...3000),
                        totalCalories: Double.random(in: 150...350),
                        vouchersEarned: Int.random(in: 0...2),
                        workoutSessionIds: [UUID()]
                    )
                    records.append(record)
                }
            }
        }
        
        return records
    }
} 