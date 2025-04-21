import SwiftUI
import Combine

/// 统计视图模型 - 管理统计相关数据和逻辑
class StatsViewModel: ObservableObject {
    // MARK: - 发布属性
    
    /// 当前选定的月份
    @Published var selectedMonth: Date = Date()
    
    /// 筛选后的运动记录
    @Published var filteredWorkoutRecords: [WorkoutRecord] = []
    
    /// 是否显示月份选择器
    @Published var showMonthPicker: Bool = false
    
    /// 全局状态引用
    private var appState: AppState
    
    /// 发布者集合
    private var cancellables = Set<AnyCancellable>()
    
    // 添加新的热量平衡统计属性
    @Published var monthlyClearedDesserts: Int = 0
    @Published var monthlyDeficitDays: Int = 0
    @Published var weeklyDeficitDays: Int = 0
    
    @Published var monthlyConsumedCalories: Double = 0
    @Published var monthlyBurnedCalories: Double = 0
    @Published var weeklyConsumedCalories: Double = 0
    @Published var weeklyBurnedCalories: Double = 0
    
    // MARK: - 初始化方法
    
    /// 初始化
    init(appState: AppState) {
        self.appState = appState
        
        // 订阅运动记录变化
        appState.$workoutRecords
            .sink { [weak self] records in
                self?.filterRecordsByMonth()
            }
            .store(in: &cancellables)
        
        // 订阅月份变化
        $selectedMonth
            .sink { [weak self] _ in
                self?.filterRecordsByMonth()
            }
            .store(in: &cancellables)
        
        // 初始筛选
        filterRecordsByMonth()
        
        // 异步加载模拟数据，避免在视图更新周期内修改状态
        DispatchQueue.main.async { [weak self] in
            self?.loadMockData()
            self?.calculateStats()
        }
    }
    
    // MARK: - 计算属性
    
    /// 当前月份名称（中文）
    var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: selectedMonth)
    }
    
    /// 当月的总运动时长（分钟）
    var totalDurationThisMonth: Double {
        filteredWorkoutRecords.reduce(0) { $0 + $1.duration }
    }
    
    /// 当月的总消耗卡路里
    var totalCaloriesThisMonth: Double {
        filteredWorkoutRecords.reduce(0) { $0 + $1.caloriesBurned }
    }
    
    /// 当月的运动次数
    var workoutCountThisMonth: Int {
        filteredWorkoutRecords.count
    }
    
    // MARK: - 方法
    
    /// 切换到上个月
    func goToPreviousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
    
    /// 切换到下个月
    func goToNextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = newDate
        }
    }
    
    /// 设置当前月份
    func setMonth(_ date: Date) {
        selectedMonth = date
        showMonthPicker = false
    }
    
    /// 根据月份筛选记录
    private func filterRecordsByMonth() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedMonth)
        
        guard let startOfMonth = calendar.date(from: components),
              let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            filteredWorkoutRecords = []
            return
        }
        
        // 筛选本月记录
        filteredWorkoutRecords = appState.workoutRecords.filter { record in
            return record.completionDate >= startOfMonth && record.completionDate < startOfNextMonth
        }
        
        // 计算统计数据
        calculateStats()
    }
    
    /// 重置月份为当前月
    func resetToCurrentMonth() {
        selectedMonth = Date()
    }
    
    /// 根据日期获取该日的记录
    func getRecordsForDate(_ date: Date) -> [WorkoutRecord] {
        let calendar = Calendar.current
        return filteredWorkoutRecords.filter { record in
            calendar.isDate(record.completionDate, inSameDayAs: date)
        }
    }
    
    /// 检查指定日期是否有记录
    func hasRecordsForDate(_ date: Date) -> Bool {
        return !getRecordsForDate(date).isEmpty
    }
    
    /// 获取当月日期数组
    func getDaysInSelectedMonth() -> Int {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: selectedMonth) else {
            return 30 // 默认返回30天
        }
        return range.count
    }
    
    // MARK: - 私有方法
    
    /// 加载模拟数据
    private func loadMockData() {
        // 如果已经有数据，则不再重复加载
        if !appState.workoutRecords.isEmpty {
            // 重新计算统计数据即可
            calculateStats()
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        
        // 生成过去30天的随机记录
        var mockRecords: [WorkoutRecord] = []
        let desserts = DessertData.getSampleDesserts()
        let exerciseTypes = ExerciseType.allCases
        
        // 日期有一定规律，部分日期有多个记录
        // 为每周选择5天记录 (更丰富的数据)
        for dayOffset in (1...30).reversed() {
            if dayOffset % 7 == 0 || dayOffset % 7 == 6 { // 周六日概率低一些
                if Int.random(in: 0...2) > 0 { continue }
            }
            
            let recordDate = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            
            // 每天1-3条记录
            let recordsCount = Int.random(in: 1...3)
            
            for _ in 0..<recordsCount {
                // 随机选择甜品和运动
                let dessert = desserts.randomElement()!
                let exerciseType = exerciseTypes.randomElement()!
                
                // 运动时长 20-60分钟
                let duration = Double.random(in: 20...60)
                
                // 消耗的卡路里
                // 有70%概率达成目标
                let targetCalories = Double(dessert.calories) ?? 300
                let caloriesBurned = Double.random(in: 0...1) < 0.7 ?
                    targetCalories * Double.random(in: 1.0...1.5) : // 达成目标
                    targetCalories * Double.random(in: 0.5...0.95)  // 未达成目标
                
                // 创建记录
                let record = WorkoutRecord(
                    dessert: dessert,
                    exerciseType: exerciseType,
                    completionDate: recordDate,
                    duration: duration,
                    caloriesBurned: caloriesBurned
                )
                
                mockRecords.append(record)
            }
        }
        
        // 添加今天的记录
        let todayRecordsCount = Int.random(in: 1...2)
        for _ in 0..<todayRecordsCount {
            let dessert = desserts.randomElement()!
            let exerciseType = exerciseTypes.randomElement()!
            let duration = Double.random(in: 20...60)
            let targetCalories = Double(dessert.calories) ?? 300
            let caloriesBurned = targetCalories * Double.random(in: 1.0...1.3) // 今天都达成目标
            
            let record = WorkoutRecord(
                dessert: dessert,
                exerciseType: exerciseType,
                completionDate: today,
                duration: duration,
                caloriesBurned: caloriesBurned
            )
            
            mockRecords.append(record)
        }
        
        // 保存模拟数据
        appState.workoutRecords = mockRecords
        
        // 筛选当月记录
        filterRecordsByMonth()
    }
    
    /// 计算统计数据
    private func calculateStats() {
        let calendar = Calendar.current
        
        // 月度统计
        monthlyClearedDesserts = Set(filteredWorkoutRecords.map { $0.dessert.id }).count
        monthlyConsumedCalories = filteredWorkoutRecords.reduce(0) { $0 + (Double($1.dessert.calories) ?? 0) }
        monthlyBurnedCalories = filteredWorkoutRecords.reduce(0) { $0 + $1.caloriesBurned }
        
        // 计算月度减脂成功天数（每天消耗热量大于等于摄入热量）
        var deficitDaysSet = Set<DateComponents>()
        for record in filteredWorkoutRecords {
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: record.completionDate)
            
            // 获取当天所有记录
            let sameDay = filteredWorkoutRecords.filter {
                calendar.isDate($0.completionDate, inSameDayAs: record.completionDate)
            }
            
            // 计算当天热量差
            let dayBurned = sameDay.reduce(0) { $0 + $1.caloriesBurned }
            let dayConsumed = sameDay.reduce(0) { $0 + (Double($1.dessert.calories) ?? 0) }
            
            // 如果消耗大于等于摄入，认为当天减脂成功
            if dayBurned >= dayConsumed {
                deficitDaysSet.insert(dateComponents)
            }
        }
        monthlyDeficitDays = deficitDaysSet.count
        
        // 周度统计 - 获取本周日期范围
        let weekday = calendar.component(.weekday, from: Date())
        let daysFromStartOfWeek = weekday - 1 // 周日为1
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromStartOfWeek, to: Date()) else {
            return
        }
        
        // 筛选本周记录
        let weeklyRecords = filteredWorkoutRecords.filter { record in
            guard let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else {
                return false
            }
            return record.completionDate >= startOfWeek && record.completionDate < endOfWeek
        }
        
        // 计算周度消耗和摄入
        weeklyConsumedCalories = weeklyRecords.reduce(0) { $0 + (Double($1.dessert.calories) ?? 0) }
        weeklyBurnedCalories = weeklyRecords.reduce(0) { $0 + $1.caloriesBurned }
        
        // 计算周度减脂成功天数
        var weeklyDeficitDaysSet = Set<DateComponents>()
        for record in weeklyRecords {
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: record.completionDate)
            
            // 获取当天所有记录
            let sameDay = weeklyRecords.filter {
                calendar.isDate($0.completionDate, inSameDayAs: record.completionDate)
            }
            
            // 计算当天热量差
            let dayBurned = sameDay.reduce(0) { $0 + $1.caloriesBurned }
            let dayConsumed = sameDay.reduce(0) { $0 + (Double($1.dessert.calories) ?? 0) }
            
            // 如果消耗大于等于摄入，认为当天减脂成功
            if dayBurned >= dayConsumed {
                weeklyDeficitDaysSet.insert(dateComponents)
            }
        }
        weeklyDeficitDays = weeklyDeficitDaysSet.count
    }
} 