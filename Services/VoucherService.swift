//
//  VoucherService.swift
//  DessertRun
//
//  Created by Claude on 2025/4/8.
//

import Foundation
import Combine

class VoucherService: ObservableObject {
    /// 单例实例
    static let shared = VoucherService()
    
    /// 美食券列表
    @Published var vouchers: [DessertVoucher] = []
    
    /// 是否正在加载
    @Published var isLoading = false
    
    /// 错误信息
    @Published var errorMessage: String?
    
    /// 是否有更多券可加载
    @Published var hasMoreVouchers = true
    
    /// 当前页码
    private var currentPage = 1
    
    /// 每页数量
    private let pageSize = 10
    
    /// API服务
    private let apiService = APIService.shared
    
    /// 取消令牌
    private var cancellables = Set<AnyCancellable>()
    
    /// 最近一次触发拉取的时间，用于防抖
    private var lastFetchTime: Date = .distantPast
    
    /// 获取美食券列表
    /// - Parameter forceRefresh: 是否强制刷新
    func loadVouchers(forceRefresh: Bool = false) {
        // 1. 节流判断放在最前，避免在被拦截时已清空数据
        let now = Date()
        let interval = now.timeIntervalSince(lastFetchTime)
        if interval < 1 { // 普通调用节流 1s
            return
        }
        if forceRefresh && interval < 10 {
            return
        }

        // 2. 如果强制刷新，重置页码和列表
        if forceRefresh {
            currentPage = 1
            vouchers = []
            hasMoreVouchers = true
        }

        // 3. 若正在加载或没有更多数据则返回
        if isLoading || !hasMoreVouchers {
            return
        }

        isLoading = true
        errorMessage = nil
        
        // 使用批量接口，按created_at降序，第一页limit自定义
        let params: [String: Any] = [
            "page": currentPage,
            "limit": pageSize,
            "status": "active"
        ]

        NetworkManager.shared.request(
            endpoint: "/api/v1/vouchers/batch",
            method: .get,
            parameters: params,
            requiresAuth: true,
            responseType: VoucherBatchWrapper.self
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
            self?.isLoading = false
            if case .failure(let error) = completion {
                self?.errorMessage = error.localizedDescription
                DRError("获取美食券失败: \(error)")
            }
        }, receiveValue: { [weak self] resp in
            guard let self = self else { return }
            var enriched: [DessertVoucher] = []
            let imgMap = resp.data.images ?? [:]
            let iconMap = resp.data.dessertIcons ?? [:]
            for var v in resp.data.vouchers {
                if let imgId = v.imageId, let url = imgMap[imgId] {
                    v.voucherImageURL = url
                }
                if let dId = v.dessertId, let url = iconMap[dId] {
                    v.dessertIconURL = url
                }
                enriched.append(v)
            }
            if self.currentPage == 1 {
                self.vouchers = enriched
            } else {
                // 追加并去重（按id）
                var combined = self.vouchers
                combined.append(contentsOf: enriched)
                var seen = Set<String>()
                self.vouchers = combined.filter { voucher in
                    let id = voucher.id
                    if seen.contains(id) { return false }
                    seen.insert(id)
                    return true
                }.sorted { $0.createdAt > $1.createdAt }
            }

            // 更新分页状态
            self.hasMoreVouchers = resp.data.total > self.vouchers.count
            if self.hasMoreVouchers {
                self.currentPage += 1
            }

            // 4. 预缓存券大图与icon，加快滚动加载
            let urlsToPrefetch: [String] = self.vouchers.compactMap { v in
                [v.displayVoucherImageURL, v.displayDessertIconURL]
            }.flatMap { $0 }.compactMap { $0 }
            if !urlsToPrefetch.isEmpty {
                ImageCacheService.shared.prefetchImages(urls: urlsToPrefetch) { _, _ in }
            }
        })
        .store(in: &cancellables)
        
        lastFetchTime = now
    }
    
    /// 加载更多美食券
    func loadMoreVouchersIfNeeded() {
        loadVouchers(forceRefresh: false)
    }
    
    /// 核销美食券
    /// - Parameters:
    ///   - voucherID: 美食券ID
    ///   - activityID: 活动ID（可选）
    ///   - completion: 完成回调
    func redeemVoucher(voucherID: UUID, activityID: UUID? = nil, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        errorMessage = nil
        
        let endpoint = "api/v1/vouchers/\(voucherID.uuidString)/redeem"
        
        var requestBody: [String: Any] = [:]
        if let activityID = activityID {
            requestBody["activity_id"] = activityID.uuidString
        }
        
        // 使用NetworkManager进行请求
        NetworkManager.shared.request(
            endpoint: endpoint,
            method: .post,
            parameters: requestBody,
            requiresAuth: true
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completionResult in
            self?.isLoading = false
            
            if case .failure(let error) = completionResult {
                self?.errorMessage = error.localizedDescription
                DRError("核销美食券失败: \(error)")
                completion(false, error.localizedDescription)
            }
        }, receiveValue: { (data: APIResponse<RedeemVoucherResponse>) in
            if data.code == 0 && data.data?.success == true {
                completion(true, nil)
            } else {
                completion(false, data.message)
            }
        })
        .store(in: &cancellables)
    }
    
    /// 在本地列表中快速插入一张新美食券（避免重新走网络请求）
    /// - Parameter voucher: 新生成的美食券
    func insertNewVoucher(_ voucher: DessertVoucher) {
        // 保证在主线程更新已发布属性
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // 如果列表中已存在同 ID 券则忽略
            guard !self.vouchers.contains(where: { $0.id == voucher.id }) else { return }
            // 直接插入列表首位并保持时间倒序
            self.vouchers.insert(voucher, at: 0)
            self.vouchers.sort { $0.createdAt > $1.createdAt }
        }
    }
}

/// 分页响应
struct PaginatedResponse<T: Codable>: Codable {
    let total: Int
    let page: Int
    let limit: Int
    let items: [T]
}

/// 核销美食券响应
struct RedeemVoucherResponse: Codable {
    let success: Bool
    let voucherID: UUID
    let redeemedAt: Date
    let activityID: UUID?
    
    enum CodingKeys: String, CodingKey {
        case success
        case voucherID = "voucher_id"
        case redeemedAt = "redeemed_at"
        case activityID = "activity_id"
    }
}

struct VoucherBatchWrapper: Codable {
    let code: Int
    let message: String
    let data: VoucherBatchData
}

struct VoucherBatchData: Codable {
    let total: Int
    let page: Int
    let limit: Int
    let vouchers: [DessertVoucher]
    let images: [String: String]?
    let dessertIcons: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case total, page, limit, vouchers
        case images
        case dessertIcons = "dessert_icons"
    }
} 