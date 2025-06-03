import SwiftUI
import Combine
import Foundation

/// 这个功能暂时不用了，但是先别删除，不知道有没有其他地方用到了
/// 美食统计排行项
struct StatTopDessertItem: Identifiable {
    /// ID
    let id: String
    
    /// 名称
    let name: String
    
    /// 图像名称
    let imageName: String
    
    /// 卡路里
    let calories: Double
    
    /// 数量
    let count: Int
    
    /// 总卡路里
    let totalCalories: Double
    
    /// 甜品ID
    let dessertId: String
}

/// 美食打卡视图模型 - 管理美食打卡相关数据和逻辑
class FoodCheckInViewModel: ObservableObject {
    // MARK: - 单例模式
    
    /// 全局共享实例
    static let shared = FoodCheckInViewModel(appState: AppState.shared)
    
    // 私有静态引用，确保只有一个实例
    private static var _shared: FoodCheckInViewModel?
    
    // MARK: - 发布属性
    
    /// 美食券加载状态
    @Published var isLoadingVouchers: Bool = false
    
    /// 排行榜加载状态
    @Published var isLoadingTopDesserts: Bool = false
    
    /// 排行榜数据
    @Published var topDesserts: [StatTopDessertItem] = []
    
    /// 错误信息
    @Published var errorMessage: String? = nil
    
    /// 排行榜是否无数据
    @Published var hasNoTopDessertData: Bool = false
    
    /// 全局状态引用
    private var appState: AppState
    
    /// 发布者集合
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 加载更多记录
    var hasMoreRecords: Bool = false
    var isLoadingMore: Bool = false
    var currentPage: Int = 1
    private let pageSize: Int = 20
    var totalRecordsCount: Int = 0
    
    // 添加美食券分页相关属性
    var hasMoreVouchers: Bool = false
    var isLoadingMoreVouchers: Bool = false
    var currentVoucherPage: Int = 1
    var totalVouchersCount: Int = 0
    // 添加标记，明确确认没有更多美食券数据
    var noMoreVouchersConfirmed: Bool = false
    
    /// 当前排行榜对应的用户ID（用于账号切换时刷新）
    private var currentUserUUID: UUID? = nil
    
    // MARK: - 初始化方法
    
    /// 初始化
    init(appState: AppState) {
        // 确保只创建一个实例
        if Self._shared != nil {
            self.appState = appState
            DRDebug("[FoodCheckInViewModel] 使用现有实例: \(Unmanaged.passUnretained(Self._shared!).toOpaque())")
            return
        }
        
        self.appState = appState
        Self._shared = self
        DRDebug("[FoodCheckInViewModel] 创建新实例: \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    // MARK: - 计算属性
    
    /// 总的美食打卡次数
    var totalFoodCheckInCount: Int {
        return appState.workoutRecords.count
    }
    
    /// 美食种类数量
    var allUniqueDessertTypes: Int {
        return Set(appState.workoutRecords.map { $0.dessert.id }).count
    }
    
    // MARK: - 从API加载美食券
    func loadDessertVouchers(status: String? = nil) {
        // 添加加载状态标记，防止重复请求
        if isLoadingVouchers {
            DRDebug("[FoodCheckInViewModel] 正在加载美食券，忽略重复请求")
            return
        }
        
        isLoadingVouchers = true
        DRDebug("[FoodCheckInViewModel] 开始加载美食券数据")
        
        // 使用与API定义一致的参数，将limit改为20，与getUserVouchers方法默认值匹配
        APIService.shared.getUserVouchers(status: status, page: 1, limit: 20)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingVouchers = false
                    if case .failure(let error) = completion {
                        DRError("[FoodCheckInViewModel] 加载美食券失败: \(error.errorMessage)")
                        self?.errorMessage = error.errorMessage
                    }
                },
                receiveValue: { [weak self] vouchers in
                    guard let self = self else { return }
                    self.isLoadingVouchers = false
                    DRDebug("[FoodCheckInViewModel] 成功接收美食券数据，数量: \(vouchers.count)")
                    
                    // 打印一些美食券样本，帮助调试日期问题
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    
                    for (index, voucher) in vouchers.prefix(3).enumerated() {
                        let createdAt = dateFormatter.string(from: voucher.createdAt)
                        let expireAt = voucher.expireAt != nil ? dateFormatter.string(from: voucher.expireAt!) : "nil"
                        
                        DRDebug("[FoodCheckInViewModel] 美食券[\(index)]: id=\(voucher.id), createdAt=\(createdAt), expireAt=\(expireAt), recordId=\(voucher.workoutRecordId ?? "nil")")
                    }
                    
                    // 更新应用状态中的美食券列表
                    DispatchQueue.main.async {
                        // 避免不必要的状态更新，只在数据真正变化时更新
                        let hasChanges = self.hasVoucherChanges(newVouchers: vouchers)
                        
                        if hasChanges {
                            DRDebug("[FoodCheckInViewModel] 检测到美食券数据变化，更新状态")
                            self.appState.dessertVouchers = vouchers
                            DRInfo("[FoodCheckInViewModel] 成功加载\(vouchers.count)张美食券")
                            
                            // 强制刷新视图
                            NotificationCenter.default.post(name: NSNotification.Name("VouchersUpdated"), object: nil)
                        } else {
                            DRDebug("[FoodCheckInViewModel] 美食券数据未变化，跳过更新")
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - 从API加载美食排行榜
    func loadTopDesserts(limit: Int = 5, force: Bool = false) {
        // 检查当前用户是否变化
        let userUUID = AuthService.shared.currentUser?.id
        if currentUserUUID != userUUID {
            DRInfo("[FoodCheckInViewModel] 检测到账户切换，重置排行榜数据")
            currentUserUUID = userUUID
            topDesserts = []
        }
        
        // 防止重复加载，除非force为true
        if isLoadingTopDesserts {
            if force == false {
                DRDebug("[FoodCheckInViewModel] 正在加载美食排行榜，忽略重复请求")
                return
            }
        }
        
        isLoadingTopDesserts = true
        DRDebug("[FoodCheckInViewModel] 开始从后端加载美食排行榜数据，ViewModel实例: \(Unmanaged.passUnretained(self).toOpaque())")
        
        // 保留当前数据，仅在成功加载新数据时替换，减少UI闪烁
        let currentTopDesserts = self.topDesserts
        
        APIService.shared.getUserTopDesserts(limit: limit)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoadingTopDesserts = false
                        if case .failure(let error) = completion {
                            DRError("[FoodCheckInViewModel] 加载美食排行榜失败: \(error.errorMessage)")
                            
                            // 判断是否为令牌过期错误
                            if case .tokenExpired = error {
                                self?.errorMessage = "登录已过期，请重新登录"
                                // 令牌过期错误已在APIService中处理，不需要额外处理
                            } else {
                                self?.errorMessage = "加载排行榜失败：\(error.errorMessage)"
                                
                                // 添加是否无数据的状态
                                self?.hasNoTopDessertData = true
                            }
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    DRDebug("[FoodCheckInViewModel] 收到排行榜API响应，ViewModel实例: \(Unmanaged.passUnretained(self).toOpaque())")
                    
                    if response.code == 0 || response.code == 200 {
                        let items = response.data.items.map { item in
                            StatTopDessertItem(
                                id: item.dessertId.uuidString,
                                name: item.dessertName,
                                imageName: item.imageURL,
                                calories: item.calories,
                                count: item.checkinCount,
                                totalCalories: item.totalCalories,
                                dessertId: item.dessertId.uuidString
                            )
                        }
                        
                        // 确保在主线程更新UI绑定的数据
                        DispatchQueue.main.async { [self] in
                            DRDebug("[FoodCheckInViewModel] 准备更新排行榜数据，项目数: \(items.count)，ViewModel实例: \(Unmanaged.passUnretained(self).toOpaque())")
                            
                            // 重置加载状态
                            self.isLoadingTopDesserts = false
                            
                            // 检查是否有数据
                            if items.isEmpty {
                                DRInfo("[FoodCheckInViewModel] 排行榜无数据")
                                self.hasNoTopDessertData = true
                                self.errorMessage = "暂无排行榜数据"
                            } else {
                                // 直接设置数据
                                self.topDesserts = items
                                self.hasNoTopDessertData = false
                                self.errorMessage = nil
                                
                                DRInfo("[FoodCheckInViewModel] 成功加载\(items.count)个排行榜项")
                                
                                if !self.topDesserts.isEmpty {
                                    DRDebug("[FoodCheckInViewModel] 更新后排行榜数据内容: \(self.topDesserts.map { $0.name })")
                                }
                                
                                // 仅当数据真正变化时才发送通知，减少UI刷新
                                if !self.areTopDessertsEqual(currentTopDesserts, items) {
                                    self.sendTopDessertsUpdatedNotification()
                                
                                    // 仅预加载排行榜相关图片，不触发其他加载
                                    self.preloadTopDessertImages(items)
                                } else {
                                    DRDebug("[FoodCheckInViewModel] 排行榜数据未变化，跳过通知")
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            // 重置加载状态
                            self.isLoadingTopDesserts = false
                            self.hasNoTopDessertData = true
                            
                            DRError("[FoodCheckInViewModel] 加载美食排行榜失败: \(response.message)")
                            self.errorMessage = "加载排行榜失败：\(response.message)"
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 比较两个排行榜数据集是否相同
    private func areTopDessertsEqual(_ old: [StatTopDessertItem], _ new: [StatTopDessertItem]) -> Bool {
        guard old.count == new.count else { return false }
        
        for i in 0..<old.count {
            if old[i].id != new[i].id || old[i].count != new[i].count {
                return false
            }
        }
        
        return true
    }
    
    /// 仅预加载排行榜图片，不触发其他加载
    private func preloadTopDessertImages(_ items: [StatTopDessertItem]) {
        let imageUrls = items.compactMap { item -> String? in
            guard !item.imageName.isEmpty else { return nil }
            return item.imageName
        }
        
        if !imageUrls.isEmpty {
            DRDebug("[FoodCheckInViewModel] 开始预加载\(imageUrls.count)张排行榜图片")
            ImageCacheService.shared.prefetchImages(urls: imageUrls) { loaded, total in
                if loaded == total {
                    DRDebug("[FoodCheckInViewModel] 排行榜图片预加载完成，\(loaded)/\(total)")
                    // 发送特定的排行榜图片加载完成通知
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("RankingImagesLoaded"),
                            object: nil
                        )
                    }
                }
            }
        }
    }
    
    /// 发送排行榜更新通知
    private func sendTopDessertsUpdatedNotification() {
        NotificationCenter.default.post(
            name: NSNotification.Name("TopDessertsUpdated"),
            object: nil,
            userInfo: ["viewModel": self, "items": self.topDesserts]
        )
        DRDebug("[FoodCheckInViewModel] 已发送排行榜更新通知，实例: \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    /// 获取按时间倒序排列的所有记录
    func getSortedAllRecords() -> [WorkoutRecord] {
        return appState.workoutRecords.sorted { record1, record2 in
            // 比较时间戳，精确到秒级的倒序排列（最新的记录在前）
            return record1.date.timeIntervalSince1970 > record2.date.timeIntervalSince1970
        }
    }
    
    /// 加载更多记录
    func loadMoreRecords() {
        // 检查是否正在加载
        if isLoadingMore {
            DRDebug("[FoodCheckInViewModel] 正在加载中，忽略重复请求")
            return
        }
        
        guard hasMoreRecords && !isLoadingMore else { return }
        
        isLoadingMore = true
        
        let nextPage = currentPage + 1
        
        // 添加调试日志
        DRDebug("[FoodCheckInViewModel] 正在加载更多记录，页码: \(nextPage)，每页数量: \(pageSize)")
        
        APIService.shared.getUserWorkoutRecordsWithTotal(page: nextPage, limit: pageSize)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingMore = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorMessage
                        DRError("[FoodCheckInViewModel] 加载更多美食记录失败: \(error.errorMessage)")
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
                        DRDebug("[FoodCheckInViewModel] 没有更多记录可加载")
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
                                
                                DRInfo("[FoodCheckInViewModel] 成功加载额外\(uniqueNewRecords.count)条美食记录，总数: \(total)")
                            } else {
                                DRDebug("[FoodCheckInViewModel] 没有新的唯一记录可添加")
                            }
                        }
                        
                        // 计算已加载的总记录数
                        let loadedRecordsCount = self.appState.workoutRecords.count
                        
                        // 根据总记录数判断是否还有更多
                        self.hasMoreRecords = loadedRecordsCount < total
                        
                        DRDebug("[FoodCheckInViewModel] 已加载记录数: \(loadedRecordsCount), 总记录数: \(total), 是否有更多: \(self.hasMoreRecords)")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 加载首页数据
    func loadData() {
        // 检查是否正在加载
        if isLoadingVouchers {
            DRDebug("[FoodCheckInViewModel] 正在加载中，忽略重复请求")
            return
        }
        
        // 重置分页信息
        currentVoucherPage = 1
        hasMoreVouchers = false
        
        // 简化加载逻辑：只加载美食券数据和排行榜
        // 1. 加载美食券数据，它现在包含足够的展示信息
        loadVouchersIndependently(forceRefresh: true)
        
        // 2. 单独加载排行榜，不触发其他加载
        loadTopDessertsIndependently(limit: 5) 
    }
    
    /// 单独加载运动记录
    func loadWorkoutRecordsIndependently(forceRefresh: Bool = false) {
        guard !isLoadingMore else {
            DRDebug("[FoodCheckInViewModel] 上一个打卡记录请求仍在进行中，跳过")
            return
        }
        
        isLoadingMore = true
        
        DRDebug("[FoodCheckInViewModel] 独立加载美食记录，页码: \(currentPage)，每页数量: \(pageSize)")
        
        APIService.shared.getUserWorkoutRecordsWithTotal(page: currentPage, limit: pageSize)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoadingMore = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.errorMessage
                        DRError("[FoodCheckInViewModel] 加载美食记录失败: \(error.errorMessage)")
                    }
                },
                receiveValue: { [weak self] result in
                    guard let self = self else { return }
                    
                    let (records, total) = result
                    
                    // 更新总记录数
                    self.totalRecordsCount = total
                    
                    // 更新应用状态中的记录列表
                    DispatchQueue.main.async {
                        self.appState.workoutRecords = records
                        DRInfo("[FoodCheckInViewModel] 成功加载\(records.count)条美食记录，总数: \(total)")
                        
                        // 根据总记录数和当前加载的记录数判断是否还有更多记录
                        let recordsLoaded = records.count
                        self.hasMoreRecords = recordsLoaded < total
                        
                        DRDebug("[FoodCheckInViewModel] 当前加载: \(recordsLoaded), 总记录数: \(total), 是否有更多: \(self.hasMoreRecords)")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 单独加载排行榜
    func loadTopDessertsIndependently(limit: Int, forceRefresh: Bool = false) {
        guard !isLoadingTopDesserts else {
            DRDebug("[FoodCheckInViewModel] 上一个排行榜请求仍在进行中，跳过")
            return
        }
        
        isLoadingTopDesserts = true
        
        DRDebug("[FoodCheckInViewModel] 开始单独加载排行榜数据")
        
        // 强制清空旧数据，确保发布更新
        if !topDesserts.isEmpty {
            DRDebug("[FoodCheckInViewModel] 加载前清空旧数据，原有 \(topDesserts.count) 条")
            DispatchQueue.main.async {
                self.topDesserts = []
            }
        }
        
        APIService.shared.getUserTopDesserts(limit: limit)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoadingTopDesserts = false
                        if case .failure(let error) = completion {
                            DRError("[FoodCheckInViewModel] 加载美食排行榜失败: \(error.errorMessage)")
                            
                            // 判断是否为令牌过期错误
                            if case .tokenExpired = error {
                                self?.errorMessage = "登录已过期，请重新登录"
                            } else {
                                self?.errorMessage = "加载排行榜失败：\(error.errorMessage)"
                                self?.hasNoTopDessertData = true
                            }
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    DRDebug("[FoodCheckInViewModel] 收到排行榜API响应")
                    
                    if response.code == 0 || response.code == 200 {
                        let items = response.data.items.map { item in
                            StatTopDessertItem(
                                id: item.dessertId.uuidString,
                                name: item.dessertName,
                                imageName: item.imageURL,
                                calories: item.calories,
                                count: item.checkinCount,
                                totalCalories: item.totalCalories,
                                dessertId: item.dessertId.uuidString
                            )
                        }
                        
                        // 确保在主线程更新UI绑定的数据
                        DispatchQueue.main.async { [self] in
                            // 重置加载状态
                            self.isLoadingTopDesserts = false
                            
                            // 检查是否有数据
                            if items.isEmpty {
                                DRInfo("[FoodCheckInViewModel] 排行榜无数据")
                                self.hasNoTopDessertData = true
                                self.errorMessage = "暂无排行榜数据"
                            } else {
                                // 直接设置数据
                                self.topDesserts = items
                                self.hasNoTopDessertData = false
                                self.errorMessage = nil
                                
                                DRInfo("[FoodCheckInViewModel] 成功加载\(items.count)个排行榜项")
                                
                                // 单次发送通知，避免UI闪烁
                                self.sendTopDessertsUpdatedNotification()
                                
                                // 简化预加载逻辑，只发出通知
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("AllRankingImagesLoaded"),
                                        object: nil,
                                        userInfo: ["viewModel": self]
                                    )
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            // 重置加载状态
                            self.isLoadingTopDesserts = false
                            self.hasNoTopDessertData = true
                            
                            DRError("[FoodCheckInViewModel] 加载美食排行榜失败: \(response.message)")
                            self.errorMessage = "加载排行榜失败：\(response.message)"
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 加载更多美食券
    func loadMoreVouchers() {
        // 修改检查条件 - 只要不在加载中就可以尝试加载更多
        guard !isLoadingMoreVouchers && !isLoadingVouchers else {
            DRDebug("[FoodCheckInViewModel] 加载条件不满足，跳过加载更多美食券: isLoadingMoreVouchers=\(isLoadingMoreVouchers), isLoadingVouchers=\(isLoadingVouchers)")
            return
        }
        
        // 如果已明确确认没有更多记录，则不再尝试加载
        if noMoreVouchersConfirmed {
            DRInfo("[FoodCheckInViewModel] 已明确确认没有更多记录，不再尝试加载")
            return
        }
        
        // 设置加载状态
        isLoadingMoreVouchers = true
        
        // 增加页码
        currentVoucherPage += 1
        
        DRInfo("[FoodCheckInViewModel] 加载更多美食券, 页码: \(currentVoucherPage), 当前已加载: \(AppState.shared.dessertVouchers.count), 总数: \(totalVouchersCount)")
        
        // 调用独立加载方法 - 不要在这里重置状态，而是在loadVouchersIndependently完成后重置
        loadVouchersIndependently(forceRefresh: false)
    }
    
    /// 独立加载美食券
    func loadVouchersIndependently(forceRefresh: Bool = false) {
        guard !isLoadingVouchers else {
            DRDebug("[FoodCheckInViewModel] 上一个美食券请求仍在进行中，跳过")
            return
        }
        
        isLoadingVouchers = true
        // 重置分页状态
        if forceRefresh {
            currentVoucherPage = 1
        }
        DRInfo("[FoodCheckInViewModel] 开始加载美食券数据, 页码: \(currentVoucherPage)")
        
        APIService.shared.getUserVouchersWithImages(status: "", page: currentVoucherPage, limit: pageSize)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoadingVouchers = false
                    // 在请求完成后，不管成功失败，都重置加载更多状态
                    self.isLoadingMoreVouchers = false
                    
                    if case .failure(let error) = completion {
                        DRError("[FoodCheckInViewModel] 加载美食券失败: \(error.errorMessage)")
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    // 记录总数和更新分页状态
                    self.totalVouchersCount = response.total
                    
                    // 当前已加载的美食券数量
                    let currentLoaded = (self.currentVoucherPage == 1) ? 
                        0 : AppState.shared.dessertVouchers.count
                    
                    // 修正判断逻辑：确保加载更多按钮显示
                    let currentPageTotal = currentLoaded + response.vouchers.count
                    self.hasMoreVouchers = currentPageTotal < response.total
                    
                    // 更新没有更多记录的确认标记
                    self.noMoreVouchersConfirmed = !self.hasMoreVouchers
                    
                    DRInfo("[FoodCheckInViewModel] 美食券分页信息: 当前总数=\(currentPageTotal), API返回总数=\(response.total), 当前页=\(response.page), 是否有更多=\(self.hasMoreVouchers), 确认无更多=\(self.noMoreVouchersConfirmed)")
                    
                    // 区分第一页和加载更多的情况
                    if self.currentVoucherPage == 1 {
                        // 第一页，直接替换数据
                        AppState.shared.dessertVouchers = response.vouchers
                    } else {
                        // 加载更多，追加数据，避免重复
                        let existingIds = Set(AppState.shared.dessertVouchers.map { $0.id })
                        let uniqueNewVouchers = response.vouchers.filter { !existingIds.contains($0.id) }
                        
                        if !uniqueNewVouchers.isEmpty {
                            AppState.shared.dessertVouchers.append(contentsOf: uniqueNewVouchers)
                            DRDebug("[FoodCheckInViewModel] 添加了\(uniqueNewVouchers.count)个新的美食券")
                        } else {
                            DRDebug("[FoodCheckInViewModel] 没有新的美食券需要添加")
                        }
                    }
                    
                    // 更新总记录数为实际美食券数量，保持一致性
                    self.totalRecordsCount = AppState.shared.dessertVouchers.count
                    
                    // 重置加载状态（同时处理loadMoreVouchers的状态）
                    self.isLoadingVouchers = false
                    self.isLoadingMoreVouchers = false
                    
                    // 强制发送多个更新通知，确保视图能看到变化
                    DispatchQueue.main.async {
                        // 发送美食券更新通知
                        NotificationCenter.default.post(
                            name: NSNotification.Name("VouchersUpdated"),
                            object: nil
                        )
                        
                        // 额外发送新记录创建通知，触发界面完全刷新
                        NotificationCenter.default.post(
                            name: NSNotification.Name("NewRecordCreated"),
                            object: nil
                        )
                        
                        DRInfo("[FoodCheckInViewModel] 美食券数据加载成功: \(response.vouchers.count)个, 当前页: \(self.currentVoucherPage), 总加载: \(AppState.shared.dessertVouchers.count)个")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 缓存所有图片URL
    private func cacheImageURLs(voucherImages: [String: String], dessertIcons: [String: String], recordImages: [String: String]) {
        // 设置缓存过期时间为1小时
        let expirationInterval: TimeInterval = 3600
        let cacheService = ImageCacheService.shared
        
        // 1. 缓存美食券图片
        for (id, url) in voucherImages {
            if !url.isEmpty {
                cacheService.cacheImageURL(url, forId: id, expirationInterval: expirationInterval)
            }
        }
        
        // 2. 缓存图标
        for (id, url) in dessertIcons {
            if !url.isEmpty {
                // 使用特殊前缀标记图标URL
                cacheService.cacheImageURL(url, forId: "icon_\(id)", expirationInterval: expirationInterval)
            }
        }
        
        // 3. 缓存记录图片
        for (id, url) in recordImages {
            if !url.isEmpty {
                // 使用特殊前缀标记记录图片URL
                cacheService.cacheImageURL(url, forId: "record_\(id)", expirationInterval: expirationInterval)
            }
        }
        
        DRDebug("[FoodCheckInViewModel] 已缓存 \(voucherImages.count) 张美食券图片URL, \(dessertIcons.count) 张图标URL, \(recordImages.count) 张记录图片URL")
    }
    
    /// 检查美食券数据是否有变化
    private func hasVoucherChanges(newVouchers: [DessertVoucher]) -> Bool {
        // 数量不同，肯定有变化
        if appState.dessertVouchers.count != newVouchers.count {
            return true
        }
        
        // 创建ID到美食券的映射，方便比较
        let existingVoucherMap = Dictionary(uniqueKeysWithValues: 
            appState.dessertVouchers.map { ($0.id, $0) }
        )
        
        // 检查每一个新美食券是否存在变化
        for voucher in newVouchers {
            if let existingVoucher = existingVoucherMap[voucher.id] {
                // 比较关键属性
                if voucher.status != existingVoucher.status {
                    return true
                }
            } else {
                // 存在新的美食券
                return true
            }
        }
        
        return false
    }
    
    /// 在创建新的打卡记录后立即刷新美食券和记录数据
    func refreshDataAfterNewRecord() {
        DRInfo("[FoodCheckInViewModel] 新打卡记录创建后立即刷新数据")
        
        // 确保在主线程执行UI更新
        DispatchQueue.main.async {
            // 清除加载状态，避免冲突
            self.isLoadingVouchers = false
            self.isLoadingTopDesserts = false
            
            // 强制发送通知，告知视图需要刷新
            NotificationCenter.default.post(name: NSNotification.Name("NewRecordCreated"), object: nil)
            
            // 设置APIService跳过缓存
            APIService.shared.setSkipCache(true)
            
            // 先短暂延迟，让服务器有时间处理新记录
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // 1. 首先刷新美食券数据，现在包含了足够的信息，无需再单独加载运动记录
                DRInfo("[FoodCheckInViewModel] 正在强制刷新美食券数据...")
                self.loadVouchersIndependently(forceRefresh: true)
                
                // 2. 刷新排行榜数据
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.loadTopDesserts(limit: 5, force: true)
                    
                    // 额外发送通知，确保视图更新
                    NotificationCenter.default.post(name: NSNotification.Name("VouchersUpdated"), object: nil)
                    
                    // 重置缓存跳过标志
                    APIService.shared.setSkipCache(false)
                }
            }
        }
    }
    
    // MARK: - 退出登录清理
    /// 退出登录时调用，重置所有与用户相关的缓存数据
    func resetForLogout() {
        DispatchQueue.main.async {
            DRInfo("[FoodCheckInViewModel] 退出登录，重置本地缓存数据")
            // 清空排行榜
            self.topDesserts = []
            self.hasNoTopDessertData = false
            self.isLoadingTopDesserts = false
            // 重置分页等状态
            self.currentUserUUID = nil
            self.isLoadingVouchers = false
            self.isLoadingMoreVouchers = false
            self.currentVoucherPage = 1
            self.hasMoreVouchers = false
            self.noMoreVouchersConfirmed = false
        }
    }
}

// MARK: - 后端美食排行榜响应模型
struct TopDessertDTO: Codable {
    let dessertId: UUID
    let dessertName: String
    let checkinCount: Int
    let calories: Double
    let totalCalories: Double
    let imageURL: String
    
    enum CodingKeys: String, CodingKey {
        case dessertId = "dessert_id"
        case dessertName = "dessert_name"
        case checkinCount = "checkin_count"
        case calories
        case totalCalories = "total_calories"
        case imageURL = "image_url"
    }
}

struct TopDessertStatsResponse: Codable {
    let items: [TopDessertDTO]
    
    enum CodingKeys: String, CodingKey {
        case items
    }
}

struct TopDessertResponse: Codable {
    let code: Int
    let message: String
    let data: TopDessertStatsResponse
    
    enum CodingKeys: String, CodingKey {
        case code
        case message
        case data
    }
}

// 扩展FoodCheckInViewModel，添加加载单个运动记录的方法
extension FoodCheckInViewModel {
    /// 加载单个运动记录详情
    func loadSingleWorkoutRecord(recordId: String, completion: @escaping (WorkoutRecord?) -> Void) {
        DRInfo("[FoodCheckInViewModel] 加载单个运动记录详情: id=\(recordId)")
        
        // 检查缓存中是否已有该记录
        if let cachedRecord = AppState.shared.workoutRecords.first(where: { $0.id == recordId }) {
            DRDebug("[FoodCheckInViewModel] 使用缓存的运动记录数据: id=\(recordId)")
            completion(cachedRecord)
            return
        }
        
        // 从API加载单个运动记录
        APIService.shared.getWorkoutRecord(recordId: recordId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completionResult in
                    if case .failure(let error) = completionResult {
                        DRError("[FoodCheckInViewModel] 加载运动记录失败: id=\(recordId), 错误=\(error.localizedDescription)")
                        completion(nil)
                    }
                },
                receiveValue: { record in
                    DRInfo("[FoodCheckInViewModel] 成功加载运动记录: id=\(recordId)")
                    
                    // 将记录添加到缓存中
                    DispatchQueue.main.async {
                        // 避免重复添加
                        if !AppState.shared.workoutRecords.contains(where: { $0.id == record.id }) {
                            AppState.shared.workoutRecords.append(record)
                        }
                    }
                    
                    completion(record)
                }
            )
            .store(in: &self.cancellables)
    }
} 