//
//  StatsComponents.swift
//  DessertRun
//
//  Created by Claude on 2025/4/11.
//

import SwiftUI

/// 自定义月份选择器
struct MonthPicker: View {
    @Binding var selectedDate: Date
    var onMonthChange: () -> Void
    
    // 当前月份和年份
    private var month: Int {
        Calendar.current.component(.month, from: selectedDate)
    }
    
    private var year: Int {
        Calendar.current.component(.year, from: selectedDate)
    }
    
    // 格式化月份显示
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        return formatter.string(from: selectedDate)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // 前一个月按钮
            Button(action: {
                moveMonth(by: -1)
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "61462C"))
            }
            
            // 月份显示，点击弹出月份选择器
            Button(action: {
                // 在这里可以弹出年月选择器
                showMonthYearPicker()
            }) {
                Text(monthYearString)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "61462C"))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(hex: "F5F5F5"))
                    )
            }
            
            // 后一个月按钮
            Button(action: {
                moveMonth(by: 1)
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "61462C"))
            }
        }
        .padding(.vertical, 10)
    }
    
    // 移动月份
    private func moveMonth(by amount: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: amount, to: selectedDate) {
            selectedDate = newDate
            onMonthChange()
        }
    }
    
    // 显示月份年份选择器
    private func showMonthYearPicker() {
        // 实际应用中需要弹出一个月份选择器
        // 这里简化为返回当前月份
        selectedDate = Date()
        onMonthChange()
    }
}

/// 月度统计卡片组件
struct MonthlyStatsCard: View {
    var stats: WorkoutStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本月运动概览")
                .font(.headline)
                .foregroundColor(Color(hex: "61462C"))
            
            HStack(spacing: 20) {
                // 运动时长
                VStack(alignment: .leading) {
                    Text("\(stats.totalMinutes / 60)小时\(stats.totalMinutes % 60)分钟")
                        .font(.title3)
                        .bold()
                    Text("运动时长")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 运动距离
                VStack(alignment: .leading) {
                    Text(String(format: "%.1f", stats.totalDistance / 1000))
                        .font(.title3)
                        .bold()
                    Text("公里")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 美食券
                VStack(alignment: .leading) {
                    Text("\(stats.vouchersEarned)")
                        .font(.title3)
                        .bold()
                    Text("获得美食券")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

/// 状态筛选器组件
struct StatusFilter: View {
    @Binding var selectedStatus: String
    var options: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        selectedStatus = option
                    }) {
                        Text(option)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedStatus == option
                                    ? Color(hex: "FE2D55")
                                    : Color.gray.opacity(0.2)
                            )
                            .foregroundColor(
                                selectedStatus == option
                                    ? .white
                                    : .black
                            )
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// 日期辅助函数
struct DateHelper {
    // 获取指定月份的天数
    static func daysInMonth(for date: Date) -> Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.count
    }
    
    // 获取指定月份的第一天是星期几
    static func firstDayOfMonth(for date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        let firstDay = calendar.date(from: components)!
        return calendar.component(.weekday, from: firstDay) - 1 // 0是周日，6是周六
    }
    
    // 格式化日期
    static func formatDate(_ date: Date, format: String = "MM-dd") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    // 判断日期是否是今天
    static func isToday(_ date: Date) -> Bool {
        return Calendar.current.isDateInToday(date)
    }
    
    // 判断日期是否是未来
    static func isFuture(_ date: Date) -> Bool {
        return date > Date()
    }
    
    // 获取某月的第N天的日期
    static func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return Calendar.current.date(from: components)!
    }
}

// 模拟数据提供者
class MockDataProvider {
    // 生成模拟的运动记录
    static func generateMockWorkoutRecords(for date: Date, count: Int = 15) -> [CalendarWorkoutRecord] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let daysInMonth = DateHelper.daysInMonth(for: date)
        
        var records: [CalendarWorkoutRecord] = []
        
        // 确保生成的记录数量不超过当月天数
        let actualCount = min(count, daysInMonth)
        
        // 随机选择几天标记为有运动记录
        var workoutDays = Set<Int>()
        while workoutDays.count < actualCount {
            let day = Int.random(in: 1...daysInMonth)
            workoutDays.insert(day)
        }
        
        // 生成运动记录
        for day in workoutDays {
            // 随机选择一个甜品
            let dessert = DessertData.getSampleDesserts().randomElement()!
            
            // 随机选择一个运动类型
            let exerciseType = ExerciseTypeData.getSampleExerciseTypes().randomElement()!
            
            // 随机生成运动时长（15-60分钟）
            let duration = Int.random(in: 15...60) * 60 // 转换为秒
            
            // 随机生成完成百分比
            let completion = Double.random(in: 60...100)
            
            // 创建运动会话记录
            let session = WorkoutSession(targetDessert: dessert, exerciseType: exerciseType)
            session.totalElapsedSeconds = duration
            // 使用运动类型的卡路里消耗率计算
            session.burnedCalories = Double(duration / 60) * exerciseType.caloriesPerMinute
            
            // 如果是跑步，添加距离
            if exerciseType.requiresGPS {
                session.distanceInMeters = Double.random(in: 1000...5000) // 1-5公里
            }
            
            // 创建日期
            let recordDate = DateHelper.date(year: year, month: month, day: day)
            
            // 创建运动记录
            let record = CalendarWorkoutRecord(
                date: recordDate,
                sessions: [session],
                dessertVouchers: [
                    DessertVoucher(
                        dessert: dessert,
                        completionPercentage: completion,
                        workoutSessionId: session.id
                    )
                ]
            )
            
            records.append(record)
        }
        
        // 按日期排序
        return records.sorted { $0.date < $1.date }
    }
    
    // 生成模拟甜品券
    static func generateMockVouchers(for date: Date, count: Int = 10) -> [DessertRun.DessertVoucher] {
        let calendar = Calendar.current
        let currentDate = Date()
        let desserts = DessertData.getSampleDesserts()
        
        var vouchers: [DessertRun.DessertVoucher] = []
        
        for _ in 0..<count {
            // 随机选择一个甜品
            let dessert = desserts.randomElement()!
            
            // 随机生成完成百分比
            let completion = Double.random(in: 60...100)
            
            // 随机生成状态
            let statusRandom = Int.random(in: 0...10)
            let status: VoucherStatus
            
            if statusRandom < 7 {
                status = .active
            } else if statusRandom < 9 {
                status = .used
            } else {
                status = .expired
            }
            
            // 创建甜品券，在构造函数中expiryDate自动设置为30天后
            var voucher = DessertVoucher(
                dessert: dessert,
                completionPercentage: completion,
                workoutSessionId: UUID()
            )
            
            // 设置状态
            voucher.status = status
            
            // 如果是已使用状态，设置使用日期
            if status == .used {
                voucher.usedDate = Calendar.current.date(byAdding: .day, value: -Int.random(in: 1...15), to: Date())
            }
            
            vouchers.append(voucher)
        }
        
        return vouchers
    }
    
    // 生成月度统计数据
    static func generateMockMonthlyStats(for date: Date) -> WorkoutStats {
        let records = generateMockWorkoutRecords(for: date)
        
        // 计算总时长
        let totalSeconds = records.flatMap { $0.sessions }.reduce(0) { $0 + $1.totalElapsedSeconds }
        let totalMinutes = totalSeconds / 60
        
        // 计算总距离
        let totalDistance = records.flatMap { $0.sessions }.reduce(0.0) { $0 + $1.distanceInMeters }
        
        // 获取甜品券数量
        let vouchersEarned = records.flatMap { $0.dessertVouchers }.count
        
        return WorkoutStats(
            totalMinutes: totalMinutes,
            totalDistance: totalDistance,
            vouchersEarned: vouchersEarned
        )
    }
}

#Preview {
    VStack {
        MonthPicker(selectedDate: .constant(Date()), onMonthChange: {})
            .padding()
            .background(Color.white)
        
        MonthlyStatsCard(stats: MockDataProvider.generateMockMonthlyStats(for: Date()))
            .padding()
        
        StatusFilter(selectedStatus: .constant("全部"), options: ["全部", "有效", "已使用", "已过期"])
            .padding()
            .background(Color.white)
    }
} 