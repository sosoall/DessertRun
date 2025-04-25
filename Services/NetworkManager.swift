import Foundation
import Combine

/// 网络错误类型
enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case serverError(Int, String)
    case decodingFailed(Error)
    case unauthorized
    case notFound
    case noInternet
    case emptyData
    
    var errorMessage: String {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .requestFailed(let error):
            return "请求失败: \(error.localizedDescription)"
        case .invalidResponse:
            return "无效的服务器响应"
        case .serverError(let code, let message):
            return "服务器错误 (\(code)): \(message)"
        case .decodingFailed(let error):
            return "数据解析失败: \(error.localizedDescription)"
        case .unauthorized:
            return "请先登录"
        case .notFound:
            return "请求的资源不存在"
        case .noInternet:
            return "网络连接不可用，请检查您的网络设置"
        case .emptyData:
            return "服务器返回了空数据"
        }
    }
}

/// API响应结构
struct APIResponse<T: Decodable>: Decodable {
    let code: Int
    let message: String
    let data: T?
    
    var success: Bool {
        return code == 0
    }
}

/// 空数据响应类型
struct EmptyResponseData: Decodable {}

/// HTTP请求方法
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

/// 网络管理器
class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}
    
    /// 创建API请求
    /// - Parameters:
    ///   - endpoint: API端点路径
    ///   - method: HTTP方法
    ///   - parameters: 请求参数
    ///   - requiresAuth: 是否需要认证令牌
    /// - Returns: 包含解码后数据的发布者
    func request<T: Decodable>(
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
                case 401:
                    throw NetworkError.unauthorized
                case 404:
                    throw NetworkError.notFound
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
                        throw NetworkError.serverError(httpResponse.statusCode, "未知服务器错误")
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
                
                // 创建一个特殊情况处理器，处理无内容响应的情况
                if T.self == EmptyResponseData.self {
                    return Just(EmptyResponseData() as! T)
                        .setFailureType(to: NetworkError.self)
                        .eraseToAnyPublisher()
                }
                
                // 尝试解析为API标准响应格式
                return Just(data)
                    .decode(type: APIResponse<T>.self, decoder: decoder)
                    .mapError { NetworkError.decodingFailed($0) }
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
                        if let _ = error as? DecodingError {
                            return Just(data)
                                .decode(type: T.self, decoder: decoder)
                                .mapError { NetworkError.decodingFailed($0) }
                                .eraseToAnyPublisher()
                        }
                        return Fail(error: error)
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
} 