import Foundation

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
    case customError(String)
    case businessError(Int, String)
    
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
            return "未授权: \(message)"
        case .notFound(let message):
            return "未找到资源: \(message)"
        case .badRequest(let message):
            return "请求无效: \(message)"
        case .noInternet:
            return "网络连接不可用，请检查您的网络设置"
        case .emptyData:
            return "服务器返回了空数据"
        case .customError(let message):
            return message
        case .businessError(_, let message):
            return message
        }
    }
}

/// 用于处理APIService中网络错误的包装类
struct APINetworkError: Error, CustomStringConvertible {
    let error: NetworkError
    
    var errorMessage: String {
        switch error {
        case .badRequest(let message):
            return "请求无效: \(message)"
        case .unauthorized(let message):
            return "未授权: \(message)"
        case .notFound(let message):
            return "未找到资源: \(message)"
        case .serverError(let code, let message):
            return "服务器错误(\(code)): \(message)"
        case .invalidResponse:
            return "无效的服务器响应"
        case .invalidURL:
            return "无效的URL地址"
        case .noInternet:
            return "网络连接不可用，请检查您的网络设置"
        case .decodingFailed(_):
            return "数据解析失败，请稍后再试"
        case .requestFailed(let underlyingError):
            return "请求失败: \(underlyingError.localizedDescription)"
        case .emptyData:
            return "服务器返回了空数据"
        case .customError(let message):
            return message
        case .businessError(let code, let message):
            return "业务错误(\(code)): \(message)"
        }
    }
    
    var description: String {
        return errorMessage
    }
    
    var isNetworkConnectivityError: Bool {
        if case .noInternet = error { return true }
        if case .requestFailed(let err) = error,
           (err as NSError).domain == NSURLErrorDomain,
           [NSURLErrorNotConnectedToInternet, 
            NSURLErrorNetworkConnectionLost,
            NSURLErrorCannotConnectToHost].contains((err as NSError).code) {
            return true
        }
        return false
    }
    
    var isServerError: Bool {
        if case .serverError = error { return true }
        return false
    }
    
    var isAuthError: Bool {
        if case .unauthorized = error { return true }
        return false
    }
}

/// API服务错误类型
enum APIServiceError: Error, CustomStringConvertible {
    /// 网络相关错误
    case networkError(APINetworkError)
    /// 授权令牌过期
    case tokenExpired
    /// 解码错误
    case decodeError(String)
    /// 未知错误
    case unknown
    
    /// 获取用户友好的错误消息
    var errorMessage: String {
        switch self {
        case .networkError(let error):
            return error.errorMessage
        case .tokenExpired:
            return "登录已过期，请重新登录"
        case .decodeError(let message):
            return "数据解析错误: \(message)"
        case .unknown:
            return "未知错误，请稍后再试"
        }
    }
    
    /// 自定义描述信息，用于日志记录等
    var description: String {
        return "APIServiceError: \(errorMessage)"
    }
    
    /// 判断是否为网络连接错误
    var isNetworkConnectivityIssue: Bool {
        if case .networkError(let error) = self, error.isNetworkConnectivityError {
            return true
        }
        return false
    }
    
    /// 判断是否为服务器错误
    var isServerIssue: Bool {
        if case .networkError(let error) = self, error.isServerError {
            return true
        }
        return false
    }
    
    /// 判断是否为认证相关错误
    var isAuthIssue: Bool {
        if case .tokenExpired = self {
            return true
        }
        if case .networkError(let error) = self, error.isAuthError {
            return true
        }
        return false
    }
} 