import Foundation
import Combine

/// 空数据响应类型，用于没有返回数据的API
public struct EmptyResponseData: Decodable {}

/// 网络错误类型
public enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case serverError(Int, String)
    case decodingFailed(Error)
    case unauthorized(String)
    case notFound(String)
    case badRequest(String)
    case noInternet
    case emptyData
    
    public var errorMessage: String {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .requestFailed(let error):
            return "请求失败: \(error.localizedDescription)"
        case .invalidResponse:
            return "无效的服务器响应"
        case .serverError(_, let message):
            return message
        case .decodingFailed(let error):
            return "数据解析失败: \(error.localizedDescription)"
        case .unauthorized(let message):
            return message
        case .notFound(let message):
            return message
        case .badRequest(let message):
            return message
        case .noInternet:
            return "网络连接不可用，请检查您的网络设置"
        case .emptyData:
            return "服务器返回了空数据"
        }
    }
}

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
        if let dataContainer = try? container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .data) {
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
            } else {
                // 对于其他请求，将参数添加到请求体中
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
                } catch {
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
                
                // 处理HTTP状态码
                switch httpResponse.statusCode {
                case 200..<300:
                    return data
                case 400:
                    // 提取具体的400错误信息
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw NetworkError.badRequest(message)
                    } else {
                        throw NetworkError.badRequest("请求参数错误")
                    }
                case 401:
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
                if let networkError = error as? NetworkError {
                    return networkError
                } else {
                    return NetworkError.requestFailed(error)
                }
            }
            .flatMap { (data: Data) -> AnyPublisher<T, NetworkError> in
                // 尝试解析为API响应格式
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
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
                
                // 尝试解析为API标准响应格式
                return Just(data)
                    .decode(type: APIResponse<T>.self, decoder: decoder)
                    .mapError { error -> NetworkError in
                        DRError("[NetworkManager] 解析API响应失败: \(error.localizedDescription)")
                        if let decodingError = error as? DecodingError {
                            switch decodingError {
                            case .keyNotFound(let key, let context):
                                DRError("[NetworkManager] 找不到键: \(key.stringValue), 路径: \(context.codingPath.map { $0.stringValue })")
                            case .valueNotFound(let type, let context):
                                DRError("[NetworkManager] 找不到\(type)类型的值, 路径: \(context.codingPath.map { $0.stringValue })")
                            case .typeMismatch(let type, let context):
                                DRError("[NetworkManager] 类型不匹配: 期望\(type), 路径: \(context.codingPath.map { $0.stringValue })")
                            case .dataCorrupted(let context):
                                DRError("[NetworkManager] 数据损坏: \(context)")
                            @unknown default:
                                DRError("[NetworkManager] 未知解码错误: \(decodingError)")
                            }
                        }
                        return NetworkError.decodingFailed(error)
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
                        if let networkError = error as? NetworkError {
                            return networkError
                        } else {
                            return NetworkError.decodingFailed(error)
                        }
                    }
                    .catch { error -> AnyPublisher<T, NetworkError> in
                        // 如果不是标准响应格式，尝试直接解析为目标类型
                        DRInfo("[NetworkManager] 尝试直接解析为目标类型 \(T.self)")
                        // 检查是否为解码错误
                        if case .decodingFailed(let decodingError) = error,
                           decodingError is DecodingError {
                            return Just(data)
                                .decode(type: T.self, decoder: decoder)
                                .mapError { decodingError -> NetworkError in
                                    DRError("[NetworkManager] 直接解析失败: \(decodingError.localizedDescription)")
                                    return NetworkError.decodingFailed(decodingError)
                                }
                                .eraseToAnyPublisher()
                        }
                        return Fail(error: error)
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
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
} 