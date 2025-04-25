import Foundation
import Combine

/// API服务错误类型
enum APIServiceError: Error {
    case networkError(APINetworkError)
    case tokenExpired
    case unknown
    
    var errorMessage: String {
        switch self {
        case .networkError(let error):
            return error.errorMessage
        case .tokenExpired:
            return "登录已过期，请重新登录"
        case .unknown:
            return "未知错误"
        }
    }
}

/// API服务类
class APIService {
    static let shared = APIService()
    
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - 授权相关 API
    
    /// 获取验证码
    /// - Parameter phone: 手机号
    /// - Returns: 包含请求结果的发布者
    func getVerificationCode(phone: String) -> AnyPublisher<Void, APIServiceError> {
        let endpoint = "/api/v1/auth/verification-code"
        let parameters = ["phone_number": phone]
        
        return networkManager.request(
            endpoint: endpoint,
            method: .post,
            parameters: parameters,
            requiresAuth: false
        )
        .map { (_: EmptyResponse) -> Void in return }
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
    
    /// 验证码登录
    /// - Parameters:
    ///   - phone: 手机号
    ///   - code: 验证码
    /// - Returns: 包含用户信息的发布者
    func loginWithVerificationCode(phone: String, code: String) -> AnyPublisher<APIUser, APIServiceError> {
        let endpoint = "/api/v1/auth/login"
        let parameters = [
            "phone_number": phone,
            "code": code
        ]
        
        return networkManager.request(
            endpoint: endpoint,
            method: .post,
            parameters: parameters,
            requiresAuth: false
        )
        .map { (response: AuthResponse) -> APIUser in
            // 保存令牌
            UserDefaults.standard.set(response.token, forKey: Config.UserData.tokenKey)
            UserDefaults.standard.set(response.user.id, forKey: Config.UserData.userIdKey)
            return response.user
        }
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
    
    /// 密码登录
    /// - Parameters:
    ///   - phone: 手机号
    ///   - password: 密码
    /// - Returns: 包含用户信息的发布者
    func loginWithPassword(phone: String, password: String) -> AnyPublisher<APIUser, APIServiceError> {
        let endpoint = "/api/v1/auth/login-password"
        let parameters = [
            "phone_number": phone,
            "password": password
        ]
        
        return networkManager.request(
            endpoint: endpoint,
            method: .post,
            parameters: parameters,
            requiresAuth: false
        )
        .map { (response: AuthResponse) -> APIUser in
            // 保存令牌
            UserDefaults.standard.set(response.token, forKey: Config.UserData.tokenKey)
            UserDefaults.standard.set(response.user.id, forKey: Config.UserData.userIdKey)
            return response.user
        }
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
    
    /// 注册新用户
    /// - Parameters:
    ///   - phone: 手机号
    ///   - password: 密码
    ///   - code: 验证码
    ///   - nickname: 昵称
    /// - Returns: 包含用户信息的发布者
    func register(phone: String, password: String, code: String, nickname: String) -> AnyPublisher<APIUser, APIServiceError> {
        let endpoint = "/api/v1/auth/register"
        let parameters: [String: Any] = [
            "phone_number": phone,
            "password": password,
            "code": code,
            "nickname": nickname
        ]
        
        return networkManager.request(
            endpoint: endpoint,
            method: .post,
            parameters: parameters,
            requiresAuth: false
        )
        .map { (response: AuthResponse) -> APIUser in
            // 保存令牌
            UserDefaults.standard.set(response.token, forKey: Config.UserData.tokenKey)
            UserDefaults.standard.set(response.user.id, forKey: Config.UserData.userIdKey)
            return response.user
        }
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 用户相关 API
    
    /// 获取用户个人资料
    /// - Returns: 包含用户信息的发布者
    func getUserProfile() -> AnyPublisher<APIUser, APIServiceError> {
        let endpoint = "/api/v1/users/profile"
        
        return networkManager.request(
            endpoint: endpoint,
            method: .get
        )
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
    
    /// 更新用户资料
    /// - Parameter profile: 用户资料
    /// - Returns: 包含更新后用户信息的发布者
    func updateUserProfile(profile: UpdateProfileRequest) -> AnyPublisher<APIUser, APIServiceError> {
        let endpoint = "/api/v1/users/profile"
        
        var parameters: [String: Any] = [:]
        if let nickname = profile.nickname {
            parameters["nickname"] = nickname
        }
        if let avatar = profile.avatar {
            parameters["avatar"] = avatar
        }
        if let gender = profile.gender {
            parameters["gender"] = gender
        }
        
        return networkManager.request(
            endpoint: endpoint,
            method: .put,
            parameters: parameters
        )
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 私有辅助方法
    
    /// 处理网络错误
    /// - Parameter error: 网络错误
    /// - Returns: API服务错误
    private func handleError(_ error: NetworkError) -> APIServiceError {
        switch error {
        case .unauthorized:
            // 清除本地令牌
            UserDefaults.standard.removeObject(forKey: Config.UserData.tokenKey)
            UserDefaults.standard.removeObject(forKey: Config.UserData.userIdKey)
            // 处理token过期，通知显示登录页面
            DispatchQueue.main.async {
                AuthService.shared.handleTokenExpired()
            }
            return .tokenExpired
        default:
            return .networkError(APINetworkError(error: error))
        }
    }
}

// MARK: - 数据模型

/// 用于处理APIService中网络错误的包装类
struct APINetworkError {
    let error: NetworkError
    
    var errorMessage: String {
        return error.errorMessage
    }
}

/// 空响应类型（用于没有返回数据的API）
typealias EmptyResponse = EmptyResponseData

/// 认证响应
struct AuthResponse: Decodable {
    let token: String
    let user: APIUser
}

/// API用户模型
struct APIUser: Decodable, Identifiable {
    let id: Int
    let phone: String
    let nickname: String
    let avatar: String?
    let gender: Int?
    let createdAt: String
    let updatedAt: String
    
    /// 将APIUser转换为本地User模型
    func toLocalUser() -> User {
        let user = User(
            phoneNumber: phone,
            nickname: nickname,
            avatar: avatar,
            gender: gender != nil ? User.Gender.fromApiValue(gender!) : nil,
            isProfileCompleted: true,
            apiUserId: id
        )
        return user
    }
}

/// 更新用户资料请求
struct UpdateProfileRequest {
    let nickname: String?
    let avatar: String?
    let gender: Int?
} 