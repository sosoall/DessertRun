import SwiftUI
import Combine
import Foundation

/// 运动记录视图模型 - 管理运动记录相关数据和逻辑
class ExerciseRecordViewModel: ObservableObject {
    // MARK: - 视图状态属性
    
    // 年月相关状态
    @Published var selectedMonth: Date = Date()
    @Published var selectedYear: Date = Date()
    @Published var showMonthPicker: Bool = false
    @Published var showYearPicker: Bool = false
    
    // 加载状态
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String? = nil
    
    // 分页加载相关状态
    @Published var currentPage: Int = 1
    @Published var pageSize: Int = 20
    @Published var hasMoreRecords: Bool = false
    @Published var totalRecordsCount: Int = 0
    
    // 记录和统计状态
    @Published var filteredWorkoutRecords: [WorkoutRecord] = []
    @Published var yearlyFilteredWorkoutRecords: [WorkoutRecord] = []
    
    // 日常统计数据存储
    @Published var dailyStatsMap: [DateComponents: APIWorkoutStatsResponse.DailyStatData] = [:]
    @Published var yearlyStatsMap: [DateComponents: Bool] = [:]
    
    // API数据统计
    @Published var monthlyWorkoutCount: Int = 0
    @Published var monthlyTotalDuration: Double = 0
    @Published var monthlyTotalCalories: Double = 0
    @Published var monthlyTotalDistance: Double = 0
    @Published var monthlyExerciseTypes: [String: APIWorkoutStatsResponse.ExerciseTypeStats] = [:]
    
    @Published var yearlyWorkoutCount: Int = 0
    @Published var yearlyTotalDuration: Double = 0
    @Published var yearlyTotalCalories: Double = 0
    @Published var yearlyTotalDistance: Double = 0
    @Published var yearlyExerciseTypes: [String: APIWorkoutStatsResponse.ExerciseTypeStats] = [:]
    
    // 其他辅助状态
    @Published var calorieDeficit: Int = 0
    @Published var weeklyDeficitDays: Int = 0
    private var weeklyDeficitDatesSet: Set<DateComponents> = []
    
    // MARK: - 依赖项
    private var appState: AppState
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    
    init(appState: AppState) {
        self.appState = appState
        
        // 初始化时同步月份和年份状态
        let currentDate = Date()
        selectedMonth = currentDate
        selectedYear = currentDate
        
        // 当应用状态中的运动记录更新时，重新筛选
        appState.$workoutRecords
            .sink { [weak self] _ in
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
    }
    
    // MARK: - 计算属性
    
    /// 当月的美食打卡次数 
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
        filteredWorkoutRecords.reduce(0) { $0 + ($1.duration ?? 0) }
    }
    
    /// 当年的总运动时长（分钟）
    var totalDurationThisYear: Double {
        yearlyFilteredWorkoutRecords.reduce(0) { $0 + ($1.duration ?? 0) }
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
    
    // MARK: - 月份和年份操作方法
    
    /// 切换到上个月
    func goToPreviousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newDate
            
            // 获取新选择的年份和月份
            let calendar = Calendar.current
            let year = calendar.component(.year, from: selectedMonth)
            let month = calendar.component(.month, from: selectedMonth)
            
            // 立即加载新月份的统计数据
            loadMonthStats(year: year, month: month)
        }
    }
    
    /// 切换到下个月
    func goToNextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = newDate
            
            // 获取新选择的年份和月份
            let calendar = Calendar.current
            let year = calendar.component(.year, from: selectedMonth)
            let month = calendar.component(.month, from: selectedMonth)
            
            // 立即加载新月份的统计数据
            loadMonthStats(year: year, month: month)
        }
    }
    
    /// 切换到上一年
    func goToPreviousYear() {
        if let newDate = Calendar.current.date(byAdding: .year, value: -1, to: selectedYear) {
            selectedYear = newDate
            
            // 获取新选择的年份
            let calendar = Calendar.current
            let year = calendar.component(.year, from: selectedYear)
            
            // 立即加载新年份的统计数据
            loadYearStats(year: year)
        }
    }
    
    /// 切换到下一年
    func goToNextYear() {
        if let newDate = Calendar.current.date(byAdding: .year, value: 1, to: selectedYear) {
            selectedYear = newDate
            
            // 获取新选择的年份
            let calendar = Calendar.current
            let year = calendar.component(.year, from: selectedYear)
            
            // 立即加载新年份的统计数据
            loadYearStats(year: year)
        }
    }
    
    /// 设置当前月份
    func setMonth(_ date: Date) {
        selectedMonth = date
        showMonthPicker = false
        
        // 获取选择的年份和月份
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedMonth)
        let month = calendar.component(.month, from: selectedMonth)
        
        // 加载选择月份的统计数据
        loadMonthStats(year: year, month: month)
    }
    
    /// 设置当前年份
    func setYear(_ date: Date) {
        selectedYear = date
        
        // 获取选择的年份
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedYear)
        
        // 加载选择年份的统计数据
        loadYearStats(year: year)
    }
    
    // MARK: - 记录筛选方法
    
    /// 根据月份筛选记录
    private func filterRecordsByMonth() {
        let calendar = Calendar.current
        
        // 获取选中月份的年月组件
        let monthComponents = calendar.dateComponents([.year, .month], from: selectedMonth)
        
        // 筛选本月记录
        filteredWorkoutRecords = appState.workoutRecords.filter { record in
            // 获取记录的年月组件
            let recordComponents = calendar.dateComponents([.year, .month], from: record.date)
            
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
            let recordComponents = calendar.dateComponents([.year], from: record.date)
            
            // 比较年是否相同
            return recordComponents.year == yearComponents.year
        }
    }
    
    // MARK: - 日期相关方法
    
    /// 重置月份为当前月
    func resetToCurrentMonth() {
        selectedMonth = Date()
        
        // 获取当前的年份和月份
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedMonth)
        let month = calendar.component(.month, from: selectedMonth)
        
        // 加载当前月份的统计数据
        loadMonthStats(year: year, month: month)
    }
    
    /// 重置年份为当前年
    func resetToCurrentYear() {
        selectedYear = Date()
        
        // 获取当前的年份
        let calendar = Calendar.current
        let year = calendar.component(.year, from: selectedYear)
        
        // 加载当前年份的统计数据
        loadYearStats(year: year)
    }
    
    /// 根据日期获取该日的记录
    func getRecordsForDate(_ date: Date) -> [WorkoutRecord] {
        let calendar = Calendar.current
        
        // 获取日期的年、月、日组件
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        return appState.workoutRecords.filter { record in
            // 获取记录日期的年、月、日组件
            let recordComponents = calendar.dateComponents([.year, .month, .day], from: record.date)
            
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
            return record1.date.timeIntervalSince1970 > record2.date.timeIntervalSince1970
        }
    }
    
    /// 获取按时间倒序排列的年度记录
    func getSortedYearlyRecords() -> [WorkoutRecord] {
        return yearlyFilteredWorkoutRecords.sorted { record1, record2 in
            // 比较时间戳，精确到秒级的倒序排列（最新的记录在前）
            return record1.date.timeIntervalSince1970 > record2.date.timeIntervalSince1970
        }
    }
    
    /// 获取按时间倒序排列的所有记录
    func getSortedAllRecords() -> [WorkoutRecord] {
        return appState.workoutRecords.sorted { record1, record2 in
            // 比较时间戳，精确到秒级的倒序排列（最新的记录在前）
            return record1.date.timeIntervalSince1970 > record2.date.timeIntervalSince1970
        }
    }
    
    // MARK: - 计算统计数据
    private func calculateStats() {
        let calendar = Calendar.current
        
        // 月度统计
        monthlyWorkoutCount = filteredWorkoutRecords.count
        monthlyTotalDuration = filteredWorkoutRecords.reduce(0) { $0 + ($1.duration ?? 0) }
        monthlyTotalCalories = filteredWorkoutRecords.reduce(0) { $0 + $1.caloriesBurned }
        
        // 计算月度减脂成功天数（每天消耗热量大于等于摄入热量）
        var deficitDaysSet = Set<DateComponents>()
        
        // 获取月内所有不同的日期
        let daysInMonth = Set(filteredWorkoutRecords.map { 
            calendar.dateComponents([.year, .month, .day], from: $0.date) 
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
        
        calorieDeficit = deficitDaysSet.count
        
        // 周度统计 - 获取本周日期范围
        let weekday = calendar.component(.weekday, from: Date())
        let daysFromStartOfWeek = weekday - 1 // 周日为1
        guard let startOfWeek = calendar.date(byAdding: .day, value: -daysFromStartOfWeek, to: Date()) else {
            return
        }
        
        // 筛选本周记录
        let weekRecords = appState.workoutRecords.filter { record in
            record.date >= startOfWeek && record.date < Date()
        }
        
        // 周度消耗和摄入
        // 未使用的变量已注释掉
        // let weeklyConsumedCalories = weekRecords.reduce(0) { $0 + (Double($1.dessert.calories) ?? 0) }
        // let weeklyBurnedCalories = weekRecords.reduce(0) { $0 + $1.caloriesBurned }
        
        // 计算周度减脂天数
        weeklyDeficitDatesSet = Set(weekRecords.map { 
            calendar.dateComponents([.year, .month, .day], from: $0.date) 
        })
        
        weeklyDeficitDays = weeklyDeficitDatesSet.count
    }
    
    // MARK: - 统计数据加载方法
    
    /// 加载月度统计数据
    func loadMonthStats(year: Int, month: Int) {
        DRDebug("[ExerciseRecordViewModel] 加载月度统计数据: \(year)年\(month)月")
        
        APIService.shared.getUserWorkoutStats(year: year, month: month)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        DRError("[ExerciseRecordViewModel] 加载月度统计失败: \(error.errorMessage)")
                    }
                },
                receiveValue: { [weak self] stats in
                    // 更新月度统计数据
                    self?.updateMonthlyStatsFromAPI(stats: stats.data)
                }
            )
            .store(in: &cancellables)
    }
    
    /// 加载年度统计数据
    func loadYearStats(year: Int) {
        DRDebug("[ExerciseRecordViewModel] 加载年度统计数据: \(year)年")
        
        APIService.shared.getUserWorkoutStats(year: year)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        DRError("[ExerciseRecordViewModel] 加载年度统计失败: \(error.errorMessage)")
                    }
                },
                receiveValue: { [weak self] stats in
                    // 更新年度统计数据
                    self?.updateYearlyStatsFromAPI(stats: stats.data)
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - 数据加载方法
    
    /// 加载运动记录数据
    func loadData() {
        if isLoading {
            // 已经在加载中，忽略重复请求
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // 重置分页状态
        currentPage = 1
        hasMoreRecords = false  // 默认设置为false，直到确认有更多数据
        
        // 获取当前选择的年份和月份
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())
        
        // 确保月份和年份使用当前日期
        selectedMonth = Date()
        selectedYear = Date()
        
        // 仅加载统计数据，不加载详细记录
        self.loadMonthStats(year: currentYear, month: currentMonth)
        self.loadYearStats(year: currentYear)
        
        // 完成加载
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
    
    /// 更新月度统计数据
    private func updateMonthlyStatsFromAPI(stats: APIWorkoutStatsResponse.WorkoutStatsData) {
        // 更新月度统计数据属性
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.monthlyWorkoutCount = stats.workoutDays
            self.monthlyTotalDuration = stats.totalDuration
            self.monthlyTotalCalories = stats.totalCalories
            self.monthlyTotalDistance = stats.totalDistance
            self.monthlyExerciseTypes = stats.exerciseTypes
            
            // 处理每日统计数据
            self.processDailyStats(stats.dailyStats)
            
            DRInfo("[统计] 已更新月度统计 - 打卡天数:\(self.monthlyWorkoutCount)")
        }
    }
    
    /// 更新年度统计数据
    private func updateYearlyStatsFromAPI(stats: APIWorkoutStatsResponse.WorkoutStatsData) {
        // 仅记录总打卡天数
        DRInfo("[统计] API返回的年度统计: 打卡天数=\(stats.workoutDays)")
        
        // 更新年度统计数据属性
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.yearlyWorkoutCount = stats.workoutDays
            self.yearlyTotalDuration = stats.totalDuration
            self.yearlyTotalCalories = stats.totalCalories
            self.yearlyTotalDistance = stats.totalDistance
            self.yearlyExerciseTypes = stats.exerciseTypes
            
            // 处理每日统计数据（年度视图）
            self.processYearlyDailyStats(stats.dailyStats)
        }
    }
    
    /// 处理每日统计数据（月视图用）
    private func processDailyStats(_ dailyStats: [APIWorkoutStatsResponse.DailyStatData]) {
        // 按日期存储每日统计数据，用于月视图
        var dailyStatsMap = [DateComponents: APIWorkoutStatsResponse.DailyStatData]()
        let calendar = Calendar.current
        
        for stat in dailyStats {
            if let date = stat.date.toDate() {
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                dailyStatsMap[dateComponents] = stat
            }
        }
        
        // 保存到实例变量，供视图使用
        self.dailyStatsMap = dailyStatsMap
    }
    
    /// 处理每日统计数据（年视图用）
    private func processYearlyDailyStats(_ dailyStats: [APIWorkoutStatsResponse.DailyStatData]) {
        // 按日期存储每日统计数据，用于年视图
        var yearlyStatsMap = [DateComponents: Bool]()
        let calendar = Calendar.current
        
        for stat in dailyStats {
            if let date = stat.date.toDate() {
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                
                // 只在hasWorkout为true时才添加到yearlyStatsMap
                if stat.hasWorkout {
                    yearlyStatsMap[dateComponents] = true
                }
            }
        }
        
        // 保存到实例变量，供年视图使用
        self.yearlyStatsMap = yearlyStatsMap
        
        // 记录有运动记录的日期数
        let hasWorkoutCount = dailyStats.filter { $0.hasWorkout }.count
        DRInfo("[统计] 年度有运动记录的日期数: \(hasWorkoutCount)")
    }
    
    /// 加载更多记录
    func loadMoreRecords() {
        guard hasMoreRecords && !isLoadingMore && !isLoading else { return }
        
        isLoadingMore = true
        
        let nextPage = currentPage + 1
        
        APIService.shared.getUserWorkoutRecordsWithTotal(page: nextPage, limit: pageSize)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingMore = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorMessage
                        DRError("[ExerciseRecordViewModel] 加载更多运动记录失败: \(error.errorMessage)")
                    }
                },
                receiveValue: { [weak self] result in
                    guard let self = self else { return }
                    
                    self.isLoadingMore = false
                    
                    let (records, total) = result
                    
                    // 更新总记录数
                    self.totalRecordsCount = total
                    
                    if records.isEmpty {
                        self.hasMoreRecords = false
                    } else {
                        // 更新当前页码
                        self.currentPage = nextPage
                        
                        // 将新记录添加到现有记录中
                        DispatchQueue.main.async {
                            // 避免重复记录
                            // 只检查现有ID，不需要新记录的ID集合
                            let existingRecordIds = Set(self.appState.workoutRecords.map { $0.id })
                            
                            // 只添加不存在的记录
                            let uniqueNewRecords = records.filter { !existingRecordIds.contains($0.id) }
                            
                            if uniqueNewRecords.count > 0 {
                                self.appState.workoutRecords.append(contentsOf: uniqueNewRecords)
                                
                                DRInfo("[ExerciseRecordViewModel] 加载了\(uniqueNewRecords.count)条新记录")
                            }
                        }
                        
                        // 计算已加载的总记录数
                        let loadedRecordsCount = self.appState.workoutRecords.count
                        
                        // 根据总记录数判断是否还有更多
                        self.hasMoreRecords = loadedRecordsCount < total
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // 格式化总距离（公里）
    func formatTotalDistance(meters: Double) -> String {
        return String(format: "%.1f", meters / 1000.0)
    }
}

// MARK: - String扩展，用于日期转换
extension String {
    func toDate(format: String = "yyyy-MM-dd") -> Date? {
        // 首先尝试用ISO 8601格式解析（包含微秒和时区）
        if self.contains("T") && (self.contains("+") || self.contains("Z")) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: self) {
                return date
            }
            
            // 如果带微秒的解析失败，尝试不带微秒的格式
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: self) {
                return date
            }
            
            // 最后的备选方案：手动截取并解析
            // 比如将"2025-05-20T19:59:39.284951+08:00"截取为"2025-05-20T19:59:39"
            if let endIndex = self.firstIndex(of: ".") {
                let truncated = String(self[..<endIndex])
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                
                // 创建日期时设置时区为UTC
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                if let date = dateFormatter.date(from: truncated) {
                    return date
                }
                
                // 尝试再截取时区部分，处理"2025-05-20T19:59:39.284951+08:00"格式
                if let plusIndex = self.firstIndex(of: "+"), let dotIndex = self.firstIndex(of: ".") {
                    let baseDate = String(self[..<dotIndex])
                    let timezone = String(self[plusIndex...])
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    
                    // 组合日期和时区
                    let fullDateString = baseDate + timezone
                    return dateFormatter.date(from: fullDateString)
                }
            }
        }
        
        // 默认格式解析（如普通日期"2025-05-20"）
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: self)
    }
} 