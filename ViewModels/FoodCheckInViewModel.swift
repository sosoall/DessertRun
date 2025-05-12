import SwiftUI
import Combine
import Foundation

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
    // MARK: - 发布属性
    
    /// 美食券加载状态
    @Published var isLoadingVouchers: Bool = false
    
    /// 错误信息
    @Published var errorMessage: String? = nil
    
    /// 全局状态引用
    private var appState: AppState
    
    /// 发布者集合
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化方法
    
    /// 初始化
    init(appState: AppState) {
        self.appState = appState
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
                    
                    // 更新应用状态中的美食券列表
                    DispatchQueue.main.async {
                        // 避免不必要的状态更新，只在数据真正变化时更新
                        let hasChanges = self.hasVoucherChanges(newVouchers: vouchers)
                        
                        if hasChanges {
                            DRDebug("[FoodCheckInViewModel] 检测到美食券数据变化，更新状态")
                            self.appState.dessertVouchers = vouchers
                            DRInfo("[FoodCheckInViewModel] 成功加载\(vouchers.count)张美食券")
                        } else {
                            DRDebug("[FoodCheckInViewModel] 美食券数据未变化，跳过更新")
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    /// 获取按时间倒序排列的所有记录
    func getSortedAllRecords() -> [WorkoutRecord] {
        return appState.workoutRecords.sorted { record1, record2 in
            // 比较时间戳，精确到秒级的倒序排列（最新的记录在前）
            return record1.date.timeIntervalSince1970 > record2.date.timeIntervalSince1970
        }
    }
    
    /// 获取所有美食排行榜
    func getAllTopDesserts(count: Int) -> [StatTopDessertItem]? {
        return getTopDessertsFromRecords(records: appState.workoutRecords, count: count)
    }
    
    /// 从记录中获取排名前几的美食
    private func getTopDessertsFromRecords(records: [WorkoutRecord], count: Int) -> [StatTopDessertItem]? {
        if records.isEmpty {
            return nil
        }
        
        // 统计每个甜品出现的次数和热量值
        var dessertInfo: [String: (count: Int, calories: Double, name: String, imageURL: String, dessertId: String)] = [:]
        
        for record in records {
            let dessertId = record.dessert.id
            let calories = Double(record.dessert.calories) ?? 0
            
            // 获取图片URL
            let imageURL: String
            if let regularImage = record.dessert.images.first(where: { $0.type == "regular" }) {
                // 使用regular类型的图片
                imageURL = regularImage.url
            } else if !record.dessert.images.isEmpty {
                // 如果没有regular类型但有其他图片，使用第一张
                imageURL = record.dessert.images.first!.url
            } else {
                // 没有图片时使用API接口路径
                imageURL = "/api/v1/desserts/\(dessertId)/images/regular"
            }
            
            if let existing = dessertInfo[dessertId] {
                dessertInfo[dessertId] = (
                    existing.count + 1,
                    existing.calories,
                    record.dessert.name,
                    existing.imageURL,
                    dessertId
                )
            } else {
                dessertInfo[dessertId] = (
                    1,
                    calories,
                    record.dessert.name,
                    imageURL,
                    dessertId
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
            
            return StatTopDessertItem(
                id: dessertId,
                name: info.name,
                imageName: info.imageURL,
                calories: info.calories,
                count: info.count,
                totalCalories: info.calories * Double(info.count),
                dessertId: info.dessertId
            )
        }
    }
    
    // MARK: - 加载更多记录
    var hasMoreRecords: Bool = false
    var isLoadingMore: Bool = false
    var currentPage: Int = 1
    private let pageSize: Int = 20
    var totalRecordsCount: Int = 0
    
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
        if isLoadingMore {
            DRDebug("[FoodCheckInViewModel] 正在加载中，忽略重复请求")
            return
        }
        
        // 重置分页信息
        currentPage = 1
        hasMoreRecords = false
        
        DRDebug("[FoodCheckInViewModel] 开始加载美食记录，页码: \(currentPage)，每页数量: \(pageSize)")
        
        APIService.shared.getUserWorkoutRecordsWithTotal(page: currentPage, limit: pageSize)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
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
                        // 只有当已加载的记录数小于总记录数时，才设置hasMoreRecords为true
                        let recordsLoaded = records.count
                        self.hasMoreRecords = recordsLoaded < total
                        
                        DRDebug("[FoodCheckInViewModel] 当前加载: \(recordsLoaded), 总记录数: \(total), 是否有更多: \(self.hasMoreRecords)")
                        
                        // 加载完美食记录后，加载美食券
                        self.loadDessertVouchers()
                    }
                }
            )
            .store(in: &cancellables)
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
} 