import Foundation
import Combine

// 钱包和VIP相关的API调用
extension APIService {
    
    // 获取钱包信息
    func getWalletInfo() -> AnyPublisher<UserWallet, APIServiceError> {
        let endpoint = "/api/v1/wallet"
        
        // 构建请求
        guard let url = URL(string: Config.API.baseURL + endpoint) else {
            return Fail(error: APIServiceError.unknown).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 添加认证令牌
        if let token = UserDefaults.standard.string(forKey: Config.UserData.tokenKey) {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 执行请求
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                if httpResponse.statusCode == 401 {
                    throw NetworkError.unauthorized("认证失败")
                }
                
                if httpResponse.statusCode >= 400 {
                    throw NetworkError.serverError(httpResponse.statusCode, "服务器错误")
                }
                
                return data
            }
            .decode(type: WalletResponse.self, decoder: JSONDecoder.apiDecoder)
            .tryMap { response -> UserWallet in
                guard let walletData = response.data else {
                    throw NetworkError.emptyData
                }
                return walletData
            }
            .mapError { error -> APIServiceError in
                if let networkError = error as? NetworkError {
                    if case .unauthorized = networkError {
                        return .tokenExpired
                    }
                    return .networkError(APINetworkError(error: networkError))
                }
                return .unknown
            }
            .eraseToAnyPublisher()
    }
    
    // 获取交易记录
    func getTransactions(page: Int = 1, pageSize: Int = 20) -> AnyPublisher<TransactionsListResponse, APIServiceError> {
        let endpoint = "/api/v1/wallet/transactions?page=\(page)&page_size=\(pageSize)"
        
        // 构建请求
        guard let url = URL(string: Config.API.baseURL + endpoint) else {
            return Fail(error: APIServiceError.unknown).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 添加认证令牌
        if let token = UserDefaults.standard.string(forKey: Config.UserData.tokenKey) {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 执行请求
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                if httpResponse.statusCode == 401 {
                    throw NetworkError.unauthorized("认证失败")
                }
                
                if httpResponse.statusCode >= 400 {
                    throw NetworkError.serverError(httpResponse.statusCode, "服务器错误")
                }
                
                return data
            }
            .decode(type: TransactionsResponse.self, decoder: JSONDecoder.apiDecoder)
            .tryMap { response -> TransactionsListResponse in
                guard let transactionsData = response.data else {
                    throw NetworkError.emptyData
                }
                return transactionsData
            }
            .mapError { error -> APIServiceError in
                if let networkError = error as? NetworkError {
                    if case .unauthorized = networkError {
                        return .tokenExpired
                    }
                    return .networkError(APINetworkError(error: networkError))
                }
                return .unknown
            }
            .eraseToAnyPublisher()
    }
    
    // 获取VIP信息
    func getVIPInfo() -> AnyPublisher<VIPInfo, APIServiceError> {
        let endpoint = "/api/v1/vip/info"
        DRInfo("[API] 开始获取VIP信息: \(endpoint)")
        
        // 构建请求
        guard let url = URL(string: Config.API.baseURL + endpoint) else {
            DRError("[API] 构建URL失败: \(Config.API.baseURL + endpoint)")
            return Fail(error: APIServiceError.unknown).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 添加认证令牌
        if let token = UserDefaults.standard.string(forKey: Config.UserData.tokenKey) {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            DRInfo("[API] 添加认证令牌: \(token.prefix(10))...")
        } else {
            DRWarning("[API] 未找到认证令牌")
        }
        
        // 执行请求
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    DRError("[API] 无效的HTTP响应")
                    throw NetworkError.invalidResponse
                }
                
                DRInfo("[API] VIP信息响应状态码: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 401 {
                    DRError("[API] VIP信息认证失败: 401")
                    throw NetworkError.unauthorized("认证失败")
                }
                
                if httpResponse.statusCode >= 400 {
                    DRError("[API] VIP信息服务器错误: \(httpResponse.statusCode)")
                    throw NetworkError.serverError(httpResponse.statusCode, "服务器错误")
                }
                
                // 记录响应数据
                if let jsonString = String(data: data, encoding: .utf8) {
                    DRInfo("[API] VIP信息响应数据: \(jsonString)")
                }
                
                return data
            }
            .decode(type: VIPInfoResponse.self, decoder: JSONDecoder.apiDecoder)
            .tryMap { response -> VIPInfo in
                // 检查响应状态码
                if response.code != 200 {
                    DRError("[API] VIP信息业务错误: 状态码=\(response.code), 消息=\(response.message)")
                    throw NetworkError.businessError(response.code, response.message)
                }
                
                guard let vipData = response.data else {
                    DRError("[API] VIP信息响应数据为空")
                    throw NetworkError.emptyData
                }
                
                DRInfo("[API] 成功解析VIP信息: isVIP=\(vipData.isVIP), 等级=\(vipData.userLevel)")
                return vipData
            }
            .mapError { error -> APIServiceError in
                if let networkError = error as? NetworkError {
                    DRError("[API] VIP信息网络错误: \(networkError)")
                    if case .unauthorized = networkError {
                        return .tokenExpired
                    }
                    return .networkError(APINetworkError(error: networkError))
                }
                
                if let decodingError = error as? DecodingError {
                    DRError("[API] VIP信息解码错误: \(decodingError)")
                    
                    // 详细解析解码错误
                    switch decodingError {
                    case .keyNotFound(let key, _):
                        DRError("[API] 找不到键: \(key.stringValue)")
                        return .decodeError("找不到键: \(key.stringValue)")
                    case .valueNotFound(let type, _):
                        DRError("[API] 找不到值，期望类型: \(type)")
                        return .decodeError("找不到值，期望类型: \(type)")
                    case .typeMismatch(let type, _):
                        DRError("[API] 类型不匹配，期望类型: \(type)")
                        return .decodeError("类型不匹配，期望类型: \(type)")
                    default:
                        DRError("[API] 其他解码错误: \(decodingError)")
                        return .decodeError("解码错误: \(decodingError)")
                    }
                }
                
                DRError("[API] VIP信息未知错误: \(error)")
                return .unknown
            }
            .eraseToAnyPublisher()
    }
    
    // 获取VIP套餐信息
    func getVIPPackages() -> AnyPublisher<[VIPPackage], APIServiceError> {
        let endpoint = "/api/v1/vip/packages"
        
        // 构建请求
        guard let url = URL(string: Config.API.baseURL + endpoint) else {
            return Fail(error: APIServiceError.unknown).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // 添加认证令牌
        if let token = UserDefaults.standard.string(forKey: Config.UserData.tokenKey) {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 执行请求
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                if httpResponse.statusCode == 401 {
                    throw NetworkError.unauthorized("认证失败")
                }
                
                if httpResponse.statusCode >= 400 {
                    throw NetworkError.serverError(httpResponse.statusCode, "服务器错误")
                }
                
                return data
            }
            .decode(type: VIPPackagesResponse.self, decoder: JSONDecoder.apiDecoder)
            .tryMap { response -> [VIPPackage] in
                guard let packagesData = response.data else {
                    throw NetworkError.emptyData
                }
                return packagesData
            }
            .mapError { error -> APIServiceError in
                if let networkError = error as? NetworkError {
                    if case .unauthorized = networkError {
                        return .tokenExpired
                    }
                    return .networkError(APINetworkError(error: networkError))
                }
                return .unknown
            }
            .eraseToAnyPublisher()
    }
    
    // 购买VIP（改为直接购买，赠送星币）
    func purchaseVIP(packageID: String) -> AnyPublisher<VIPPurchaseResult, APIServiceError> {
        let endpoint = "/api/v1/vip/purchase/\(packageID)"
        DRInfo("[API] 开始购买VIP: \(endpoint)")
        
        // 构建请求
        guard let url = URL(string: Config.API.baseURL + endpoint) else {
            DRError("[API] 构建URL失败: \(Config.API.baseURL + endpoint)")
            return Fail(error: APIServiceError.unknown).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加认证令牌
        if let token = UserDefaults.standard.string(forKey: Config.UserData.tokenKey) {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            DRInfo("[API] 添加认证令牌: \(token.prefix(10))...")
        } else {
            DRWarning("[API] 未找到认证令牌")
        }
        
        // 执行请求
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    DRError("[API] 无效的HTTP响应")
                    throw NetworkError.invalidResponse
                }
                
                DRInfo("[API] VIP购买响应状态码: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 401 {
                    DRError("[API] VIP购买认证失败: 401")
                    throw NetworkError.unauthorized("认证失败")
                }
                
                if httpResponse.statusCode >= 400 {
                    DRError("[API] VIP购买服务器错误: \(httpResponse.statusCode)")
                    throw NetworkError.serverError(httpResponse.statusCode, "服务器错误")
                }
                
                // 记录响应数据
                if let jsonString = String(data: data, encoding: .utf8) {
                    DRInfo("[API] VIP购买响应数据: \(jsonString)")
                }
                
                return data
            }
            .decode(type: VIPPurchaseResponse.self, decoder: JSONDecoder.apiDecoder)
            .tryMap { response -> VIPPurchaseResult in
                // 检查响应状态码
                if response.code != 200 {
                    DRError("[API] VIP购买业务错误: 状态码=\(response.code), 消息=\(response.message)")
                    throw NetworkError.businessError(response.code, response.message)
                }
                
                guard let purchaseData = response.data else {
                    DRError("[API] VIP购买响应数据为空")
                    throw NetworkError.emptyData
                }
                
                DRInfo("[API] 成功解析VIP购买结果: success=\(purchaseData.success), message=\(purchaseData.message)")
                return purchaseData
            }
            .mapError { error -> APIServiceError in
                if let networkError = error as? NetworkError {
                    DRError("[API] VIP购买网络错误: \(networkError)")
                    if case .unauthorized = networkError {
                        return .tokenExpired
                    }
                    return .networkError(APINetworkError(error: networkError))
                }
                
                if let decodingError = error as? DecodingError {
                    DRError("[API] VIP购买解码错误: \(decodingError)")
                    
                    // 详细解析解码错误
                    switch decodingError {
                    case .keyNotFound(let key, _):
                        DRError("[API] 找不到键: \(key.stringValue)")
                        return .decodeError("找不到键: \(key.stringValue)")
                    case .valueNotFound(let type, _):
                        DRError("[API] 找不到值，期望类型: \(type)")
                        return .decodeError("找不到值，期望类型: \(type)")
                    case .typeMismatch(let type, _):
                        DRError("[API] 类型不匹配，期望类型: \(type)")
                        return .decodeError("类型不匹配，期望类型: \(type)")
                    default:
                        DRError("[API] 其他解码错误: \(decodingError)")
                        return .decodeError("解码错误: \(decodingError)")
                    }
                }
                
                DRError("[API] VIP购买未知错误: \(error)")
                return .unknown
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