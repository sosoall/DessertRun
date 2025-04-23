import SwiftUI
import Combine

/// 统计视图模型 - 管理统计相关数据和逻辑
class StatsViewModel: ObservableObject {
    // MARK: - 发布属性
    
    /// 当前选定的月份
    @Published var selectedMonth: Date = {
        var components = DateComponents()
        components.year = 2025
        components.month = 4
        components.day = 1
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    /// 当前选定的年份
    @Published var selectedYear: Date = {
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 1
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    /// 筛选后的运动记录（月视图）
    @Published var filteredWorkoutRecords: [WorkoutRecord] = []
    
    /// 筛选后的运动记录（年视图）
    @Published var yearlyFilteredWorkoutRecords: [WorkoutRecord] = []
    
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
    
    // MARK: - 选择的日期
    @Published var selectedDay: Date = Date()
    
    // MARK: - 初始化方法
    
    /// 初始化
    init(appState: AppState) {
        self.appState = appState
        
        // 订阅运动记录变化
        appState.$workoutRecords
            .sink { [weak self] records in
                self?.filterRecordsByMonth()
                self?.filterRecordsByYear()
            }
            .store(in: &cancellables)
        
        // 订阅月份变化
        $selectedMonth
            .sink { [weak self] _ in
                self?.filterRecordsByMonth()
            }
            .store(in: &cancellables)
            
        // 订阅年份变化
        $selectedYear
            .sink { [weak self] _ in
                self?.filterRecordsByYear()
            }
            .store(in: &cancellables)
        
        // 初始筛选
        filterRecordsByMonth()
        filterRecordsByYear()
        
        // 异步加载模拟数据，避免在视图更新周期内修改状态
        DispatchQueue.main.async { [weak self] in
            self?.loadMockData()
            self?.calculateStats()
        }
    }
    
    // MARK: - 计算属性
    
    /// 总的美食打卡次数
    var totalFoodCheckInCount: Int {
        return appState.workoutRecords.count
    }
    
    /// 全年的美食打卡次数
    var yearlyFoodCheckInCount: Int {
        return yearlyFilteredWorkoutRecords.count
    }
    
    /// 全月的美食打卡次数 
    var monthlyFoodCheckInCount: Int {
        return filteredWorkoutRecords.count
    }
    
    /// 美食种类数量（月度）
    var monthlyUniqueDessertTypes: Int {
        return Set(filteredWorkoutRecords.map { $0.dessert.id }).count
    }
    
    /// 美食种类数量（年度）
    var yearlyUniqueDessertTypes: Int {
        return Set(yearlyFilteredWorkoutRecords.map { $0.dessert.id }).count
    }
    
    /// 所有美食种类数量
    var allUniqueDessertTypes: Int {
        return Set(appState.workoutRecords.map { $0.dessert.id }).count
    }
    
    /// 当前月份名称（中文）
    var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: selectedMonth)
    }
    
    /// 当前年份名称（中文）
    var currentYearName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年"
        return formatter.string(from: selectedYear)
    }
    
    /// 当月的总运动时长（分钟）
    var totalDurationThisMonth: Double {
        filteredWorkoutRecords.reduce(0) { $0 + $1.duration }
    }
    
    /// 当年的总运动时长（分钟）
    var totalDurationThisYear: Double {
        yearlyFilteredWorkoutRecords.reduce(0) { $0 + $1.duration }
    }
    
    /// 当月的总消耗卡路里
    var totalCaloriesThisMonth: Double {
        filteredWorkoutRecords.reduce(0) { $0 + $1.caloriesBurned }
    }
    
    /// 当年的总消耗卡路里
    var totalCaloriesThisYear: Double {
        yearlyFilteredWorkoutRecords.reduce(0) { $0 + $1.caloriesBurned }
    }
    
    /// 当月的运动次数
    var workoutCountThisMonth: Int {
        filteredWorkoutRecords.count
    }
    
    /// 当年的运动次数
    var workoutCountThisYear: Int {
        yearlyFilteredWorkoutRecords.count
    }
    
    /// 当年的总运动距离（米）
    var totalDistanceThisYear: Double {
        yearlyFilteredWorkoutRecords.reduce(0.0) { total, record in
            total + (record.distance ?? 0)
        }
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
    
    /// 切换到上一年
    func goToPreviousYear() {
        if let newDate = Calendar.current.date(byAdding: .year, value: -1, to: selectedYear) {
            selectedYear = newDate
        }
    }
    
    /// 切换到下一年
    func goToNextYear() {
        if let newDate = Calendar.current.date(byAdding: .year, value: 1, to: selectedYear) {
            selectedYear = newDate
        }
    }
    
    /// 设置当前月份
    func setMonth(_ date: Date) {
        selectedMonth = date
        showMonthPicker = false
    }
    
    /// 设置当前年份
    func setYear(_ date: Date) {
        selectedYear = date
    }
    
    /// 根据月份筛选记录
    private func filterRecordsByMonth() {
        let calendar = Calendar.current
        
        // 获取选中月份的年月组件
        let monthComponents = calendar.dateComponents([.year, .month], from: selectedMonth)
        
        // 筛选本月记录
        filteredWorkoutRecords = appState.workoutRecords.filter { record in
            // 获取记录的年月组件
            let recordComponents = calendar.dateComponents([.year, .month], from: record.completionDate)
            
            // 比较年月是否相同
            return recordComponents.year == monthComponents.year &&
                   recordComponents.month == monthComponents.month
        }
        
        // 计算统计数据
        calculateStats()
    }
    
    /// 根据年份筛选记录
    private func filterRecordsByYear() {
        let calendar = Calendar.current
        
        // 获取选中年份的年组件
        let yearComponents = calendar.dateComponents([.year], from: selectedYear)
        
        // 筛选本年记录
        yearlyFilteredWorkoutRecords = appState.workoutRecords.filter { record in
            // 获取记录的年组件
            let recordComponents = calendar.dateComponents([.year], from: record.completionDate)
            
            // 比较年是否相同
            return recordComponents.year == yearComponents.year
        }
    }
    
    /// 获取月度美食排行榜
    func getMonthlyTopDesserts(count: Int) -> [TopDessertItem]? {
        return getTopDessertsFromRecords(records: filteredWorkoutRecords, count: count)
    }
    
    /// 获取年度美食排行榜
    func getYearlyTopDesserts(count: Int) -> [TopDessertItem]? {
        return getTopDessertsFromRecords(records: yearlyFilteredWorkoutRecords, count: count)
    }
    
    /// 从记录中获取排名前几的美食
    private func getTopDessertsFromRecords(records: [WorkoutRecord], count: Int) -> [TopDessertItem]? {
        if records.isEmpty {
            return nil
        }
        
        // 统计每个甜品出现的次数和热量值
        var dessertInfo: [Int: (count: Int, calories: Double, name: String, imageName: String)] = [:]
        
        for record in records {
            let dessertId = record.dessert.id
            let calories = Double(record.dessert.calories) ?? 0
            
            if let existing = dessertInfo[dessertId] {
                dessertInfo[dessertId] = (
                    existing.count + 1,
                    existing.calories,
                    record.dessert.name,
                    record.dessert.imageName
                )
            } else {
                dessertInfo[dessertId] = (
                    1,
                    calories,
                    record.dessert.name,
                    record.dessert.imageName
                )
            }
        }
        
        // 按出现次数排序，次数相同时按照id大小排序（确保排行榜稳定性）
        let sortedDesserts = dessertInfo.sorted { 
            if $0.value.count == $1.value.count {
                // 次数相同时，按ID排序
                return $0.key < $1.key
            }
            // 按次数降序排序
            return $0.value.count > $1.value.count
        }
        
        // 返回前n个
        return sortedDesserts.prefix(count).map { entry in
            let (dessertId, info) = entry
            return TopDessertItem(
                id: String(dessertId),
                name: info.name,
                imageName: info.imageName,
                calories: info.calories,
                count: info.count,
                totalCalories: info.calories * Double(info.count)
            )
        }
    }
    
    /// 重置月份为当前月
    func resetToCurrentMonth() {
        selectedMonth = Date()
    }
    
    /// 重置年份为当前年
    func resetToCurrentYear() {
        selectedYear = Date()
    }
    
    /// 根据日期获取该日的记录
    func getRecordsForDate(_ date: Date) -> [WorkoutRecord] {
        let calendar = Calendar.current
        
        // 获取日期的年、月、日组件
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        return appState.workoutRecords.filter { record in
            // 获取记录日期的年、月、日组件
            let recordComponents = calendar.dateComponents([.year, .month, .day], from: record.completionDate)
            
            // 比较年、月、日是否相同
            return dateComponents.year == recordComponents.year &&
                   dateComponents.month == recordComponents.month &&
                   dateComponents.day == recordComponents.day
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
    
    // MARK: - 记录排序方法
    
    /// 获取按时间倒序排列的记录（月视图）
    func getSortedRecords() -> [WorkoutRecord] {
        return filteredWorkoutRecords.sorted { record1, record2 in
            // 比较时间戳，精确到秒级的倒序排列（最新的记录在前）
            return record1.completionDate.timeIntervalSince1970 > record2.completionDate.timeIntervalSince1970
        }
    }
    
    /// 获取按时间倒序排列的年度记录
    func getSortedYearlyRecords() -> [WorkoutRecord] {
        return yearlyFilteredWorkoutRecords.sorted { record1, record2 in
            // 比较时间戳，精确到秒级的倒序排列（最新的记录在前）
            return record1.completionDate.timeIntervalSince1970 > record2.completionDate.timeIntervalSince1970
        }
    }
    
    /// 获取按时间倒序排列的所有记录
    func getSortedAllRecords() -> [WorkoutRecord] {
        return appState.workoutRecords.sorted { record1, record2 in
            // 比较时间戳，精确到秒级的倒序排列（最新的记录在前）
            return record1.completionDate.timeIntervalSince1970 > record2.completionDate.timeIntervalSince1970
        }
    }
    
    /// 获取所有美食排行榜
    func getAllTopDesserts(count: Int) -> [TopDessertItem]? {
        return getTopDessertsFromRecords(records: appState.workoutRecords, count: count)
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
        
        // 创建固定日期 - 2025年3月和4月的特定日期
        var targetDates: [Date] = []
        
        // 指定2025年3月的日期
        for day in [5, 9, 15, 22, 28] {
            var components = DateComponents()
            components.year = 2025
            components.month = 3
            components.day = day
            if let date = calendar.date(from: components) {
                targetDates.append(date)
            }
        }
        
        // 指定2025年4月的日期
        for day in [3, 8, 12, 18, 24] {
            var components = DateComponents()
            components.year = 2025
            components.month = 4
            components.day = day
            if let date = calendar.date(from: components) {
                targetDates.append(date)
            }
        }
        
        // 获取样本甜品和运动类型
        let desserts = DessertData.getSampleDesserts()
        let exerciseTypes = ExerciseType.allCases
        
        // 创建10天的模拟数据，每天使用不同的甜品和运动类型
        var mockRecords: [WorkoutRecord] = []
        
        for (index, date) in targetDates.enumerated() {
            // 每天使用不同的甜品和运动类型
            let dessert = desserts[index % desserts.count]
            let exerciseType = exerciseTypes[index % exerciseTypes.count]
            
            // 运动时长 20-60分钟
            let duration = Double(30 + index * 3) // 递增时长
            
            // 消耗的卡路里
            let targetCalories = Double(dessert.calories) ?? 300
            let caloriesBurned = index % 3 == 0 ?
                targetCalories * 0.8 : // 未达成目标
                targetCalories * 1.2   // 达成目标
            
            // 创建记录
            let record = WorkoutRecord(
                dessert: dessert,
                exerciseType: exerciseType,
                completionDate: date,
                duration: duration,
                caloriesBurned: caloriesBurned
            )
            
            mockRecords.append(record)
        }
        
        // 保存模拟数据
        appState.workoutRecords = mockRecords
        
        // 筛选记录
        filterRecordsByMonth()
        filterRecordsByYear()
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
        
        // 获取月内所有不同的日期
        let daysInMonth = Set(filteredWorkoutRecords.map { 
            calendar.dateComponents([.year, .month, .day], from: $0.completionDate) 
        })
        
        // 对每个不同的日期进行处理
        for dayComponents in daysInMonth {
            // 如果能生成日期对象
            if let dayDate = calendar.date(from: dayComponents) {
                // 获取当天所有记录
                let dayRecords = getRecordsForDate(dayDate)
                
                // 计算当天热量差
                let dayBurned = dayRecords.reduce(0.0) { $0 + $1.caloriesBurned }
                let dayConsumed = dayRecords.reduce(0.0) { $0 + (Double($1.dessert.calories) ?? 0) }
                
                // 如果消耗大于等于摄入，认为当天减脂成功
                if dayBurned >= dayConsumed && dayConsumed > 0 {
                    deficitDaysSet.insert(dayComponents)
                }
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
        let weekRecords = appState.workoutRecords.filter { record in
            record.completionDate >= startOfWeek && record.completionDate < Date()
        }
        
        // 周度消耗和摄入
        weeklyConsumedCalories = weekRecords.reduce(0) { $0 + (Double($1.dessert.calories) ?? 0) }
        weeklyBurnedCalories = weekRecords.reduce(0) { $0 + $1.caloriesBurned }
        
        // 计算周度减脂天数
        var weeklyDeficitDatesSet = Set<DateComponents>()
        
        // 获取周内所有不同的日期
        let daysInWeek = Set(weekRecords.map { 
            calendar.dateComponents([.year, .month, .day], from: $0.completionDate) 
        })
        
        // 对每个不同的日期进行处理
        for dayComponents in daysInWeek {
            if let dayDate = calendar.date(from: dayComponents) {
                let dayRecords = getRecordsForDate(dayDate)
                
                let dayBurned = dayRecords.reduce(0.0) { $0 + $1.caloriesBurned }
                let dayConsumed = dayRecords.reduce(0.0) { $0 + (Double($1.dessert.calories) ?? 0) }
                
                if dayBurned >= dayConsumed && dayConsumed > 0 {
                    weeklyDeficitDatesSet.insert(dayComponents)
                }
            }
        }
        
        weeklyDeficitDays = weeklyDeficitDatesSet.count
    }
    
    // MARK: - 年份选择
    func incrementYear() {
        selectedYear = Calendar.current.date(byAdding: .year, value: 1, to: selectedYear) ?? selectedYear
    }
    
    func decrementYear() {
        selectedYear = Calendar.current.date(byAdding: .year, value: -1, to: selectedYear) ?? selectedYear
    }
    
    func resetYear() {
        selectedYear = Date()
    }
} 