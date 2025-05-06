import Foundation
import Combine

// 钱包和VIP相关的API调用
extension APIService {
    
    // 获取钱包信息
    func getWalletInfo() -> AnyPublisher<UserWallet, APIServiceError> {
        guard let token = AuthService.shared.accessToken else {
            return Fail(error: APIServiceError.unauthorized).eraseToAnyPublisher()
        }
        
        let endpoint = "/api/v1/wallet"
        
        return makeRequest(endpoint: endpoint, method: .get, headers: ["Authorization": "Bearer \(token)"])
            .decode(type: WalletResponse.self, decoder: JSONDecoder.apiDecoder)
            .tryMap { response in
                guard let data = response.data else {
                    throw APIServiceError.decodingError("No wallet data")
                }
                return data
            }
            .mapError { error in
                if let apiError = error as? APIServiceError {
                    return apiError
                }
                return APIServiceError.other(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    // 获取交易记录
    func getTransactions(page: Int = 1, pageSize: Int = 20) -> AnyPublisher<TransactionsListResponse, APIServiceError> {
        guard let token = AuthService.shared.accessToken else {
            return Fail(error: APIServiceError.unauthorized).eraseToAnyPublisher()
        }
        
        let endpoint = "/api/v1/wallet/transactions?page=\(page)&page_size=\(pageSize)"
        
        return makeRequest(endpoint: endpoint, method: .get, headers: ["Authorization": "Bearer \(token)"])
            .decode(type: TransactionsResponse.self, decoder: JSONDecoder.apiDecoder)
            .tryMap { response in
                guard let data = response.data else {
                    throw APIServiceError.decodingError("No transactions data")
                }
                return data
            }
            .mapError { error in
                if let apiError = error as? APIServiceError {
                    return apiError
                }
                return APIServiceError.other(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    // 获取VIP信息
    func getVIPInfo() -> AnyPublisher<VIPInfo, APIServiceError> {
        guard let token = AuthService.shared.accessToken else {
            return Fail(error: APIServiceError.unauthorized).eraseToAnyPublisher()
        }
        
        let endpoint = "/api/v1/vip/info"
        
        return makeRequest(endpoint: endpoint, method: .get, headers: ["Authorization": "Bearer \(token)"])
            .decode(type: VIPInfoResponse.self, decoder: JSONDecoder.apiDecoder)
            .tryMap { response in
                guard let data = response.data else {
                    throw APIServiceError.decodingError("No VIP info data")
                }
                return data
            }
            .mapError { error in
                if let apiError = error as? APIServiceError {
                    return apiError
                }
                return APIServiceError.other(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    // 获取VIP套餐信息
    func getVIPPackages() -> AnyPublisher<[VIPPackage], APIServiceError> {
        guard let token = AuthService.shared.accessToken else {
            return Fail(error: APIServiceError.unauthorized).eraseToAnyPublisher()
        }
        
        let endpoint = "/api/v1/vip/packages"
        
        return makeRequest(endpoint: endpoint, method: .get, headers: ["Authorization": "Bearer \(token)"])
            .decode(type: VIPPackagesResponse.self, decoder: JSONDecoder.apiDecoder)
            .tryMap { response in
                guard let data = response.data else {
                    throw APIServiceError.decodingError("No VIP packages data")
                }
                return data
            }
            .mapError { error in
                if let apiError = error as? APIServiceError {
                    return apiError
                }
                return APIServiceError.other(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
    
    // 购买VIP（改为直接购买，赠送星币）
    func purchaseVIP(packageID: String) -> AnyPublisher<VIPPurchaseResult, APIServiceError> {
        guard let token = AuthService.shared.accessToken else {
            return Fail(error: APIServiceError.unauthorized).eraseToAnyPublisher()
        }
        
        let endpoint = "/api/v1/vip/purchase/\(packageID)"
        
        return makeRequest(endpoint: endpoint, method: .post, headers: ["Authorization": "Bearer \(token)"])
            .decode(type: VIPPurchaseResponse.self, decoder: JSONDecoder.apiDecoder)
            .tryMap { response in
                guard let data = response.data else {
                    throw APIServiceError.decodingError("No purchase result data")
                }
                return data
            }
            .mapError { error in
                if let apiError = error as? APIServiceError {
                    return apiError
                }
                return APIServiceError.other(error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }
}

// JSONDecoder扩展，用于API日期格式化
extension JSONDecoder {
    static var apiDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }
} 