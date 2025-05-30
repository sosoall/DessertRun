import Foundation
import Combine
import SwiftUI

/// 按报名ID加载美食券的视图模型
class EnrollmentVoucherViewModel: ObservableObject {
    // 发布属性
    @Published var vouchers: [DessertVoucher] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var cancellables = Set<AnyCancellable>()

    /// 重置状态
    func reset() {
        vouchers = []
        errorMessage = nil
    }

    /// 获取状态对应的字符串
    private func statusParam(from filter: RecordFilter) -> String? {
        switch filter {
        case .all:
            return nil
        case .active:
            return "active"
        case .used:
            return "used"
        case .expired:
            return "expired"
        }
    }

    /// 加载美食券列表
    func loadVouchers(enrollmentId: String, filter: RecordFilter = .all) {
        // 如果正在加载，忽略
        guard !isLoading else { 
            DRInfo("[EnrollmentVoucherViewModel] loadVouchers: 正在加载中，忽略重复请求，报名ID: \(enrollmentId)")
            return 
        }

        DRInfo("[EnrollmentVoucherViewModel] loadVouchers: 开始加载美食券列表，报名ID: \(enrollmentId), 筛选条件: \(filter)")
        isLoading = true
        errorMessage = nil

        // 构建查询参数
        var params: [String: Any] = [:]
        if let status = statusParam(from: filter) {
            params["status"] = status
            DRInfo("[EnrollmentVoucherViewModel] loadVouchers: 添加状态筛选条件: \(status)")
        }

        let endpoint = "/api/v1/challenges/enrollments/\(enrollmentId)/vouchers"
        DRInfo("[EnrollmentVoucherViewModel] loadVouchers: 请求API端点: \(endpoint), 参数: \(params)")

        NetworkManager.shared.requestRaw(
            endpoint: endpoint,
            method: .get,
            parameters: params.isEmpty ? nil : params,
            requiresAuth: true
        )
        .tryMap { data, _ -> [DessertVoucher] in
            // 定义后端实际的响应结构
            struct Response: Codable {
                let code: Int
                let message: String
                let data: VoucherListData
                
                struct VoucherListData: Codable {
                    let vouchers: [DessertVoucher]
                }
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let resp = try decoder.decode(Response.self, from: data)
            DRInfo("[EnrollmentVoucherViewModel] loadVouchers: 成功解析API响应，美食券数量: \(resp.data.vouchers.count)")
            return resp.data.vouchers
        }
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            guard let self = self else { return }
            self.isLoading = false
            
            if case .failure(let error) = completion {
                self.errorMessage = error.localizedDescription
                DRInfo("[EnrollmentVoucherViewModel] loadVouchers: 加载失败，报名ID: \(enrollmentId), 错误: \(error)")
                print("❌ 加载美食券失败: \(error)")
            }
        } receiveValue: { [weak self] vouchers in
            guard let self = self else { return }
            self.vouchers = vouchers
            DRInfo("[EnrollmentVoucherViewModel] loadVouchers: 加载成功，报名ID: \(enrollmentId), 美食券数量: \(vouchers.count)")
            print("✅ 成功加载 \(vouchers.count) 张美食券")
        }
        .store(in: &cancellables)
    }
} 