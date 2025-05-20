import SwiftUI

/// 年度日历视图组件
struct YearlyCalendarView: View {
    @ObservedObject var viewModel: ExerciseRecordViewModel
    
    // 每行显示的月份数
    private let monthsPerRow = 3
    
    var body: some View {
        VStack(spacing: 16) {
            // 年份选择器
            HStack {
                Button(action: {
                    viewModel.goToPreviousYear()
                    
                    // 年份变更后立即加载对应年份的统计数据
                    let calendar = Calendar.current
                    let year = calendar.component(.year, from: viewModel.selectedYear)
                    viewModel.loadYearStats(year: year)
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(yearString)
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                Button(action: {
                    viewModel.goToNextYear()
                    
                    // 年份变更后立即加载对应年份的统计数据
                    let calendar = Calendar.current
                    let year = calendar.component(.year, from: viewModel.selectedYear)
                    viewModel.loadYearStats(year: year)
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
                // 已运动图例
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "FE2D55"))
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
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        
        // 直接通过比较年月日查找，解决DateComponents引用比较问题
        let hasWorkout = viewModel.yearlyStatsMap.contains { key, _ in
            return key.year == year && key.month == month && key.day == day
        }
        
        // 颜色逻辑：有运动记录用粉色，无记录用灰色
        let cellColor: Color = hasWorkout ? Color(hex: "FE2D55") : Color(hex: "EEEEEE")
        
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
        YearlyCalendarView(viewModel: ExerciseRecordViewModel(appState: AppState.shared))
            .background(Color.white)
            .previewLayout(.sizeThatFits)
    }
}
