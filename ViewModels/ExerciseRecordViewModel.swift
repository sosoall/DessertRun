import SwiftUI
import Combine
import Foundation

/// 运动记录视图模型 - 管理运动记录相关数据和逻辑
class ExerciseRecordViewModel: ObservableObject {
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
    
    // 添加热量平衡统计属性
    @Published var monthlyClearedDesserts: Int = 0
    @Published var monthlyDeficitDays: Int = 0
    @Published var weeklyDeficitDays: Int = 0
    
    @Published var monthlyConsumedCalories: Double = 0
    @Published var monthlyBurnedCalories: Double = 0
    @Published var weeklyConsumedCalories: Double = 0
    @Published var weeklyBurnedCalories: Double = 0
    
    // MARK: - 选择的日期
    @Published var selectedDay: Date = Date()
    
    /// 加载状态
    @Published var isLoading: Bool = false
    
    /// 错误信息
    @Published var errorMessage: String? = nil
    
    // MARK: - 分页支持
    /// 当前页码
    @Published var currentPage: Int = 1
    
    /// 每页记录数量
    private let pageSize: Int = 20
    
    /// 是否有更多记录可加载
    @Published var hasMoreRecords: Bool = true
    
    /// 总记录数
    @Published var totalRecordsCount: Int = 0
    
    /// 是否正在加载更多
    @Published var isLoadingMore: Bool = false
    
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
        monthlyClearedDesserts = Set(filteredWorkoutRecords.map { $0.dessert.id }).count
        monthlyConsumedCalories = filteredWorkoutRecords.reduce(0) { $0 + (Double($1.dessert.calories) ?? 0) }
        monthlyBurnedCalories = filteredWorkoutRecords.reduce(0) { $0 + $1.caloriesBurned }
        
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
        
        monthlyDeficitDays = deficitDaysSet.count
        
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
        weeklyConsumedCalories = weekRecords.reduce(0) { $0 + (Double($1.dessert.calories) ?? 0) }
        weeklyBurnedCalories = weekRecords.reduce(0) { $0 + $1.caloriesBurned }
        
        // 计算周度减脂天数
        var weeklyDeficitDatesSet = Set<DateComponents>()
        
        // 获取周内所有不同的日期
        let daysInWeek = Set(weekRecords.map { 
            calendar.dateComponents([.year, .month, .day], from: $0.date) 
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
    
    // MARK: - 数据加载方法
    
    /// 加载运动记录数据
    func loadData() {
        if isLoading {
            DRDebug("[ExerciseRecordViewModel] 正在加载中，忽略重复请求")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // 重置分页状态
        currentPage = 1
        hasMoreRecords = false  // 默认设置为false，直到确认有更多数据
        
        DRDebug("[ExerciseRecordViewModel] 开始加载运动记录，页码: \(currentPage)，每页数量: \(pageSize)")
        
        // 使用可以获取总记录数的API方法
        APIService.shared.getUserWorkoutRecordsWithTotal(page: currentPage, limit: pageSize)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorMessage
                        DRError("[ExerciseRecordViewModel] 加载运动记录失败: \(error.errorMessage)")
                    }
                },
                receiveValue: { [weak self] result in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    let (records, total) = result
                    
                    // 更新总记录数
                    self.totalRecordsCount = total
                    
                    // 更新应用状态中的记录列表
                    DispatchQueue.main.async {
                        self.appState.workoutRecords = records
                        DRInfo("[ExerciseRecordViewModel] 成功加载\(records.count)条运动记录，总数: \(total)")
                        
                        // 根据总记录数和当前加载的记录数判断是否还有更多记录
                        // 只有当已加载的记录数小于总记录数时，才设置hasMoreRecords为true
                        let recordsLoaded = records.count
                        self.hasMoreRecords = recordsLoaded < total
                        
                        DRDebug("[ExerciseRecordViewModel] 当前加载: \(recordsLoaded), 总记录数: \(total), 是否有更多: \(self.hasMoreRecords)")
                        
                        // 更新筛选后的记录
                        self.filterRecordsByMonth()
                        self.filterRecordsByYear()
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 加载更多记录
    func loadMoreRecords() {
        guard hasMoreRecords && !isLoadingMore && !isLoading else { return }
        
        isLoadingMore = true
        
        let nextPage = currentPage + 1
        
        // 添加调试日志
        DRDebug("[ExerciseRecordViewModel] 正在加载更多记录，页码: \(nextPage)，每页数量: \(pageSize)")
        
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
                        DRDebug("[ExerciseRecordViewModel] 没有更多记录可加载")
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
                                // 更新过滤后的记录
                                self.filterRecordsByMonth()
                                self.filterRecordsByYear()
                                
                                DRInfo("[ExerciseRecordViewModel] 成功加载额外\(uniqueNewRecords.count)条运动记录，总数: \(total)")
                            } else {
                                DRDebug("[ExerciseRecordViewModel] 没有新的唯一记录可添加")
                            }
                        }
                        
                        // 计算已加载的总记录数
                        let loadedRecordsCount = self.appState.workoutRecords.count
                        
                        // 根据总记录数判断是否还有更多
                        self.hasMoreRecords = loadedRecordsCount < total
                        
                        DRDebug("[ExerciseRecordViewModel] 已加载记录数: \(loadedRecordsCount), 总记录数: \(total), 是否有更多: \(self.hasMoreRecords)")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // 格式化总距离
    func formatTotalDistance() -> String {
        // 从月度记录中计算总距离
        let totalMeters = filteredWorkoutRecords.reduce(0.0) { total, record in
            total + (record.distance ?? 0)
        }
        return String(format: "%.1f", totalMeters / 1000.0)
    }
} 