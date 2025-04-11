//
//  WorkoutCalendarView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/11.
//

import SwiftUI

struct WorkoutCalendarView: View {
    // 状态变量
    @State private var selectedDate: Date = Date()
    @State private var monthlyRecords: [CalendarWorkoutRecord] = []
    @State private var monthlyStats: WorkoutStats?
    @State private var showingDetailView = false
    @State private var selectedDayRecord: CalendarWorkoutRecord?
    
    // 日历网格布局
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                // 月份选择器
                MonthPicker(selectedDate: $selectedDate, onMonthChange: {
                    loadMonthlyData()
                })
                .padding(.top, 10)
                
                // 月度统计卡片
                if let stats = monthlyStats {
                    MonthlyStatsCard(stats: stats)
                }
                
                // 日历视图
                VStack(spacing: 15) {
                    // 标题 - 周几
                    HStack {
                        ForEach(weekdays, id: \.self) { weekday in
                            Text(weekday)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: "61462C"))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.bottom, 5)
                    
                    // 日历网格
                    let daysInMonth = DateHelper.daysInMonth(for: selectedDate)
                    let firstWeekday = DateHelper.firstDayOfMonth(for: selectedDate)
                    let calendar = Calendar.current
                    let year = calendar.component(.year, from: selectedDate)
                    let month = calendar.component(.month, from: selectedDate)
                    
                    // 计算总行数
                    let totalDays = firstWeekday + daysInMonth
                    let rows = (totalDays + 6) / 7
                    
                    // 日历网格
                    VStack(spacing: 10) {
                        ForEach(0..<rows, id: \.self) { row in
                            HStack {
                                ForEach(0..<7, id: \.self) { column in
                                    let index = row * 7 + column
                                    let day = index - firstWeekday + 1
                                    
                                    if day > 0 && day <= daysInMonth {
                                        // 有效日期
                                        let date = DateHelper.date(year: year, month: month, day: day)
                                        let record = findRecord(for: date)
                                        
                                        DayCell(
                                            day: day,
                                            record: record,
                                            isToday: DateHelper.isToday(date),
                                            isFuture: DateHelper.isFuture(date)
                                        )
                                        .onTapGesture {
                                            if let record = record {
                                                selectedDayRecord = record
                                                showingDetailView = true
                                            }
                                        }
                                    } else {
                                        // 空白单元格
                                        Color.clear
                                            .frame(height: 50)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .padding(.bottom, 16)
        .sheet(isPresented: $showingDetailView) {
            if let record = selectedDayRecord {
                DayDetailView(record: record)
            }
        }
        .onAppear {
            loadMonthlyData()
        }
    }
    
    // 加载月度数据
    private func loadMonthlyData() {
        // 在实际应用中，这里应该从数据库或API获取数据
        // 这里使用模拟数据
        monthlyRecords = MockDataProvider.generateMockWorkoutRecords(for: selectedDate)
        monthlyStats = MockDataProvider.generateMockMonthlyStats(for: selectedDate)
    }
    
    // 查找指定日期的记录
    private func findRecord(for date: Date) -> CalendarWorkoutRecord? {
        return monthlyRecords.first {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }
}

// 日期单元格视图
struct DayCell: View {
    let day: Int
    let record: CalendarWorkoutRecord?
    let isToday: Bool
    let isFuture: Bool
    
    var body: some View {
        ZStack {
            // 背景
            Circle()
                .fill(backgroundColor)
                .frame(width: 40, height: 40)
            
            VStack(spacing: 2) {
                // 日期数字
                Text("\(day)")
                    .font(.system(size: 14, weight: isToday ? .bold : .medium))
                    .foregroundColor(textColor)
                
                // 甜品图标（如果有运动记录）
                if let record = record, let dessert = record.mainDessert {
                    if !dessert.imageName.isEmpty {
                        Image(dessert.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "FF5E62"))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 50)
    }
    
    // 背景颜色
    private var backgroundColor: Color {
        if isToday {
            return Color(hex: "FE2D55").opacity(0.2)
        } else if record != nil {
            return Color(hex: "FFA500").opacity(0.15)
        } else if isFuture {
            return Color.gray.opacity(0.05)
        } else {
            return Color.clear
        }
    }
    
    // 文字颜色
    private var textColor: Color {
        if isToday {
            return Color(hex: "FE2D55")
        } else if isFuture {
            return Color.gray.opacity(0.5)
        } else {
            return Color(hex: "61462C")
        }
    }
}

// 日详情视图
struct DayDetailView: View {
    let record: CalendarWorkoutRecord
    
    // 环境变量用于关闭sheet
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 日期标题
                    Text(formatDate(record.date))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "61462C"))
                    
                    // 运动摘要卡片
                    workoutSummaryCard
                    
                    // 运动会话详情
                    ForEach(record.sessions, id: \.id) { session in
                        sessionCard(session: session)
                    }
                    
                    // 甜品券
                    Text("获得的美食券")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "61462C"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    ForEach(record.dessertVouchers, id: \.id) { voucher in
                        voucherPreviewCard(voucher: voucher)
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
    
    // 运动摘要卡片
    private var workoutSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("运动摘要")
                .font(.headline)
                .foregroundColor(Color(hex: "61462C"))
            
            HStack(spacing: 20) {
                // 运动时长
                VStack(alignment: .leading) {
                    Text("\(record.totalDuration / 60)分钟")
                        .font(.title3)
                        .bold()
                    Text("运动时长")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 运动距离
                VStack(alignment: .leading) {
                    if record.totalDistance > 0 {
                        Text(String(format: "%.1f", record.totalDistance / 1000))
                            .font(.title3)
                            .bold()
                        Text("公里")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("室内运动")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // 消耗卡路里
                VStack(alignment: .leading) {
                    Text("\(Int(record.totalBurnedCalories))")
                        .font(.title3)
                        .bold()
                    Text("卡路里")
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
    
    // 运动会话卡片
    private func sessionCard(session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题栏
            HStack {
                // 运动类型图标
                ZStack {
                    Circle()
                        .fill(session.exerciseType.backgroundColor)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: session.exerciseType.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                // 运动类型名称
                Text(session.exerciseType.name)
                    .font(.headline)
                    .foregroundColor(Color(hex: "61462C"))
                
                Spacer()
                
                // 耗时
                Text("\(session.totalElapsedSeconds / 60)分钟")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 详细数据
            VStack(spacing: 15) {
                // 第一行：距离和卡路里
                HStack {
                    // 距离
                    if session.exerciseType.requiresGPS {
                        HStack(spacing: 5) {
                            Image(systemName: "map.fill")
                                .foregroundColor(Color(hex: "34C759"))
                            
                            Text("\(String(format: "%.2f", session.distanceInMeters / 1000))公里")
                                .font(.subheadline)
                        }
                    } else {
                        HStack(spacing: 5) {
                            Image(systemName: "repeat")
                                .foregroundColor(Color(hex: "34C759"))
                            
                            Text("室内运动")
                                .font(.subheadline)
                        }
                    }
                    
                    Spacer()
                    
                    // 卡路里
                    HStack(spacing: 5) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(Color(hex: "FF3B30"))
                        
                        Text("\(Int(session.burnedCalories))卡路里")
                            .font(.subheadline)
                    }
                }
                
                // 第二行：完成情况
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "5856D6"))
                    
                    Text("完成目标：\(Int(min(session.completionPercentage, 100)))%")
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // 美食券预览卡片
    private func voucherPreviewCard(voucher: DessertVoucher) -> some View {
        HStack {
            // 左侧：美食图片
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "FF5E62").opacity(0.8),
                                Color(hex: "FF9966").opacity(0.9)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                // 美食图片
                if !voucher.dessert.imageName.isEmpty {
                    Image(voucher.dessert.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                } else {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
            }
            
            // 中间：美食名称和状态
            VStack(alignment: .leading, spacing: 4) {
                Text(voucher.dessert.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    if voucher.isPartial {
                        Text("\(Int(voucher.completionPercentage))%")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "FF5E62"))
                            .cornerRadius(4)
                    }
                    
                    Text(voucher.status.rawValue)
                        .font(.caption)
                        .foregroundColor(statusColor(for: voucher.status))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor(for: voucher.status).opacity(0.2))
                        .cornerRadius(4)
                    
                    Text("有效期: \(DateHelper.formatDate(voucher.expiryDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // 状态颜色
    private func statusColor(for status: VoucherStatus) -> Color {
        switch status {
        case .active:
            return Color.green
        case .used:
            return Color.gray
        case .expired:
            return Color.red
        }
    }
}


#Preview {
    WorkoutCalendarView()
} 