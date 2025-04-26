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
        
        // 创建URL请求
        let urlString = Config.API.baseURL + endpoint
        guard let url = URL(string: urlString) else {
            return Fail(error: APIServiceError.unknown).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = Config.API.timeout
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加请求体
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            return Fail(error: APIServiceError.unknown).eraseToAnyPublisher()
        }
        
        // 执行请求并手动解析响应
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: AuthResponseWrapper.self, decoder: JSONDecoder())
            .map { wrapper -> APIUser in
                // 保存令牌
                UserDefaults.standard.set(wrapper.data.token, forKey: Config.UserData.tokenKey)
                
                // 创建并返回APIUser对象
                let userId = wrapper.data.uuid?.hashValue ?? Int.random(in: 1000...9999)
                return APIUser(
                    id: userId,
                    phone: phone,
                    nickname: nil,
                    avatar: nil,
                    gender: nil,
                    createdAt: nil,
                    updatedAt: nil,
                    isNewUser: wrapper.data.isNewUser,
                    isProfileCompleted: false
                )
            }
            .mapError { error -> APIServiceError in
                print("登录解析错误: \(error)")
                return .networkError(APINetworkError(error: NetworkError.decodingFailed(error)))
            }
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
        
        // 创建URL请求
        let urlString = Config.API.baseURL + endpoint
        guard let url = URL(string: urlString) else {
            return Fail(error: APIServiceError.unknown).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = Config.API.timeout
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加请求体
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            return Fail(error: APIServiceError.unknown).eraseToAnyPublisher()
        }
        
        // 执行请求并手动解析响应
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { $0.data }
            .decode(type: AuthResponseWrapper.self, decoder: JSONDecoder())
            .map { wrapper -> APIUser in
                // 保存令牌
                UserDefaults.standard.set(wrapper.data.token, forKey: Config.UserData.tokenKey)
                
                // 创建并返回APIUser对象
                let userId = wrapper.data.uuid?.hashValue ?? Int.random(in: 1000...9999)
                return APIUser(
                    id: userId,
                    phone: phone,
                    nickname: nil,
                    avatar: nil,
                    gender: nil,
                    createdAt: nil,
                    updatedAt: nil,
                    isNewUser: wrapper.data.isNewUser,
                    isProfileCompleted: false
                )
            }
            .mapError { error -> APIServiceError in
                print("登录解析错误: \(error)")
                return .networkError(APINetworkError(error: NetworkError.decodingFailed(error)))
            }
            .eraseToAnyPublisher()
    }
    
    /// 注册新用户
    /// - Parameters:
    ///   - phone: 手机号
    ///   - password: 密码
    ///   - confirmPassword: 确认密码
    ///   - code: 验证码
    ///   - nickname: 昵称
    /// - Returns: 包含用户信息的发布者
    func register(phone: String, password: String, confirmPassword: String, code: String, nickname: String) -> AnyPublisher<APIUser, APIServiceError> {
        let endpoint = "/api/v1/auth/register"
        let parameters: [String: Any] = [
            "phone_number": phone,
            "password": password,
            "confirm_password": confirmPassword,
            "code": code,
            "nickname": nickname
        ]
        
        // 创建一个Publisher，处理注册请求和响应
        return Deferred {
            Future<APIUser, APIServiceError> { promise in
                // 执行原始注册请求
                self.networkManager.request(
                    endpoint: endpoint,
                    method: .post,
                    parameters: parameters,
                    requiresAuth: false
                )
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            // 处理注册成功但没有receiveValue的情况
                            // 注册成功后，自动登录
                            self.loginWithPassword(phone: phone, password: password)
                                .sink(
                                    receiveCompletion: { loginCompletion in
                                        if case let .failure(error) = loginCompletion {
                                            print("注册成功后登录失败: \(error.errorMessage)")
                                            // 登录失败但注册成功
                                            // 创建一个基本用户对象
                                            let user = APIUser(
                                                id: -1, // 临时ID
                                                phone: phone,
                                                nickname: nickname,
                                                avatar: nil,
                                                gender: nil,
                                                createdAt: nil,
                                                updatedAt: nil,
                                                isNewUser: nil,
                                                isProfileCompleted: nil
                                            )
                                            promise(.success(user))
                                        }
                                    },
                                    receiveValue: { user in
                                        print("注册成功并获取用户信息: \(user.nickname)")
                                        promise(.success(user))
                                    }
                                )
                                .store(in: &self.cancellables)
                        case .failure(let error):
                            print("注册失败: \(error)")
                            promise(.failure(self.handleError(error)))
                        }
                    },
                    receiveValue: { (_: EmptyResponse) in
                        print("注册API调用成功")
                        // 这里不做任何事情，因为我们将在receiveCompletion的.finished分支中处理
                    }
                )
                .store(in: &self.cancellables)
            }
        }
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
        case .unauthorized(let message):
            // 只有消息明确提到"过期"或"token"时才认为是token过期
            if message.contains("过期") || message.contains("token") || message.contains("Token") {
                // 清除本地令牌
                UserDefaults.standard.removeObject(forKey: Config.UserData.tokenKey)
                UserDefaults.standard.removeObject(forKey: Config.UserData.userIdKey)
                // 处理token过期，通知显示登录页面
                DispatchQueue.main.async {
                    AuthService.shared.handleTokenExpired()
                }
                return .tokenExpired
            } else {
                // 其他401错误，如密码错误、用户不存在等
                return .networkError(APINetworkError(error: error))
            }
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

/// 认证响应数据
struct AuthResponseData: Decodable {
    let token: String
    let userID: String
    let isNewUser: Bool
    
    enum CodingKeys: String, CodingKey {
        case token
        case userID = "user_id"
        case isNewUser = "is_new_user"
    }
    
    var uuid: UUID? {
        return UUID(uuidString: userID)
    }
}

/// 认证响应包装器（用于直接解析完整的API响应）
struct AuthResponseWrapper: Decodable {
    let code: Int
    let message: String
    let data: AuthResponseData
}

/// API用户模型
struct APIUser: Decodable, Identifiable {
    let id: Int
    let phone: String
    let nickname: String?
    let avatar: String?
    let gender: Int?
    let createdAt: String?
    let updatedAt: String?
    let isNewUser: Bool?
    let isProfileCompleted: Bool?
    
    // 定义CodingKeys来处理字段名称映射
    enum CodingKeys: String, CodingKey {
        case id
        case phone = "phone_number"
        case nickname
        case avatar
        case gender
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isNewUser = "is_new_user"
        case isProfileCompleted = "is_profile_completed"
    }
    
    /// 将APIUser转换为本地User模型
    func toLocalUser() -> User {
        let user = User(
            phoneNumber: phone,
            nickname: nickname,
            avatar: avatar,
            gender: gender != nil ? User.Gender.fromApiValue(gender!) : nil,
            isProfileCompleted: isProfileCompleted ?? false,
            isNewUser: isNewUser ?? true,
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