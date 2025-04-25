import Foundation
import Combine

/// 网络请求结果类型
enum NetworkResult<T> {
    case success(T)
    case failure(ServiceNetworkError)
}

/// 网络服务的错误类型
enum ServiceNetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    case serverError(Int, String)
    case networkUnavailable
    case unauthorized
    case unknown
    
    var errorMessage: String {
        switch self {
        case .invalidURL:
            return "无效的URL"
        case .requestFailed(let error):
            return "请求失败: \(error.localizedDescription)"
        case .invalidResponse:
            return "无效的响应"
        case .decodingFailed(let error):
            return "数据解析失败: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "服务器错误: \(code) - \(message)"
        case .networkUnavailable:
            return "网络连接不可用"
        case .unauthorized:
            return "未授权，请重新登录"
        case .unknown:
            return "未知错误"
        }
    }
}

/// API响应基础结构
struct ApiResponse<T: Decodable>: Decodable {
    let code: Int
    let message: String
    let data: T?
}

/// 空请求体类型，用于不需要请求体的API调用
struct EmptyBody: Encodable {}

/// 网络服务，处理与后端API的通信
class NetworkService {
    
    // 单例实例
    static let shared = NetworkService()
    
    // 基础URL
    private let baseURL = "http://localhost:8080"
    
    // 存储JWT令牌
    private var token: String?
    
    private init() {}
    
    /// 设置认证令牌
    func setToken(_ token: String) {
        self.token = token
    }
    
    /// 清除认证令牌
    func clearToken() {
        self.token = nil
    }
    
    /// 执行GET请求
    /// - Parameters:
    ///   - endpoint: API端点路径
    ///   - queryParams: 查询参数
    /// - Returns: 包含解码后数据的Future
    func get<T: Decodable>(_ endpoint: String, queryParams: [String: String]? = nil) -> Future<T, ServiceNetworkError> {
        return request(endpoint, method: "GET", queryParams: queryParams, body: EmptyBody())
    }
    
    /// 执行POST请求
    /// - Parameters:
    ///   - endpoint: API端点路径
    ///   - body: 请求体
    /// - Returns: 包含解码后数据的Future
    func post<T: Decodable, U: Encodable>(_ endpoint: String, body: U) -> Future<T, ServiceNetworkError> {
        return request(endpoint, method: "POST", body: body)
    }
    
    /// 执行PUT请求
    /// - Parameters:
    ///   - endpoint: API端点路径
    ///   - body: 请求体
    /// - Returns: 包含解码后数据的Future
    func put<T: Decodable, U: Encodable>(_ endpoint: String, body: U) -> Future<T, ServiceNetworkError> {
        return request(endpoint, method: "PUT", body: body)
    }
    
    /// 执行DELETE请求
    /// - Parameters:
    ///   - endpoint: API端点路径
    /// - Returns: 包含解码后数据的Future
    func delete<T: Decodable>(_ endpoint: String) -> Future<T, ServiceNetworkError> {
        return request(endpoint, method: "DELETE", body: EmptyBody())
    }
    
    /// 通用请求方法
    /// - Parameters:
    ///   - endpoint: API端点路径
    ///   - method: HTTP方法
    ///   - queryParams: 查询参数
    ///   - body: 请求体
    /// - Returns: 包含解码后数据的Future
    private func request<T: Decodable, U: Encodable>(_ endpoint: String, 
                                                    method: String, 
                                                    queryParams: [String: String]? = nil, 
                                                    body: U? = nil) -> Future<T, ServiceNetworkError> {
        return Future { promise in
            // 构建URL
            guard var components = URLComponents(string: self.baseURL + endpoint) else {
                promise(.failure(.invalidURL))
                return
            }
            
            // 添加查询参数
            if let queryParams = queryParams {
                components.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
            }
            
            guard let url = components.url else {
                promise(.failure(.invalidURL))
                return
            }
            
            // 创建请求
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // 添加认证头
            if let token = self.token {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            // 添加请求体
            if let body = body {
                do {
                    request.httpBody = try JSONEncoder().encode(body)
                } catch {
                    promise(.failure(.requestFailed(error)))
                    return
                }
            }
            
            // 执行请求
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                // 处理网络错误
                if let error = error {
                    promise(.failure(.requestFailed(error)))
                    return
                }
                
                // 检查HTTP响应
                guard let httpResponse = response as? HTTPURLResponse else {
                    promise(.failure(.invalidResponse))
                    return
                }
                
                // 检查状态码
                switch httpResponse.statusCode {
                case 200...299:
                    // 成功响应
                    guard let data = data else {
                        promise(.failure(.invalidResponse))
                        return
                    }
                    
                    do {
                        // 尝试将响应解析为ApiResponse
                        let apiResponse = try JSONDecoder().decode(ApiResponse<T>.self, from: data)
                        
                        // 检查业务状态码
                        if apiResponse.code == 200, let responseData = apiResponse.data {
                            promise(.success(responseData))
                        } else {
                            promise(.failure(.serverError(apiResponse.code, apiResponse.message)))
                        }
                    } catch {
                        // 尝试直接解析为T
                        do {
                            let decodedData = try JSONDecoder().decode(T.self, from: data)
                            promise(.success(decodedData))
                        } catch {
                            promise(.failure(.decodingFailed(error)))
                        }
                    }
                    
                case 401:
                    promise(.failure(.unauthorized))
                    
                default:
                    promise(.failure(.serverError(httpResponse.statusCode, "服务器错误")))
                }
            }
            
            task.resume()
        }
    }
} 