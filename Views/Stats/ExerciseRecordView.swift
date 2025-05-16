import SwiftUI

/// 运动记录标签页
struct ExerciseRecordView: View {
    @ObservedObject var viewModel: ExerciseRecordViewModel
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: StatTab = .month
    @State private var selectedMonth: Date = Date()
    @State private var selectedWeek: Date = Date()
    @State private var hasAppeared: Bool = false  // 添加状态变量控制是否已经加载过数据
    
    enum StatTab: String, CaseIterable, Identifiable {
        case year = "年"
        case month = "月"
        case week = "周"
        
        var id: String { self.rawValue }
        
        var iconName: String {
            switch self {
            case .year: return "calendar"
            case .month: return "calendar.badge.clock"
            case .week: return "calendar.day.timeline.left"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 顶部标题和视图切换
                HStack {
                    Text("运动记录")
                        .font(.system(size: 22, weight: .semibold))
                    
                    Spacer()
                    
                    // 视图切换按钮
                    HStack(spacing: 16) {
                        ForEach(StatTab.allCases) { tab in
                            Button(action: {
                                selectedTab = tab
                            }) {
                                Image(systemName: tab.iconName)
                                    .foregroundColor(selectedTab == tab ? Color(hex: "FE2D55") : .gray)
                                    .font(.system(size: 20))
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // 根据选择的Tab显示不同内容
                if selectedTab == .month {
                    // 月视图
                    VStack(spacing: 16) {
                        // 月份日历视图
                        MonthCalendarView(viewModel: viewModel)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                            .padding(.horizontal)
                        
                        // 统计卡片行
                        statisticsCardsRow
                    }
                } else if selectedTab == .week {
                    // 周视图
                    VStack(spacing: 16) {
                        // 周视图图表
                        weekChartView
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                            .padding(.horizontal)
                            
                        // 进度条卡片
                        weeklyProgressCard
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                            .padding(.horizontal)
                    }
                } else {
                    // 年视图
                    VStack(spacing: 16) {
                        // 年度日历视图
                        YearlyCalendarView(viewModel: viewModel)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                            .padding(.horizontal)
                            
                        // 统计卡片行
                        statisticsCardsRow
                    }
                }
                
                Spacer(minLength: 80) // 确保底部有足够空间
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGray6))
        .onAppear {
            // 初始化时同步视图Model的年份和月份到本地状态
            selectedMonth = viewModel.selectedMonth
            selectedWeek = Date() // 默认显示当前周
            
            // 只在第一次显示视图时加载数据
            if !hasAppeared {
                DRDebug("[ExerciseRecordView] 首次加载视图，获取数据")
                
                // 确保使用当前日期初始化视图
                let calendar = Calendar.current
                let currentYear = calendar.component(.year, from: Date())
                let currentMonth = calendar.component(.month, from: Date())
                
                // 直接加载数据（已优化数据加载顺序）
                viewModel.loadData()
                
                // 标记为已加载
                hasAppeared = true
            } else {
                DRDebug("[ExerciseRecordView] 视图已经加载过，但仍然刷新当前显示的数据")
                
                // 即使不是首次加载，也刷新当前视图的数据
                refreshCurrentTabData()
            }
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            // 当切换标签页时，确保viewModel中的年份和月份是最新的
            refreshCurrentTabData()
        }
    }
    
    // 统计卡片行
    private var statisticsCardsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 卡路里消耗卡片
                caloriesBurnedCard
                
                // 运动天数卡片
                workoutDaysCard
                
                // 运动时长卡片
                workoutDurationCard
                
                // 运动距离卡片
                workoutDistanceCard
            }
            .padding(.horizontal)
        }
    }
    
    // 卡路里消耗卡片
    private var caloriesBurnedCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(hex: "FE2D55"))
                .frame(width: 24, height: 24)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(selectedTab == .month ? viewModel.monthlyTotalCalories : viewModel.yearlyTotalCalories))")
                    .font(.system(size: 20, weight: .semibold))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text("卡路里")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 2, y: 2)
    }
    
    // 运动天数卡片
    private var workoutDaysCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(hex: "FE2D55"))
                .frame(width: 24, height: 24)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(selectedTab == .month ? viewModel.monthlyWorkoutCount : viewModel.yearlyWorkoutCount)")
                    .font(.system(size: 20, weight: .semibold))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text("天")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 2, y: 2)
    }
    
    // 运动时长卡片
    private var workoutDurationCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock")
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(hex: "FE2D55"))
                .frame(width: 24, height: 24)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(selectedTab == .month ? viewModel.monthlyTotalDuration : viewModel.yearlyTotalDuration))")
                    .font(.system(size: 20, weight: .semibold))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text("分钟")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 2, y: 2)
    }
    
    // 运动距离卡片
    private var workoutDistanceCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "figure.walk")
                .resizable()
                .scaledToFit()
                .foregroundColor(Color(hex: "FE2D55"))
                .frame(width: 24, height: 24)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                let distance = selectedTab == .month ? 
                    viewModel.formatTotalDistance(meters: viewModel.monthlyTotalDistance) :
                    viewModel.formatTotalDistance(meters: viewModel.yearlyTotalDistance)
                
                Text(distance)
                    .font(.system(size: 20, weight: .semibold))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text("公里")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 2, y: 2)
    }
    
    // 周视图柱状图
    private var weekChartView: some View {
        VStack(spacing: 12) {
            // 周日期选择器
            HStack {
                Spacer()
                
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
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            // 周热量图表
            WeeklyCalorieChart(dataPoints: generateWeekChartData(for: selectedWeek))
                .frame(height: 250)
                .padding(.horizontal)
            
            // 图例
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
                
                // 运动目标图例
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "34C759"))
                        .frame(width: 14, height: 14)
                    
                    Text("运动目标")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "909090"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }
    
    // 新增周运动进度卡片
    private var weeklyProgressCard: some View {
        VStack(spacing: 10) {
            // 标题和数值
            HStack {
                Text("本周运动天数")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "A4A4A4"))
                
                Spacer()
                
                Text("\(calculateWeekWorkoutDays())/7天")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "FF5D50"))
            }
            
            // 进度条和刻度布局
            VStack(spacing: 4) {
                // 进度条
                ZStack(alignment: .leading) {
                    // 背景条
                    RoundedRectangle(cornerRadius: 99)
                        .fill(Color(hex: "D9D9D9"))
                        .frame(height: 8)
                    
                    // 进度条
                    RoundedRectangle(cornerRadius: 99)
                        .fill(Color(hex: "FF329A"))
                        .frame(width: calculateProgressWidth(), height: 8)
                }
                .padding(.horizontal, 2) // 添加小边距，确保与刻度0和7对齐
                
                // 数字标识 - 使用自定义布局确保刻度对齐
                HStack(spacing: 0) {
                    // 0刻度 - 左对齐
                    Text("0")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "A4A4A4"))
                        .frame(width: 20, alignment: .leading)
                    
                    Spacer()
                    
                    // 中间刻度 - 均匀分布
                    ForEach(1...6, id: \.self) { num in
                        Text("\(num)")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "A4A4A4"))
                        
                        if num < 6 {
                            Spacer()
                        }
                    }
                    
                    Spacer()
                    
                    // 7刻度 - 右对齐
                    Text("7")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "A4A4A4"))
                        .frame(width: 20, alignment: .trailing)
                }
                .padding(.horizontal, 2) // 与进度条保持相同边距
            }
        }
        .padding(16)
    }
    
    // 计算当前选中周的运动天数
    private func calculateWeekWorkoutDays() -> Int {
        let weekData = generateWeekChartData(for: selectedWeek)
        return weekData.filter { $0.hasWorkout }.count
    }
    
    // 计算进度条宽度
    private func calculateProgressWidth() -> CGFloat {
        let totalWidth: CGFloat = UIScreen.main.bounds.width - 32 - 32 - 4 // 屏幕宽度减去内外边距
        let progress = CGFloat(calculateWeekWorkoutDays()) / 7.0
        return totalWidth * progress
    }
    
    // 格式化周范围字符串
    private func formatWeekRange(_ date: Date) -> String {
        let calendar = Calendar.current
        
        // 获取date所在周的周日（本周开始日期）
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        guard let startOfWeek = calendar.date(from: components) else { return "" }
        
        // 获取周六（本周结束日期）
        guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else { return "" }
        
        // 创建日期格式器
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        
        // 返回格式化的周范围
        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
    }
    
    // 生成周视图的数据
    private func generateWeekChartData(for weekStartDate: Date) -> [WeekDayData] {
        let calendar = Calendar.current
        
        // 获取weekStartDate所在周的周日（本周开始日期）
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStartDate)
        guard let startOfWeek = calendar.date(from: components) else { return [] }
        
        // 生成一周的数据
        var weekData: [WeekDayData] = []
        
        for dayOffset in 0...6 {
            guard let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek) else { continue }
            
            // 获取当天的运动记录并按时间排序
            let dayRecords = viewModel.getRecordsForDate(currentDate).sorted(by: { $0.date < $1.date })
            
            // 获取最早记录的甜品ID（如果有）
            let firstDessertId = dayRecords.first?.dessert.id
            
            // 计算总消耗热量
            let totalBurned = dayRecords.reduce(0.0) { $0 + $1.caloriesBurned }
            
            // 计算总目标热量
            let totalTarget = dayRecords.reduce(0.0) { $0 + (Double($1.dessert.calories) ?? 0) }
            
            // 判断是否达成目标
            let isGoalAchieved = totalBurned >= totalTarget && totalTarget > 0
            
            // 获取星期几
            let weekday = calendar.component(.weekday, from: currentDate)
            
            // 创建数据点
            let dataPoint = WeekDayData(
                date: currentDate,
                day: ["日", "一", "二", "三", "四", "五", "六"][weekday - 1],
                caloriesBurned: Int(totalBurned),
                hasWorkout: !dayRecords.isEmpty,
                isGoalAchieved: isGoalAchieved,
                targetCalories: totalTarget > 0 ? Int(totalTarget) : nil,
                dessertId: firstDessertId
            )
            
            weekData.append(dataPoint)
        }
        
        return weekData
    }
    
    // 刷新当前选中标签页的数据
    private func refreshCurrentTabData() {
        let calendar = Calendar.current
        
        switch selectedTab {
        case .month:
            // 切换到月视图时，确保使用当前选中的月份
            viewModel.selectedMonth = selectedMonth
            
            // 重新加载当前月份的统计数据
            let year = calendar.component(.year, from: selectedMonth)
            let month = calendar.component(.month, from: selectedMonth)
            viewModel.loadMonthStats(year: year, month: month)
            
        case .year:
            // 切换到年视图时，重新加载年度统计数据
            let year = calendar.component(.year, from: viewModel.selectedYear)
            viewModel.loadYearStats(year: year)
            
        case .week:
            // 切换到周视图时，确保使用当前选中的周
            // 周视图使用selectedWeek，不需要额外处理
            break
        }
    }
}

// 单个运动记录卡片
struct ExerciseRecordCard: View {
    let record: WorkoutRecord
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部日期
            HStack {
                Text(record.formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // 目标状态指示器
                if record.caloriesBurned >= (Double(record.dessert.calories) ?? 0) {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 14, height: 14)
                        
                        Text("已达成")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: 14, height: 14)
                        
                        Text("未达成")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // 主要内容
            HStack(alignment: .center, spacing: 16) {
                // 甜品图标
                ZStack {
                    Circle()
                        .fill(Color(hex: "FE2D55").opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    // 从后端获取图标
                    if let iconURL = APIService.shared.getDessertImageURL(dessertId: record.dessert.id, type: "icon") {
                        AsyncImage(url: iconURL) { phase in
                            switch phase {
                            case .empty:
                                // 加载中显示空白
                                ProgressView()
                                    .frame(width: 60, height: 60)
                            case .success(let image):
                                // 加载成功显示图片
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)
                            case .failure:
                                // 加载失败显示默认图标
                                Image(systemName: "cup.and.saucer.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.gray)
                                    .frame(width: 60, height: 60)
                            @unknown default:
                                // 未知状态
                                Color.clear.frame(width: 60, height: 60)
                            }
                        }
                    } else {
                        // 无法获取URL时显示默认图标
                        Image(systemName: "cup.and.saucer.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.gray)
                            .frame(width: 60, height: 60)
                    }
                }
                
                // 甜品信息和进度
                VStack(alignment: .leading, spacing: 6) {
                    // 甜品名称和热量
                    Text(record.dessert.name)
                        .font(.headline)
                    
                    Text("\(record.dessert.calories)卡")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // 进度条
                    HStack {
                        // 进度文本
                        Text("\(Int(record.caloriesBurned))/\(record.dessert.calories)卡")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                    
                    // 自定义进度条
                    ProgressView(value: min(record.caloriesBurned / (Double(record.dessert.calories) ?? 1), 1.0))
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "FE2D55")))
                        .frame(height: 6)
                }
                
                Spacer()
            }
            
            // 运动详情
            HStack(spacing: 20) {
                // 运动类型
                VStack(spacing: 4) {
                    Image(systemName: getExerciseIcon(record.exerciseType.name))
                        .foregroundColor(Color(hex: "FE2D55"))
                    
                    Text(record.exerciseType.name)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // 时长或距离
                if record.exerciseType.usesDistance {
                    VStack(spacing: 4) {
                        if let distance = record.distance {
                            Text(String(format: "%.2f", distance / 1000)) // 转换为公里
                                .font(.caption)
                                .foregroundColor(.black)
                            
                            Text("公里")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("无数据")
                                .font(.caption)
                                .foregroundColor(.black)
                        }
                    }
                } else {
                    VStack(spacing: 4) {
                        Text("\(Int(record.duration ?? 0))")
                            .font(.caption)
                            .foregroundColor(.black)
                        
                        Text("分钟")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                // 热量消耗
                VStack(spacing: 4) {
                    Text("\(Int(record.caloriesBurned))")
                        .font(.caption)
                        .foregroundColor(.black)
                    
                    Text("卡路里")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    // 获取运动类型图标
    private func getExerciseIcon(_ exerciseType: String) -> String {
        switch exerciseType {
        case "跑步":
            return "figure.run"
        case "步行":
            return "figure.walk"
        case "骑行":
            return "bicycle"
        case "游泳":
            return "figure.pool.swim"
        case "力量训练":
            return "dumbbell"
        default:
            return "heart.circle"
        }
    }
}

// MARK: - 辅助模型

// 周图表数据结构
struct WeekDayData: Identifiable {
    let id = UUID()
    let date: Date
    let day: String
    let caloriesBurned: Int
    let hasWorkout: Bool
    let isGoalAchieved: Bool
    let targetCalories: Int?
    var dessertId: String? // 添加甜品ID
}

// 周视图柱状图
struct WeeklyCalorieChart: View {
    let dataPoints: [WeekDayData]
    private let maxHeight: CGFloat = 200
    
    var body: some View {
        // 柱状图主体
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(dataPoints) { point in
                VStack(spacing: 8) {
                    // 空白占位，保持布局一致
                    Text("")
                        .font(.system(size: 12))
                    
                    // 柱状图
                    ZStack(alignment: .bottom) {
                        // 背景
                        Rectangle()
                            .frame(height: maxHeight)
                            .opacity(0)
                        
                        if point.hasWorkout {
                            // 柱状
                            VStack(spacing: 0) {
                                // 柱子
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(point.isGoalAchieved ? Color(hex: "FE2D55") : Color(hex: "FF9901"))
                                    .frame(height: calculateBarHeight(calories: point.caloriesBurned))
                                    .frame(width: 25)
                                
                                // 美食图标 - 新增部分
                                if let dessertId = point.dessertId, !dessertId.isEmpty {
                                    if let iconURL = APIService.shared.getDessertImageURL(dessertId: dessertId, type: "icon") {
                                        // 使用AsyncImage加载图标
                                        AsyncImage(url: iconURL) { phase in
                                            switch phase {
                                            case .empty:
                                                // 加载中显示空白
                                                Color.clear.frame(width: 25, height: 25)
                                            case .success(let image):
                                                // 加载成功显示图片
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 25, height: 25)
                                            case .failure:
                                                // 加载失败显示默认图标
                                                Image(systemName: "cup.and.saucer.fill")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .foregroundColor(.gray)
                                                    .frame(width: 25, height: 25)
                                            @unknown default:
                                                // 未知状态
                                                Color.clear.frame(width: 25, height: 25)
                                            }
                                        }
                                    } else {
                                        // 无法获取URL时显示默认图标
                                        Image(systemName: "cup.and.saucer.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .foregroundColor(.gray)
                                            .frame(width: 25, height: 25)
                                    }
                                }
                            }
                        } else {
                            // 无运动记录时显示浅灰色柱子
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color(hex: "F8F8F8"))
                                .frame(height: 25)
                                .frame(width: 25)
                        }
                        
                        // 目标卡路里绿点
                        if let targetCalories = point.targetCalories, targetCalories > 0 {
                            Circle()
                                .fill(Color(hex: "34C759"))
                                .frame(width: 10, height: 10)
                                .offset(y: -calculateBarHeight(calories: targetCalories) + 5)
                        }
                    }
                    
                    // 星期几
                    Text(point.day)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "DCDCDC"))
                    
                    // 卡路里显示（如果有运动记录）
                    if point.hasWorkout {
                        Text("\(point.caloriesBurned)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    } else {
                        Text("")
                            .font(.system(size: 12))
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // 计算柱状图高度
    private func calculateBarHeight(calories: Int) -> CGFloat {
        // 找出最大卡路里值以便缩放
        let maxCalories = max(
            dataPoints.map { $0.caloriesBurned }.max() ?? 1,
            dataPoints.compactMap { $0.targetCalories }.max() ?? 0
        )
        let heightRatio = min(Double(calories) / Double(max(maxCalories, 1)), 1.0)
        
        // 确保即使最小的消耗也有一定高度
        let minHeight: CGFloat = 30
        return max(CGFloat(heightRatio) * maxHeight, calories > 0 ? minHeight : 0)
    }
}

// MARK: - 预览
struct ExerciseRecordView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseRecordView(viewModel: ExerciseRecordViewModel(appState: AppState.shared))
            .environmentObject(AppState.shared)
    }
} 