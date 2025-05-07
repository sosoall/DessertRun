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
    
    /// 获取美食券列表
    /// - Parameter forceRefresh: 是否强制刷新
    func loadVouchers(forceRefresh: Bool = false) {
        // 如果强制刷新，重置页码和列表
        if forceRefresh {
            currentPage = 1
            vouchers = []
            hasMoreVouchers = true
        }
        
        // 如果正在加载或没有更多数据，直接返回
        if isLoading || !hasMoreVouchers {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let endpoint = "api/v1/vouchers?page=\(currentPage)&limit=\(pageSize)"
        
        // 使用NetworkManager进行请求
        NetworkManager.shared.request(
            endpoint: endpoint,
            method: .get,
            parameters: nil,
            requiresAuth: true
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
            self?.isLoading = false
            
            if case .failure(let error) = completion {
                self?.errorMessage = error.localizedDescription
                DRError("获取美食券失败: \(error)")
            }
        }, receiveValue: { [weak self] (data: APIResponse<PaginatedResponse<DessertVoucher>>) in
            guard let self = self else { return }
            
            if let items = data.data?.items {
                // 如果返回的数据不足一页，说明没有更多数据了
                if items.count < self.pageSize {
                    self.hasMoreVouchers = false
                }
                
                // 追加数据
                if self.currentPage == 1 {
                    self.vouchers = items
                } else {
                    self.vouchers.append(contentsOf: items)
                }
                
                // 增加页码
                self.currentPage += 1
            } else {
                self.hasMoreVouchers = false
            }
        })
        .store(in: &cancellables)
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