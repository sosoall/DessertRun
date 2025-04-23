import SwiftUI

/// 年度日历视图组件
struct YearlyCalendarView: View {
    @ObservedObject var viewModel: StatsViewModel
    
    // 每行显示的月份数
    private let monthsPerRow = 3
    
    var body: some View {
        VStack(spacing: 16) {
            // 年份选择器
            HStack {
                Button(action: {
                    viewModel.decrementYear()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(yearString)
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                Button(action: {
                    viewModel.incrementYear()
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // 月份网格（4行3列）
            VStack(spacing: 20) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(0..<monthsPerRow, id: \.self) { column in
                            let monthIndex = row * monthsPerRow + column
                            if monthIndex < 12 {
                                monthCalendar(for: monthIndex + 1)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            
            // 颜色图例
            HStack(spacing: 16) {
                // 运动量super图例
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "FE2D55"))
                        .frame(width: 14, height: 14)
                    
                    Text("运动量super！")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "909090"))
                }
                
                // 已运动图例
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "FF9901"))
                        .frame(width: 14, height: 14)
                    
                    Text("已运动")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "909090"))
                }
                
                // 无运动图例
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "EEEEEE"))
                        .frame(width: 14, height: 14)
                    
                    Text("无运动")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "909090"))
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .padding(.vertical, 8)
    }
    
    // 年份字符串
    private var yearString: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: viewModel.selectedYear)
        return "\(year)年"
    }
    
    // 单个月份日历
    private func monthCalendar(for month: Int) -> some View {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = calendar.component(.year, from: viewModel.selectedYear)
        components.month = month
        components.day = 1
        
        guard let date = calendar.date(from: components) else {
            return AnyView(EmptyView())
        }
        
        let monthName = getMonthName(month)
        
        return AnyView(
            VStack(spacing: 2) {
                // 月份名称
                Text(monthName)
                    .font(.system(size: 14, weight: .medium))
                    .frame(height: 20)
                
                // 日历格子 - 使用紧凑布局
                let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
                let firstWeekday = calendar.component(.weekday, from: date)
                
                VStack(spacing: 1) {
                    ForEach(0..<6, id: \.self) { row in // 固定6行
                        HStack(spacing: 1) {
                            ForEach(0..<7, id: \.self) { column in
                                let day = column + 1 + row * 7 - (firstWeekday - 1)
                                if day > 0 && day <= daysInMonth {
                                    calendarCell(year: components.year!, month: month, day: day)
                                } else {
                                    // 空白占位
                                    Color.clear
                                        .aspectRatio(1, contentMode: .fit)
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        )
    }
    
    // 日历单元格
    private func calendarCell(year: Int, month: Int, day: Int) -> some View {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        guard let date = calendar.date(from: components) else {
            return AnyView(Rectangle().fill(Color.clear))
        }
        
        let dayRecords = viewModel.getRecordsForDate(date)
        let hasWorkout = !dayRecords.isEmpty
        
        // 计算是否达成目标（消耗 >= 摄入）
        var isGoalAchieved = false
        if hasWorkout {
            let totalBurned = dayRecords.reduce(0.0) { $0 + $1.caloriesBurned }
            let totalTarget = dayRecords.reduce(0.0) { $0 + (Double($1.dessert.calories) ?? 0) }
            isGoalAchieved = totalBurned >= totalTarget && totalTarget > 0
        }
        
        // 颜色逻辑
        let cellColor: Color
        if !hasWorkout {
            cellColor = Color(hex: "EEEEEE") // 灰色：无记录
        } else if isGoalAchieved {
            cellColor = Color(hex: "FE2D55") // 粉色：已达成目标
        } else {
            cellColor = Color(hex: "FF9901") // 黄色：有运动但未达成
        }
        
        return AnyView(
            RoundedRectangle(cornerRadius: 2) // 使用圆角矩形，截图中看起来圆角较小
                .fill(cellColor)
                .aspectRatio(1, contentMode: .fit)
                .frame(minWidth: 0, maxWidth: .infinity)
        )
    }
    
    // 获取月份名称
    private func getMonthName(_ month: Int) -> String {
        return "\(month)月"
    }
}

// MARK: - 预览
struct YearlyCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        YearlyCalendarView(viewModel: StatsViewModel(appState: AppState.shared))
            .background(Color.white)
            .previewLayout(.sizeThatFits)
    }
}
