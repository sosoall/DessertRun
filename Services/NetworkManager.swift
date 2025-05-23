import Foundation
import Combine

// 导入我们的APIErrors定义
// 导入API错误类型

/// 空数据响应类型，用于没有返回数据的API
public struct EmptyResponseData: Decodable {}

/// API响应结构
public struct APIResponse<T: Decodable>: Decodable {
    public let code: Int
    public let message: String
    public let data: T?
    
    public var success: Bool {
        return code == 0 || code == 200
    }
    
    // 自定义初始化方法，手动解析data字段
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(Int.self, forKey: .code)
        message = try container.decode(String.self, forKey: .message)
        
        // 手动尝试解析data字段
        if let _ = try? container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .data) {
            // 如果data是一个对象，我们需要手动构建一个新的解码器来解析它
            let dataDecoder = try container.superDecoder(forKey: .data)
            data = try T(from: dataDecoder)
        } else {
            // 如果data是null或者其他类型
            data = try container.decodeIfPresent(T.self, forKey: .data)
        }
    }
    
    public enum CodingKeys: String, CodingKey {
        case code, message, data
    }
    
    // 动态CodingKeys，用于检查data是否为对象
    public struct DynamicCodingKeys: CodingKey {
        public var stringValue: String
        public var intValue: Int?
        
        public init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }
        
        public init?(intValue: Int) {
            self.stringValue = "\(intValue)"
            self.intValue = intValue
        }
    }
}

/// HTTP请求方法
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

/// 网络管理器
public class NetworkManager {
    public static let shared = NetworkManager()
    
    // 自定义JSON解码器
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        
        // 配置日期解码策略，支持多种格式
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ" // 标准格式带毫秒
        
        let backupFormatter = DateFormatter()
        backupFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" // 不带毫秒的格式
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // 尝试使用主要日期格式
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            
            // 尝试备用日期格式
            if let date = backupFormatter.date(from: dateString) {
                return date
            }
            
            // 尝试ISO8601格式
            if let date = ISO8601DateFormatter().date(from: dateString) {
                return date
            }
            
            // 尝试简单日期格式
            let simpleFormatter = DateFormatter()
            simpleFormatter.dateFormat = "yyyy-MM-dd"
            if let date = simpleFormatter.date(from: dateString) {
                return date
            }
            
            // 如果所有格式都失败，抛出错误
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected date string to be ISO8601-formatted or in format 'yyyy-MM-dd'T'HH:mm:ss.SSSZ'."
                )
            )
        }
        
        return decoder
    }()
    
    private init() {}
    
    /// 创建API请求
    /// - Parameters:
    ///   - endpoint: API端点路径
    ///   - method: HTTP方法
    ///   - parameters: 请求参数
    ///   - requiresAuth: 是否需要认证令牌
    /// - Returns: 包含解码后数据的发布者
    public func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) -> AnyPublisher<T, NetworkError> {
        
        // 构建完整URL
        let urlString: String
        if endpoint.hasPrefix("http") {
            urlString = endpoint
        } else {
            urlString = Config.API.baseURL + endpoint
        }
        
        guard let url = URL(string: urlString) else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        // 检查授权令牌是否已过期（如果请求需要授权）
        if requiresAuth {
            if let token = UserDefaults.standard.string(forKey: Config.UserData.tokenKey) {
                // 检查令牌是否为空字符串或格式明显无效
                if token.isEmpty || token.count < 10 {
                    DRWarning("[NetworkManager] 发现无效令牌，可能已过期")
                    
                    // 删除无效令牌
                    UserDefaults.standard.removeObject(forKey: Config.UserData.tokenKey)
                    UserDefaults.standard.removeObject(forKey: Config.UserData.userIdKey)
                    
                    // 通知认证服务处理token过期
                    DispatchQueue.main.async {
                        AuthService.shared.handleTokenExpired()
                    }
                    
                    return Fail(error: NetworkError.unauthorized("令牌无效，请重新登录")).eraseToAnyPublisher()
                }
            } else {
                // 如果需要授权但没有令牌，直接返回未授权错误
                DRWarning("[NetworkManager] 请求需要授权但未找到令牌")
                
                // 通知认证服务处理token过期
                DispatchQueue.main.async {
                    AuthService.shared.handleTokenExpired()
                }
                
                return Fail(error: NetworkError.unauthorized("未登录或登录已过期")).eraseToAnyPublisher()
            }
        }
        
        // 创建URL请求
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = Config.API.timeout
        
        // 添加通用头部
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("\(Config.App.appName)/\(Config.App.appVersion)", forHTTPHeaderField: "User-Agent")
        
        // 添加认证令牌
        if requiresAuth, let token = UserDefaults.standard.string(forKey: Config.UserData.tokenKey) {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 处理参数
        if let parameters = parameters {
            if method == .get {
                // 对于GET请求，将参数添加到URL中
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
                components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
                if let queryURL = components.url {
                    request.url = queryURL
                }
                DRDebug("[NetworkManager] GET请求参数: \(parameters)")
            } else {
                // 对于其他请求，将参数添加到请求体中
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: parameters)
                    request.httpBody = jsonData
                    
                    // 增加请求参数日志
                    DRDebug("[NetworkManager] \(method.rawValue)请求参数: \(parameters)")
                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                        DRDebug("[NetworkManager] 序列化后的JSON参数: \(jsonString)")
                    }
                    
                    // 检查参数中特殊字段的类型问题
                    for (key, value) in parameters {
                        if key == "duration" || key == "distance" {
                            DRDebug("[NetworkManager] 参数[\(key)]的类型: \(type(of: value)), 值: \(value)")
                        }
                    }
                } catch {
                    DRError("[NetworkManager] 参数序列化失败: \(error.localizedDescription)")
                    return Fail(error: NetworkError.requestFailed(error)).eraseToAnyPublisher()
                }
            }
        }
        
        // 执行请求
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { NetworkError.requestFailed($0) }
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                // 打印详细的HTTP状态和响应大小信息
                DRDebug("[NetworkManager] 收到HTTP响应: \(endpoint), 状态码=\(httpResponse.statusCode), 数据大小=\(data.count)字节")
                
                // 打印原始JSON响应数据（最多前1000个字符，避免日志过长）
                if data.count > 0 {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        let truncatedJson = jsonString.count > 1000 ? String(jsonString.prefix(1000)) + "..." : jsonString
                        DRDebug("[NetworkManager] 原始响应JSON: \(truncatedJson)")
                    } else {
                        DRDebug("[NetworkManager] 响应数据无法转为JSON字符串")
                    }
                }
                
                // 处理HTTP状态码
                switch httpResponse.statusCode {
                case 200..<300:
                    return data
                case 400:
                    // 提取具体的400错误信息
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        // 打印完整的错误响应以便调试
                        DRError("[NetworkManager] 400错误详细信息: \(json)")
                        
                        if let message = json["message"] as? String {
                            throw NetworkError.badRequest(message)
                        } else if let error = json["error"] as? String {
                            throw NetworkError.badRequest(error)
                        } else if let errors = json["errors"] as? [[String: Any]], !errors.isEmpty {
                            // 处理错误数组
                            let errorMessages = errors.compactMap { error -> String? in
                                if let field = error["field"] as? String, 
                                   let message = error["message"] as? String {
                                    return "\(field): \(message)"
                                }
                                return nil
                            }.joined(separator: ", ")
                            
                            if !errorMessages.isEmpty {
                                throw NetworkError.badRequest(errorMessages)
                            }
                        }
                        
                        // 如果没有标准的错误字段，返回整个JSON字符串
                        if let jsonString = String(data: data, encoding: .utf8) {
                            throw NetworkError.badRequest("请求参数错误: \(jsonString)")
                        } else {
                            throw NetworkError.badRequest("请求参数错误: 无法解析错误详情")
                        }
                    } else if let jsonString = String(data: data, encoding: .utf8) {
                        DRError("[NetworkManager] 400错误原始响应: \(jsonString)")
                        throw NetworkError.badRequest("请求参数错误: \(jsonString)")
                    } else {
                        throw NetworkError.badRequest("请求参数错误")
                    }
                case 401:
                    // 清除过期令牌
                    UserDefaults.standard.removeObject(forKey: Config.UserData.tokenKey)
                    UserDefaults.standard.removeObject(forKey: Config.UserData.userIdKey)
                    
                    // 通知认证服务处理token过期
                    DispatchQueue.main.async {
                        AuthService.shared.handleTokenExpired()
                    }
                    
                    // 提取具体的401错误信息
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw NetworkError.unauthorized(message)
                    } else {
                        throw NetworkError.unauthorized("未授权访问")
                    }
                case 404:
                    // 提取具体的404错误信息
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw NetworkError.notFound(message)
                    } else {
                        throw NetworkError.notFound("请求的资源不存在")
                    }
                default:
                    // 尝试解析服务器错误消息
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let message = json["message"] as? String {
                            throw NetworkError.serverError(httpResponse.statusCode, message)
                        } else {
                            throw NetworkError.serverError(httpResponse.statusCode, "未知服务器错误")
                        }
                    } catch {
                        if let networkError = error as? NetworkError {
                            throw networkError
                        } else {
                            throw NetworkError.serverError(httpResponse.statusCode, "未知服务器错误")
                        }
                    }
                }
            }
            .mapError { error -> NetworkError in
                // 如果错误已经是NetworkError，直接返回即可
                if let networkError = error as? NetworkError {
                    return networkError
                } else {
                    return NetworkError.requestFailed(error)
                }
            }
            .flatMap { (data: Data) -> AnyPublisher<T, NetworkError> in
                // 尝试解析为API响应格式
                // 使用自定义解码器，支持多种日期格式
                // 打印原始数据，用于调试
                if let jsonString = String(data: data, encoding: .utf8) {
                    DRInfo("[NetworkManager] 收到的JSON数据: \(jsonString)")
                }
                
                // 创建一个特殊情况处理器，处理无内容响应的情况
                if T.self == EmptyResponseData.self {
                    return Just(EmptyResponseData() as! T)
                        .setFailureType(to: NetworkError.self)
                        .eraseToAnyPublisher()
                }
                
                // 特殊处理数组类型响应，例如[ChallengeActivity]
                if String(describing: T.self).contains("Array<") {
                    DRInfo("[NetworkManager] 检测到数组类型响应: \(T.self)")
                    
                    // 特别处理ChallengeActivity数组
                    if T.self == [ChallengeActivity].self {
                        do {
                            // 检查是否是标准包装响应
                            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               json["code"] != nil {
                                // 如果是标准响应格式，继续常规解析流程
                            } else {
                                // 如果是直接的数组响应，尝试直接解析
                                let result = try self.decoder.decode([ChallengeActivity].self, from: data)
                                return Just(result as! T)
                                    .setFailureType(to: NetworkError.self)
                                    .eraseToAnyPublisher()
                            }
                        } catch {
                            DRError("[NetworkManager] 直接解析[ChallengeActivity]失败: \(error)")
                        }
                    }
                }
                
                // 尝试解析为API标准响应格式
                return Just(data)
                    .decode(type: APIResponse<T>.self, decoder: self.decoder)
                    .mapError { [weak self] error -> NetworkError in
                        DRError("[NetworkManager] 解析API响应失败: \(error.localizedDescription)")
                        
                        // 处理self为nil的情况
                        guard let self = self else {
                            return NetworkError.decodingFailed(error)
                        }
                        
                        // 如果不是标准响应格式，尝试直接解析为目标类型
                        DRInfo("[NetworkManager] 尝试直接解析为目标类型 \(T.self)")
                        
                        // 简化错误处理逻辑，避免使用case pattern matching
                        if let decodingError = error as? DecodingError {
                            // 直接返回解码错误
                            return NetworkError.decodingFailed(decodingError)
                        } else {
                            return NetworkError.requestFailed(error)
                        }
                    }
                    .tryMap { response in
                        // 检查响应状态
                        guard response.code == 0 || response.code == 200 else {
                            throw NetworkError.serverError(response.code, response.message)
                        }
                        
                        // 检查是否有数据
                        guard let responseData = response.data else {
                            throw NetworkError.emptyData
                        }
                        
                        return responseData
                    }
                    .mapError { error -> NetworkError in
                        // 如果错误已经是NetworkError，直接返回即可
                        if let networkError = error as? NetworkError {
                            return networkError
                        } else {
                            return NetworkError.decodingFailed(error)
                        }
                    }
                    .catch { [weak self] error -> AnyPublisher<T, NetworkError> in
                        // 处理self为nil的情况
                        guard let self = self else {
                            return Fail(error: error).eraseToAnyPublisher()
                        }
                        
                        // 如果不是标准响应格式，尝试直接解析为目标类型
                        DRInfo("[NetworkManager] 尝试直接解析为目标类型 \(T.self)")
                        
                        // 简化错误处理逻辑，避免使用case pattern matching
                        if let decodingError = error as? DecodingError {
                            // 直接返回解码错误
                            return Fail(error: NetworkError.decodingFailed(decodingError))
                                .eraseToAnyPublisher()
                        } else {
                            return Fail(error: error)
                                .eraseToAnyPublisher()
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    /// 创建API请求（自定义响应类型）
    /// - Parameters:
    ///   - endpoint: API端点路径
    ///   - method: HTTP方法
    ///   - parameters: 请求参数
    ///   - requiresAuth: 是否需要认证令牌
    ///   - responseType: 自定义响应类型
    /// - Returns: 包含解码后数据的发布者
    public func request<R: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        requiresAuth: Bool = true,
        responseType: R.Type
    ) -> AnyPublisher<R, NetworkError> {
        // 构建完整URL
        let urlString: String
        if endpoint.hasPrefix("http") {
            urlString = endpoint
        } else {
            urlString = Config.API.baseURL + endpoint
        }
        
        guard let url = URL(string: urlString) else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        // 检查授权令牌是否已过期（如果请求需要授权）
        if requiresAuth {
            if let token = UserDefaults.standard.string(forKey: Config.UserData.tokenKey) {
                // 检查令牌是否为空字符串或格式明显无效
                if token.isEmpty || token.count < 10 {
                    DRWarning("[NetworkManager] 发现无效令牌，可能已过期")
                    
                    // 删除无效令牌
                    UserDefaults.standard.removeObject(forKey: Config.UserData.tokenKey)
                    UserDefaults.standard.removeObject(forKey: Config.UserData.userIdKey)
                    
                    // 通知认证服务处理token过期
                    DispatchQueue.main.async {
                        AuthService.shared.handleTokenExpired()
                    }
                    
                    return Fail(error: NetworkError.unauthorized("令牌无效，请重新登录")).eraseToAnyPublisher()
                }
            } else {
                // 如果需要授权但没有令牌，直接返回未授权错误
                DRWarning("[NetworkManager] 请求需要授权但未找到令牌")
                
                // 通知认证服务处理token过期
                DispatchQueue.main.async {
                    AuthService.shared.handleTokenExpired()
                }
                
                return Fail(error: NetworkError.unauthorized("未登录或登录已过期")).eraseToAnyPublisher()
            }
        }
        
        // 创建URL请求
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = Config.API.timeout
        
        // 添加通用头部
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("\(Config.App.appName)/\(Config.App.appVersion)", forHTTPHeaderField: "User-Agent")
        
        // 添加认证令牌
        if requiresAuth, let token = UserDefaults.standard.string(forKey: Config.UserData.tokenKey) {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 处理参数
        if let parameters = parameters {
            if method == .get {
                // 对于GET请求，将参数添加到URL中
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
                components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
                if let queryURL = components.url {
                    request.url = queryURL
                }
                DRDebug("[NetworkManager] GET请求参数: \(parameters)")
            } else {
                // 对于其他请求，将参数添加到请求体中
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: parameters)
                    request.httpBody = jsonData
                    
                    // 增加请求参数日志
                    DRDebug("[NetworkManager] \(method.rawValue)请求参数: \(parameters)")
                } catch {
                    DRError("[NetworkManager] 参数序列化失败: \(error.localizedDescription)")
                    return Fail(error: NetworkError.requestFailed(error)).eraseToAnyPublisher()
                }
            }
        }
        
        // 执行请求
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { NetworkError.requestFailed($0) }
            .tryMap { data, response -> (Data, HTTPURLResponse) in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                // 打印详细的HTTP状态和响应大小信息
                DRDebug("[NetworkManager] 收到HTTP响应: \(endpoint), 状态码=\(httpResponse.statusCode), 数据大小=\(data.count)字节")
                
                // 打印原始JSON响应数据（最多前1000个字符，避免日志过长）
                if data.count > 0 {
                    if let jsonString = String(data: data, encoding: .utf8) {
                        let truncatedJson = jsonString.count > 1000 ? String(jsonString.prefix(1000)) + "..." : jsonString
                        DRDebug("[NetworkManager] 原始响应JSON: \(truncatedJson)")
                    } else {
                        DRDebug("[NetworkManager] 响应数据无法转为JSON字符串")
                    }
                }
                
                // 处理HTTP状态码
                switch httpResponse.statusCode {
                case 200..<300:
                    return (data, httpResponse)
                case 400:
                    // 提取具体的400错误信息
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw NetworkError.badRequest(message)
                    } else if let jsonString = String(data: data, encoding: .utf8) {
                        throw NetworkError.badRequest(jsonString)
                    } else {
                        throw NetworkError.badRequest("请求参数错误")
                    }
                case 401:
                    // 清除过期令牌
                    UserDefaults.standard.removeObject(forKey: Config.UserData.tokenKey)
                    UserDefaults.standard.removeObject(forKey: Config.UserData.userIdKey)
                    
                    // 通知认证服务处理token过期
                    DispatchQueue.main.async {
                        AuthService.shared.handleTokenExpired()
                    }
                    
                    // 提取具体的401错误信息
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw NetworkError.unauthorized(message)
                    } else {
                        throw NetworkError.unauthorized("未授权访问")
                    }
                case 404:
                    // 提取具体的404错误信息
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw NetworkError.notFound(message)
                    } else {
                        throw NetworkError.notFound("请求的资源不存在")
                    }
                default:
                    // 尝试解析服务器错误消息
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw NetworkError.serverError(httpResponse.statusCode, message)
                    } else {
                        throw NetworkError.serverError(httpResponse.statusCode, "未知服务器错误")
                    }
                }
            }
            .map { data, _ in
                // 先保存数据
                let responseData = data
                return responseData
            }
            .decode(type: R.self, decoder: self.decoder)
            .mapError { [weak self] error -> NetworkError in
                // 确保self不为nil
                guard let self = self else {
                    return NetworkError.decodingFailed(error)
                }
                
                if let decodingError = error as? DecodingError {
                    DRError("[NetworkManager] 解析自定义响应失败: \(decodingError.localizedDescription)")
                    
                    // 提供更详细的解码错误信息
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        DRError("[NetworkManager] 找不到键: \(key.stringValue), 路径: \(context.codingPath.map { $0.stringValue })")
                        // 尝试输出当前已解析的上下文内容
                        DRError("[NetworkManager] 解析上下文: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        DRError("[NetworkManager] 类型不匹配: 期望\(type), 路径: \(context.codingPath.map { $0.stringValue })")
                    case .valueNotFound(let type, let context):
                        DRError("[NetworkManager] 值不存在: 期望\(type), 路径: \(context.codingPath.map { $0.stringValue })")
                    case .dataCorrupted(let context):
                        DRError("[NetworkManager] 数据损坏: \(context.debugDescription), 路径: \(context.codingPath.map { $0.stringValue })")
                    @unknown default:
                        DRError("[NetworkManager] 未知解码错误: \(decodingError)")
                    }
                    
                    return NetworkError.decodingFailed(decodingError)
                } else {
                    return NetworkError.requestFailed(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    // 处理响应数据
    private func handleResponse<T: Decodable>(_ data: Data, _ response: URLResponse) throws -> T {
        // 检查HTTP响应状态码
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidURL
        }
        
        // 打印响应状态码和数据大小以便调试
        DRInfo("[NetworkManager] 收到响应: 状态码=\(httpResponse.statusCode), 数据大小=\(data.count)字节")
        
        // 打印响应原始数据以便调试
        if let jsonString = String(data: data, encoding: .utf8) {
            DRInfo("[NetworkManager] 响应原始数据: \(jsonString)")
        }
        
        // 检查HTTP状态码
        switch httpResponse.statusCode {
        case 200...299:  // 成功
            do {
                let decoder = JSONDecoder()
                // 不使用下划线命名转换为驼峰命名，因为模型中已经手动定义了CodingKeys
                // decoder.keyDecodingStrategy = .convertFromSnakeCase
                return try decoder.decode(T.self, from: data)
            } catch {
                // 添加详细的解码错误信息
                DRError("[NetworkManager] 数据解析失败: \(error.localizedDescription)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        DRError("找不到键: \(key.stringValue), 路径: \(context.codingPath.map { $0.stringValue })")
                        // 尝试输出当前已解析的上下文内容
                        DRError("[NetworkManager] 解析上下文: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        DRError("找不到\(type)类型的值, 路径: \(context.codingPath.map { $0.stringValue })")
                    case .typeMismatch(let type, let context):
                        DRError("类型不匹配: 期望\(type), 路径: \(context.codingPath.map { $0.stringValue })")
                    case .dataCorrupted(let context):
                        DRError("数据损坏: \(context)")
                    @unknown default:
                        DRError("未知解码错误: \(decodingError)")
                    }
                }
                throw NetworkError.decodingFailed(error)
            }
            
        case 400:  // 错误请求
            if let jsonString = String(data: data, encoding: .utf8) {
                throw NetworkError.badRequest(jsonString)
            } else {
                throw NetworkError.badRequest("Bad Request")
            }
            
        case 401:  // 未授权
            if let jsonString = String(data: data, encoding: .utf8) {
                throw NetworkError.unauthorized(jsonString)
            } else {
                throw NetworkError.unauthorized("Unauthorized")
            }
            
        case 404:  // 未找到
            if let jsonString = String(data: data, encoding: .utf8) {
                throw NetworkError.notFound(jsonString)
            } else {
                throw NetworkError.notFound("Not Found")
            }
            
        case 500...599:  // 服务器错误
            if let jsonString = String(data: data, encoding: .utf8) {
                throw NetworkError.serverError(httpResponse.statusCode, jsonString)
            } else {
                throw NetworkError.serverError(httpResponse.statusCode, "Server Error")
            }
            
        default:  // 其他错误
            if let jsonString = String(data: data, encoding: .utf8) {
                throw NetworkError.serverError(httpResponse.statusCode, jsonString)
            } else {
                throw NetworkError.serverError(httpResponse.statusCode, "Unknown Error")
            }
        }
    }
    
    /// 创建API请求，返回原始响应数据
    /// - Parameters:
    ///   - endpoint: API端点路径
    ///   - method: HTTP方法
    ///   - parameters: 请求参数
    ///   - requiresAuth: 是否需要认证令牌
    /// - Returns: 原始数据和响应对象的发布者
    public func requestRaw(
        endpoint: String,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) -> AnyPublisher<(Data, URLResponse), NetworkError> {
        // 构建完整URL
        let urlString: String
        if endpoint.hasPrefix("http") {
            urlString = endpoint
        } else {
            urlString = Config.API.baseURL + endpoint
        }
        
        guard let url = URL(string: urlString) else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        
        // 检查授权令牌是否已过期（如果请求需要授权）
        if requiresAuth {
            if let token = UserDefaults.standard.string(forKey: Config.UserData.tokenKey) {
                // 检查令牌是否为空字符串或格式明显无效
                if token.isEmpty || token.count < 10 {
                    DRWarning("[NetworkManager] 发现无效令牌，可能已过期")
                    
                    // 删除无效令牌
                    UserDefaults.standard.removeObject(forKey: Config.UserData.tokenKey)
                    UserDefaults.standard.removeObject(forKey: Config.UserData.userIdKey)
                    
                    // 通知认证服务处理token过期
                    DispatchQueue.main.async {
                        AuthService.shared.handleTokenExpired()
                    }
                    
                    return Fail(error: NetworkError.unauthorized("令牌无效，请重新登录")).eraseToAnyPublisher()
                }
            } else {
                // 如果需要授权但没有令牌，直接返回未授权错误
                DRWarning("[NetworkManager] 请求需要授权但未找到令牌")
                
                // 通知认证服务处理token过期
                DispatchQueue.main.async {
                    AuthService.shared.handleTokenExpired()
                }
                
                return Fail(error: NetworkError.unauthorized("未登录或登录已过期")).eraseToAnyPublisher()
            }
        }
        
        // 创建URL请求
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = Config.API.timeout
        
        // 添加通用头部
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("\(Config.App.appName)/\(Config.App.appVersion)", forHTTPHeaderField: "User-Agent")
        
        // 添加认证令牌
        if requiresAuth, let token = UserDefaults.standard.string(forKey: Config.UserData.tokenKey) {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 处理参数
        if let parameters = parameters {
            if method == .get {
                // 对于GET请求，将参数添加到URL中
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
                components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
                if let queryURL = components.url {
                    request.url = queryURL
                }
                DRDebug("[NetworkManager] GET请求参数: \(parameters)")
            } else {
                // 对于其他请求，将参数添加到请求体中
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: parameters)
                    request.httpBody = jsonData
                    
                    // 增加请求参数日志
                    DRDebug("[NetworkManager] \(method.rawValue)请求参数: \(parameters)")
                } catch {
                    DRError("[NetworkManager] 参数序列化失败: \(error.localizedDescription)")
                    return Fail(error: NetworkError.requestFailed(error)).eraseToAnyPublisher()
                }
            }
        }
        
        // 执行请求，直接返回原始的数据和响应对象
        return URLSession.shared.dataTaskPublisher(for: request)
            .mapError { NetworkError.requestFailed($0) }
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                // 打印响应信息
                DRDebug("[NetworkManager] API响应: 状态码=\(httpResponse.statusCode), 数据大小=\(data.count)字节")
                
                // 处理HTTP状态码
                switch httpResponse.statusCode {
                case 200..<300:
                    return (data, response)
                case 400:
                    // 提取具体的400错误信息
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw NetworkError.badRequest(message)
                    } else if let jsonString = String(data: data, encoding: .utf8) {
                        throw NetworkError.badRequest(jsonString)
                    } else {
                        throw NetworkError.badRequest("请求参数错误")
                    }
                case 401:
                    // 清除过期令牌
                    UserDefaults.standard.removeObject(forKey: Config.UserData.tokenKey)
                    UserDefaults.standard.removeObject(forKey: Config.UserData.userIdKey)
                    
                    // 通知认证服务处理token过期
                    DispatchQueue.main.async {
                        AuthService.shared.handleTokenExpired()
                    }
                    
                    // 提取具体的401错误信息
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw NetworkError.unauthorized(message)
                    } else {
                        throw NetworkError.unauthorized("未授权访问")
                    }
                case 404:
                    // 提取具体的404错误信息
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw NetworkError.notFound(message)
                    } else {
                        throw NetworkError.notFound("请求的资源不存在")
                    }
                default:
                    // 尝试解析服务器错误消息
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw NetworkError.serverError(httpResponse.statusCode, message)
                    } else {
                        throw NetworkError.serverError(httpResponse.statusCode, "未知服务器错误")
                    }
                }
            }
            .mapError { error -> NetworkError in
                // 如果错误已经是NetworkError，直接返回即可
                if let networkError = error as? NetworkError {
                    return networkError
                } else {
                    return NetworkError.requestFailed(error)
                }
            }
            .eraseToAnyPublisher()
    }
} 
