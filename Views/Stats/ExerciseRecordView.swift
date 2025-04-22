import SwiftUI

/// 运动记录标签页
struct ExerciseRecordView: View {
    @ObservedObject var viewModel: StatsViewModel
    @State private var selectedTab: StatTab = .month
    @State private var selectedMonth: Date = Date()
    @State private var selectedWeek: Date = Date()
    
    enum StatTab: String, CaseIterable, Identifiable {
        case month = "月"
        case week = "周"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("运动记录")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // 日期选择器（月份或周）
                    if selectedTab == .month {
                        HStack(spacing: 4) {
                            Button(action: {
                                selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                                viewModel.setMonth(selectedMonth)
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.gray)
                            }
                            
                            Text(formatDate(selectedMonth, format: "yyyy年MM月"))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Button(action: {
                                selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                                viewModel.setMonth(selectedMonth)
                            }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    } else {
                        HStack(spacing: 4) {
                            Button(action: {
                                selectedWeek = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: selectedWeek) ?? selectedWeek
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.gray)
                            }
                            
                            Text(formatWeekRange(selectedWeek))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Button(action: {
                                selectedWeek = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: selectedWeek) ?? selectedWeek
                            }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // 切换Tab
                Picker("查看模式", selection: $selectedTab) {
                    ForEach(StatTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // 根据选择的Tab显示不同内容
                if selectedTab == .month {
                    monthCalendarView
                } else {
                    weekChartView
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGray6))
    }
    
    // 月视图日历
    private var monthCalendarView: some View {
        VStack(spacing: 16) {
            // 月份日历
            CalendarGridView(dateItems: generateMonthCalendarItems())
                .padding(.horizontal)
            
            // 日历颜色图例
            calendarLegendView
            
            // 月度汇总
            monthlySummaryView
                .padding(.horizontal)
                .padding(.top, 8)
        }
    }
    
    // 日历图例视图
    private var calendarLegendView: some View {
        HStack(spacing: 20) {
            // 有打卡但未达成目标
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(UIColor.systemGray5))
                    .frame(width: 14, height: 14)
                
                Text("未达成目标")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // 达成目标
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 14, height: 14)
                
                Text("已达成目标")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }
    
    // 月度汇总
    private var monthlySummaryView: some View {
        HStack(spacing: 16) {
            // 消耗热量
            VStack(alignment: .center, spacing: 8) {
                Text("本月消耗")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("\(Int(viewModel.monthlyBurnedCalories))卡")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.green)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemGray5))
            .cornerRadius(12)
            
            // 目标热量
            VStack(alignment: .center, spacing: 8) {
                Text("美食目标")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text("\(Int(viewModel.monthlyConsumedCalories))卡")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.orange)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemGray5))
            .cornerRadius(12)
        }
    }
    
    // 周视图柱状图
    private var weekChartView: some View {
        VStack(spacing: 12) {
            // 周热量图表
            WeeklyCalorieChart(dataPoints: generateWeekChartData(for: selectedWeek))
                .frame(height: 250)
                .padding(.horizontal)
            
            // 图例
            weeklyChartLegendView
            
            // 周度汇总
            weeklySummaryView
                .padding(.horizontal)
                .padding(.top, 8)
        }
    }
    
    // 周度图表图例
    private var weeklyChartLegendView: some View {
        HStack(spacing: 24) {
            // 消耗热量图例
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green.opacity(0.7))
                    .frame(width: 14, height: 14)
                
                Text("消耗热量")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // 运动目标图例
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.orange.opacity(0.7))
                    .frame(width: 10, height: 10)
                
                Text("运动目标")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // 达成目标图例
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 14, height: 14)
                
                Text("达成目标")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGray6).opacity(0.7))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    // 周度汇总
    private var weeklySummaryView: some View {
        VStack(spacing: 16) {
            // 本周目标达成天数
            HStack {
                Text("本周达成运动目标")
                    .font(.callout)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("\(viewModel.weeklyDeficitDays)/7天")
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 6)
                        .frame(height: 12)
                        .foregroundColor(Color(UIColor.systemGray5))
                    
                    // 填充部分
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.green.opacity(0.7), .green]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(viewModel.weeklyDeficitDays) / 7, height: 12)
                }
            }
            .frame(height: 12)
            
            // 热量总计
            HStack(spacing: 16) {
                // 美食目标
                VStack(alignment: .leading, spacing: 4) {
                    Text("美食目标")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(Int(viewModel.weeklyConsumedCalories))卡")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // 消耗总计
                VStack(alignment: .trailing, spacing: 4) {
                    Text("消耗总计")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(Int(viewModel.weeklyBurnedCalories))卡")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
    }
    
    // MARK: - 日历网格视图
    private struct CalendarGridView: View {
        let dateItems: [CalendarDateItem]
        
        // 每周天数
        private let daysInWeek = 7
        
        // 计算总行数
        private var totalRows: Int {
            (dateItems.count + daysInWeek - 1) / daysInWeek
        }
        
        // 星期标签
        private let weekdayLabels = ["日", "一", "二", "三", "四", "五", "六"]
        
        var body: some View {
            VStack(spacing: 8) {
                // 星期标题行
                HStack {
                    ForEach(weekdayLabels, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // 日期网格
                VStack(spacing: 4) {
                    ForEach(0..<totalRows, id: \.self) { row in
                        HStack(spacing: 2) {
                            ForEach(0..<daysInWeek, id: \.self) { col in
                                let index = row * daysInWeek + col
                                if index < dateItems.count {
                                    CalendarDateCell(item: dateItems[index])
                                        .frame(maxWidth: .infinity)
                                } else {
                                    // 空白占位
                                    Color.clear
                                        .frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
        }
    }
    
    // 日历单元格
    private struct CalendarDateCell: View {
        let item: CalendarDateItem
        
        var body: some View {
            VStack(spacing: 2) {
                // 日期
                dayTextView
                
                // 显示消耗的卡路里或占位符
                calorieIndicatorView
            }
            .padding(.vertical, 2)
            .frame(height: 54)
        }
        
        // 日期文本视图
        private var dayTextView: some View {
            Text("\(item.day)")
                .font(.system(size: 15, weight: item.isToday ? .bold : .regular))
                .foregroundColor(item.isToday ? .white : (item.isCurrentMonth ? .primary : .gray.opacity(0.6)))
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(item.isToday ? Color.blue : Color.clear)
                )
        }
        
        // 卡路里指示器视图
        private var calorieIndicatorView: some View {
            Group {
                if item.hasData {
                    Text("\(Int(item.burnedCalories))")
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                        .padding(2)
                        .frame(minWidth: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.isGoalAchieved ? Color.green.opacity(0.2) : Color(UIColor.systemGray5))
                        )
                } else if item.isCurrentMonth {
                    // 当月无数据显示小圆点
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 4, height: 4)
                        .padding(.top, 8)
                } else {
                    // 占位，保持高度一致
                    Color.clear
                        .frame(height: 18)
                }
            }
        }
    }
    
    // MARK: - 周热量图表
    private struct WeeklyCalorieChart: View {
        let dataPoints: [WeeklyDataPoint]
        
        var body: some View {
            VStack(spacing: 16) {
                // 图表部分
                chartBarsView
                
                // 中心线
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
                    .padding(.horizontal, 10)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(14)
        }
        
        // 柱状图部分
        private var chartBarsView: some View {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(dataPoints) { point in
                    singleBarView(for: point)
                }
            }
            .frame(maxHeight: 180)
            .padding(.top, 20)
        }
        
        // 单个柱状图
        private func singleBarView(for point: WeeklyDataPoint) -> some View {
            VStack(spacing: 4) {
                // 目标点标记
                Circle()
                    .fill(Color.orange.opacity(0.7))
                    .frame(width: 8, height: 8)
                    .offset(y: -getHeight(for: point.targetCalories) + 4)
                    .zIndex(1)
                
                // 消耗热量柱
                Capsule()
                    .fill(Color.green.opacity(0.7))
                    .frame(width: 20, height: getHeight(for: point.burnedCalories))
                    .background(
                        Capsule()
                            .fill(point.isGoalAchieved ? Color.green.opacity(0.2) : Color.clear)
                            .frame(width: 30, height: getHeight(for: point.burnedCalories) + 10)
                    )
                
                // 星期标签
                Text(point.weekday)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.top, 6)
            }
            .frame(maxWidth: .infinity)
        }
        
        // 计算柱状图高度
        private func getHeight(for value: Double) -> CGFloat {
            // 最大热量值，用于归一化
            let maxValue = max(
                dataPoints.map { max($0.burnedCalories, $0.targetCalories) }.max() ?? 1000,
                1000 // 设置最小上限，防止空数据
            )
            
            // 最大高度
            let maxHeight: CGFloat = 160
            
            return CGFloat(value) / CGFloat(maxValue) * maxHeight
        }
    }
    
    // MARK: - 辅助方法和数据生成
    
    // 格式化日期
    private func formatDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    // 格式化周范围
    private func formatWeekRange(_ date: Date) -> String {
        let calendar = Calendar.current
        guard let weekStartDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)),
              let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate) else {
            return ""
        }
        
        let startFormatter = DateFormatter()
        let endFormatter = DateFormatter()
        
        // 如果跨月，显示月份
        if calendar.component(.month, from: weekStartDate) != calendar.component(.month, from: weekEndDate) {
            startFormatter.dateFormat = "MM月dd日"
            endFormatter.dateFormat = "MM月dd日"
        } else {
            startFormatter.dateFormat = "MM月dd日"
            endFormatter.dateFormat = "dd日"
        }
        
        return "\(startFormatter.string(from: weekStartDate))-\(endFormatter.string(from: weekEndDate))"
    }
    
    // 生成月日历数据
    private func generateMonthCalendarItems() -> [CalendarDateItem] {
        // 获取日历数据
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedMonth)
        guard let firstDayOfMonth = calendar.date(from: components),
              let lastDayOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDayOfMonth) else {
            return []
        }
        
        // 获取本月第一天是星期几（0是星期日）
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        
        var items: [CalendarDateItem] = []
        
        // 添加上个月的填充天数
        if firstWeekday > 0 {
            for i in 0..<firstWeekday {
                guard let prevDate = calendar.date(byAdding: .day, value: -firstWeekday + i, to: firstDayOfMonth) else { continue }
                let day = calendar.component(.day, from: prevDate)
                items.append(CalendarDateItem(
                    day: day,
                    isCurrentMonth: false,
                    isToday: calendar.isDateInToday(prevDate),
                    hasData: false,
                    burnedCalories: 0,
                    targetCalories: 0,
                    isGoalAchieved: false
                ))
            }
        }
        
        // 添加本月的天数
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)?.count ?? 30
        
        for day in 1...daysInMonth {
            guard let date = calendar.date(bySetting: .day, value: day, of: firstDayOfMonth) else { continue }
            
            // 获取当天记录
            let dayRecords = viewModel.getRecordsForDate(date)
            let hasData = !dayRecords.isEmpty
            
            // 计算消耗的卡路里和目标卡路里（美食卡路里）
            let burnedCalories = dayRecords.reduce(0) { $0 + $1.caloriesBurned }
            let targetCalories = dayRecords.reduce(0) { $0 + (Double($1.dessert.calories) ?? 0) }
            
            // 达成目标：消耗卡路里大于或等于目标卡路里
            let goalAchieved = burnedCalories >= targetCalories && hasData
            
            items.append(CalendarDateItem(
                day: day,
                isCurrentMonth: true,
                isToday: calendar.isDateInToday(date),
                hasData: hasData,
                burnedCalories: burnedCalories,
                targetCalories: targetCalories,
                isGoalAchieved: goalAchieved
            ))
        }
        
        // 计算需要填充的下个月天数
        let totalCellsNeeded = 42 // 6行7列
        let remainingCells = totalCellsNeeded - items.count
        
        // 添加下个月的填充
        if remainingCells > 0 {
            for day in 1...remainingCells {
                guard let nextDate = calendar.date(byAdding: .day, value: day, to: lastDayOfMonth) else { continue }
                items.append(CalendarDateItem(
                    day: day,
                    isCurrentMonth: false,
                    isToday: calendar.isDateInToday(nextDate),
                    hasData: false,
                    burnedCalories: 0,
                    targetCalories: 0,
                    isGoalAchieved: false
                ))
            }
        }
        
        return items
    }
    
    // 生成周图表数据
    private func generateWeekChartData(for weekDate: Date) -> [WeeklyDataPoint] {
        let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        var dataPoints: [WeeklyDataPoint] = []
        
        // 获取周的开始日期
        let calendar = Calendar.current
        guard let weekStartDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekDate)) else {
            return []
        }
        
        // 为每一天生成数据
        for (index, day) in weekdays.enumerated() {
            guard let date = calendar.date(byAdding: .day, value: index, to: weekStartDate) else { continue }
            
            // 获取当天记录
            let dayRecords = viewModel.getRecordsForDate(date)
            
            // 如果有记录，使用实际数据
            if !dayRecords.isEmpty {
                let burnedCalories = dayRecords.reduce(0) { $0 + $1.caloriesBurned }
                let targetCalories = dayRecords.reduce(0) { $0 + (Double($1.dessert.calories) ?? 0) }
                
                dataPoints.append(WeeklyDataPoint(
                    id: index,
                    weekday: day,
                    burnedCalories: burnedCalories,
                    targetCalories: targetCalories,
                    isGoalAchieved: burnedCalories >= targetCalories
                ))
            } else {
                // 无记录时使用0值
                dataPoints.append(WeeklyDataPoint(
                    id: index,
                    weekday: day,
                    burnedCalories: 0,
                    targetCalories: 0,
                    isGoalAchieved: false
                ))
            }
        }
        
        return dataPoints
    }
} 