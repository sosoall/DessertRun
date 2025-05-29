import SwiftUI

/// 月视图日历组件
struct MonthCalendarView: View {
    @ObservedObject var viewModel: ExerciseRecordViewModel
    @State private var selectedMonth: Date
    
    // 颜色定义
    private let pinkColor = Color(hex: "FE2D55") // 运动量super！颜色
    private let yellowColor = Color(hex: "FF9901") // 已运动颜色
    private let grayColor = Color(hex: "ECECEC") // 未运动颜色 - 更浅的灰色
    
    // 一周的天数
    private let daysOfWeek = ["日", "一", "二", "三", "四", "五", "六"]
    
    // 初始化方法
    init(viewModel: ExerciseRecordViewModel) {
        self.viewModel = viewModel
        self._selectedMonth = State(initialValue: viewModel.selectedMonth)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 月份切换
            HStack(alignment: .center) {
                Spacer()
                
                HStack(spacing: 4) {
                    Button(action: {
                        viewModel.goToPreviousMonth()
                        selectedMonth = viewModel.selectedMonth
                        
                        // 月份变更后立即加载对应月份的统计数据
                        let calendar = Calendar.current
                        let year = calendar.component(.year, from: selectedMonth)
                        let month = calendar.component(.month, from: selectedMonth)
                        viewModel.loadMonthStats(year: year, month: month)
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                    
                    Text(monthYearString(from: selectedMonth))
                        .font(.system(size: 16, weight: .medium))
                    
                    Button(action: {
                        viewModel.goToNextMonth()
                        selectedMonth = viewModel.selectedMonth
                        
                        // 月份变更后立即加载对应月份的统计数据
                        let calendar = Calendar.current
                        let year = calendar.component(.year, from: selectedMonth)
                        let month = calendar.component(.month, from: selectedMonth)
                        viewModel.loadMonthStats(year: year, month: month)
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            // 星期栏
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Color(hex: "909090"))
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            // 日历网格 - 动态行数
            let calendarRows = calculateCalendarRows()
            VStack(spacing: 8) {
                // 根据当前月份需要的行数动态创建行
                ForEach(0..<calendarRows, id: \.self) { weekIndex in
                    HStack(spacing: 4) {
                        // 每周7天，周日到周六
                        ForEach(0..<7) { dayIndex in
                            let dayOffset = weekIndex * 7 + dayIndex
                            if dayOffset < monthDays().count {
                                let dateInfo = monthDays()[dayOffset]
                                if dateInfo.isCurrentMonth {
                                    calendarCell(for: dateInfo.date)
                                } else {
                                    // 不在当前月份的空白单元格
                                    Color.clear
                                        .aspectRatio(1, contentMode: .fit)
                                }
                            } else {
                                // 超出当月天数的空白单元格
                                Color.clear
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            
            // 图例说明
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(pinkColor)
                        .frame(width: 14, height: 14)
                    
                    Text("运动量super！")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "909090"))
                }
                
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(yellowColor)
                        .frame(width: 14, height: 14)
                    
                    Text("已运动")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "909090"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .onAppear {
            DRInfo("[MonthCalendarView] onAppear 触发，当前月份: \(monthYearString(from: selectedMonth))")
            // 确保初次显示时有数据
            let calendar = Calendar.current
            let year = calendar.component(.year, from: selectedMonth)
            let month = calendar.component(.month, from: selectedMonth)
            
            // 如果当前月份没有数据，重新加载
            if viewModel.dailyStatsMap.isEmpty {
                DRInfo("[MonthCalendarView] 日历数据为空，重新加载月份数据")
                viewModel.loadMonthStats(year: year, month: month)
            }
        }
        .onReceive(viewModel.$dailyStatsMap) { statsMap in
            DRInfo("[MonthCalendarView] dailyStatsMap 更新，当前数据量: \(statsMap.count)")
            // 当数据更新时，触发视图刷新
            selectedMonth = viewModel.selectedMonth
        }
        .onChange(of: viewModel.selectedMonth) { oldMonth, newMonth in
            DRInfo("[MonthCalendarView] selectedMonth 变化: \(monthYearString(from: oldMonth)) -> \(monthYearString(from: newMonth))")
            selectedMonth = newMonth
        }
    }
    
    // 计算日历需要的行数
    private func calculateCalendarRows() -> Int {
        let days = monthDays()
        // 计算实际需要的行数，向上取整
        return Int(ceil(Double(days.count) / 7.0))
    }
    
    // 单个日历单元格
    private func calendarCell(for date: Date) -> some View {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        // 从新的数据源获取日期数据
        let dailyStat = viewModel.dailyStatsMap[dateComponents]
        let hasWorkout = dailyStat?.hasWorkout ?? false
        
        return ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(hasWorkout ? pinkColor : grayColor)
                .aspectRatio(1, contentMode: .fit)
            
            if !hasWorkout {
                // 没有运动记录时显示日期数字
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.gray.opacity(0.6))
            } else if let stat = dailyStat, let dessertCount = stat.totalDessertCount {
                // 有运动记录时显示美食数量和图标
                VStack(spacing: 4) {
                    // 获取最多打卡的美食种类
                    if let popularDessert = stat.mostPopularDessert {
                        // 从后端获取图标URL
                        if let iconURL = APIService.shared.getDessertImageURL(dessertId: popularDessert.dessertId, type: "icon") {
                            // 使用AsyncImage加载图标
                            AsyncImage(url: iconURL) { phase in
                                switch phase {
                                case .empty:
                                    // 加载中显示空白
                                    Color.clear.frame(width: 24, height: 24)
                                case .success(let image):
                                    // 加载成功显示图片
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 24, height: 24)
                                case .failure:
                                    // 加载失败显示默认图标
                                    Image(systemName: "cup.and.saucer.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                @unknown default:
                                    // 未知状态
                                    Color.clear.frame(width: 24, height: 24)
                                }
                            }
                        } else {
                            // 无法获取URL时显示默认图标
                            Image(systemName: "cup.and.saucer.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                        }
                    }
                    
                    // 显示美食倍数
                    Text("\(String(format: "%.1f", dessertCount))x")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black)
                }
            }
        }
    }
    
    // MARK: - 辅助方法
    
    // 获取月份和年份的字符串
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }
    
    // 获取当前月份所有日期
    private func monthDays() -> [(date: Date, isCurrentMonth: Bool)] {
        var days: [(date: Date, isCurrentMonth: Bool)] = []
        
        let calendar = Calendar.current
        
        // 当前月的第一天
        let components = calendar.dateComponents([.year, .month], from: selectedMonth)
        guard let startOfMonth = calendar.date(from: components) else { return [] }
        
        // 当前月的最后一天
        guard let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth),
              let lastDayOfMonth = calendar.date(byAdding: .day, value: -1, to: endOfMonth) else { return [] }
        
        // 第一天是星期几
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        
        // 添加上个月的日期填充第一周
        if firstWeekday > 1 {
            for day in (1..<firstWeekday).reversed() {
                if let previousDay = calendar.date(byAdding: .day, value: -day, to: startOfMonth) {
                    days.append((previousDay, false))
                }
            }
        }
        
        // 添加当前月的所有日期
        for day in 0...calendar.component(.day, from: lastDayOfMonth) - 1 {
            if let date = calendar.date(byAdding: .day, value: day, to: startOfMonth) {
                days.append((date, true))
            }
        }
        
        // 填充最后一周
        let remainingDays = 7 - (days.count % 7)
        if remainingDays < 7 {
            for day in 1...remainingDays {
                if let nextDay = calendar.date(byAdding: .day, value: day, to: lastDayOfMonth) {
                    days.append((nextDay, false))
                }
            }
        }
        
        return days
    }
}

// MARK: - 预览
struct MonthCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        MonthCalendarView(viewModel: ExerciseRecordViewModel(appState: AppState.shared))
            .previewLayout(.sizeThatFits)
            .padding()
    }
} 