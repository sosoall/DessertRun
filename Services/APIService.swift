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
            .tryMap { data, response -> Data in
                // 手动处理HTTP状态码
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                // 打印响应状态码和数据
                print("验证码登录响应: 状态码=\(httpResponse.statusCode), 数据大小=\(data.count)字节")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("响应数据: \(jsonString)")
                }
                
                // 处理HTTP状态码
                switch httpResponse.statusCode {
                case 200..<300:
                    return data
                case 401:
                    // 提取401错误信息
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw NetworkError.unauthorized(message)
                    } else if let errorString = String(data: data, encoding: .utf8) {
                        throw NetworkError.unauthorized("认证失败: \(errorString)")
                    } else {
                        throw NetworkError.unauthorized("认证失败")
                    }
                default:
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw NetworkError.serverError(httpResponse.statusCode, message)
                    } else if let errorString = String(data: data, encoding: .utf8) {
                        throw NetworkError.serverError(httpResponse.statusCode, errorString)
                    } else {
                        throw NetworkError.serverError(httpResponse.statusCode, "服务器错误")
                    }
                }
            }
            .decode(type: AuthResponseWrapper.self, decoder: JSONDecoder())
            .map({ wrapper -> APIUser in
                // 保存令牌
                UserDefaults.standard.set(wrapper.data.token, forKey: Config.UserData.tokenKey)
                
                // 创建并返回APIUser对象
                return APIUser(
                    id: wrapper.data.userID, // 直接使用服务器返回的UUID字符串
                    phone: phone,
                    nickname: nil,
                    avatar: nil,
                    gender: nil,
                    height: nil,
                    weight: nil,
                    hasExerciseHabit: nil,
                    createdAt: nil,
                    updatedAt: nil,
                    isNewUser: wrapper.data.isNewUser,
                    isProfileCompleted: false
                )
            })
            .mapError { error -> APIServiceError in
                print("登录解析错误: \(error)")
                if let networkError = error as? NetworkError {
                    return .networkError(APINetworkError(error: networkError))
                } else {
                    return .networkError(APINetworkError(error: NetworkError.decodingFailed(error)))
                }
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
            .tryMap { data, response -> Data in
                // 手动处理HTTP状态码
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                // 打印响应状态码和数据
                print("密码登录响应: 状态码=\(httpResponse.statusCode), 数据大小=\(data.count)字节")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("响应数据: \(jsonString)")
                }
                
                // 处理HTTP状态码
                switch httpResponse.statusCode {
                case 200..<300:
                    return data
                case 401:
                    // 提取401错误信息
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw NetworkError.unauthorized(message)
                    } else if let errorString = String(data: data, encoding: .utf8) {
                        throw NetworkError.unauthorized("认证失败: \(errorString)")
                    } else {
                        throw NetworkError.unauthorized("认证失败")
                    }
                default:
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw NetworkError.serverError(httpResponse.statusCode, message)
                    } else if let errorString = String(data: data, encoding: .utf8) {
                        throw NetworkError.serverError(httpResponse.statusCode, errorString)
                    } else {
                        throw NetworkError.serverError(httpResponse.statusCode, "服务器错误")
                    }
                }
            }
            .decode(type: AuthResponseWrapper.self, decoder: JSONDecoder())
            .map({ wrapper -> APIUser in
                // 保存令牌
                UserDefaults.standard.set(wrapper.data.token, forKey: Config.UserData.tokenKey)
                
                // 创建并返回APIUser对象
                return APIUser(
                    id: wrapper.data.userID, // 直接使用服务器返回的UUID字符串
                    phone: phone,
                    nickname: nil,
                    avatar: nil,
                    gender: nil,
                    height: nil,
                    weight: nil,
                    hasExerciseHabit: nil,
                    createdAt: nil,
                    updatedAt: nil,
                    isNewUser: wrapper.data.isNewUser,
                    isProfileCompleted: false
                )
            })
            .mapError { error -> APIServiceError in
                print("登录解析错误: \(error)")
                if let networkError = error as? NetworkError {
                    return .networkError(APINetworkError(error: networkError))
                } else {
                    return .networkError(APINetworkError(error: NetworkError.decodingFailed(error)))
                }
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
                                            // APIUser构造函数需要显式指定所有参数
                                            let user = APIUser(
                                                id: UUID().uuidString,
                                                phone: phone,
                                                nickname: nickname,
                                                avatar: nil,
                                                gender: nil,
                                                height: nil,
                                                weight: nil,
                                                hasExerciseHabit: nil,
                                                createdAt: nil,
                                                updatedAt: nil,
                                                isNewUser: nil,
                                                isProfileCompleted: nil
                                            )
                                            promise(.success(user))
                                        }
                                    },
                                    receiveValue: { user in
                                        print("注册成功并获取用户信息: \(user.nickname ?? "未设置昵称")")
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
        if let height = profile.height {
            parameters["height"] = height
        }
        if let weight = profile.weight {
            parameters["weight"] = weight
        }
        if let hasExerciseHabit = profile.hasExerciseHabit {
            parameters["has_exercise_habit"] = hasExerciseHabit
        }
        
        print("发送用户更新请求: \(parameters)")
        
        return networkManager.request(
            endpoint: endpoint,
            method: .put,
            parameters: parameters
        )
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 美食相关API
    
    /// 获取所有美食
    func getAllDesserts() -> AnyPublisher<DessertListResponse, APIServiceError> {
        return processAPIRequest(
            endpoint: "/desserts",
            method: .get,
            parameters: ["all": "true"],
            requiresAuth: false
        )
    }
    
    /// 按分类获取美食
    func getDessertsByCategory(categoryID: String, page: Int = 1, limit: Int = 20) -> AnyPublisher<DessertListResponse, APIServiceError> {
        return processAPIRequest(
            endpoint: "/desserts",
            method: .get,
            parameters: [
                "category_id": categoryID,
                "page": "\(page)",
                "limit": "\(limit)"
            ],
            requiresAuth: false
        )
    }
    
    /// 搜索美食
    func searchDesserts(query: String, limit: Int = 10) -> AnyPublisher<DessertSearchResponse, APIServiceError> {
        return processAPIRequest(
            endpoint: "/desserts/search",
            method: .get,
            parameters: [
                "query": query,
                "limit": "\(limit)"
            ],
            requiresAuth: false
        )
    }
    
    /// 获取美食详情
    func getDessertDetail(id: String) -> AnyPublisher<DessertDetailResponse, APIServiceError> {
        return processAPIRequest(
            endpoint: "/desserts/\(id)",
            method: .get,
            parameters: nil,
            requiresAuth: false
        )
    }
    
    /// 获取美食分类
    func getCategories(parentID: String? = nil) -> AnyPublisher<CategoryListResponse, APIServiceError> {
        var params: [String: String]? = nil
        if let parentID = parentID {
            params = ["parent_id": parentID]
        }
        
        return processAPIRequest(
            endpoint: "/categories",
            method: .get,
            parameters: params,
            requiresAuth: false
        )
    }
    
    // MARK: - 通用请求处理
    
    /// 处理API请求
    private func processAPIRequest<T: Decodable>(endpoint: String, method: HTTPMethod, 
                                              parameters: [String: String]?, 
                                              requiresAuth: Bool = true) -> AnyPublisher<T, APIServiceError> {
        // 构建URL
        var urlComponents = URLComponents(string: Config.API.baseURL + endpoint)
        
        // 添加查询参数(GET请求)
        if method == .get && parameters != nil {
            urlComponents?.queryItems = parameters?.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents?.url else {
            return Fail(error: APIServiceError.unknown).eraseToAnyPublisher()
        }
        
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = Config.API.timeout
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加认证令牌(如果需要)
        if requiresAuth, let token = UserDefaults.standard.string(forKey: Config.UserData.tokenKey) {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 添加请求体(非GET请求)
        if method != .get && parameters != nil {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: parameters as Any)
                request.httpBody = jsonData
            } catch {
                return Fail(error: APIServiceError.unknown).eraseToAnyPublisher()
            }
        }
        
        // 执行请求
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                // 验证HTTP响应
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                // 打印响应信息(调试)
                print("API响应: \(endpoint), 状态码=\(httpResponse.statusCode), 数据大小=\(data.count)字节")
                
                // 根据状态码处理响应
                switch httpResponse.statusCode {
                case 200..<300:
                    return data
                case 400:
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw NetworkError.badRequest(message)
                    } else {
                        throw NetworkError.badRequest("请求参数无效")
                    }
                case 401:
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw NetworkError.unauthorized(message)
                    } else {
                        throw NetworkError.unauthorized("未授权")
                    }
                case 404:
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw NetworkError.notFound(message)
                    } else {
                        throw NetworkError.notFound("资源不存在")
                    }
                default:
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let message = json["message"] as? String {
                        throw NetworkError.serverError(httpResponse.statusCode, message)
                    } else {
                        throw NetworkError.serverError(httpResponse.statusCode, "服务器错误")
                    }
                }
            }
            .decode(type: APIResponse<T>.self, decoder: JSONDecoder())
            .map { $0.data }
            .mapError { error -> APIServiceError in
                if let networkError = error as? NetworkError {
                    return .networkError(APINetworkError(error: networkError))
                } else if let decodingError = error as? DecodingError {
                    return .networkError(APINetworkError(error: .decodingFailed(decodingError)))
                } else {
                    return .networkError(APINetworkError(error: .unknown(error)))
                }
            }
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
struct APINetworkError: Error {
    let error: NetworkError
    
    var errorMessage: String {
        switch error {
        case .badRequest(let message):
            return message
        case .unauthorized(let message):
            return message
        case .notFound(let message):
            return message
        case .serverError(_, let message):
            return message
        case .invalidResponse:
            return "无效的响应"
        case .decodingFailed(_):
            return "数据解析失败"
        case .unknown(_):
            return "未知错误"
        }
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
    let id: String
    let phone: String
    let nickname: String?
    let avatar: String?
    let gender: String?  // 从服务器接收时仍为String类型("男"/"女")
    let height: Double?  // 添加身高字段
    let weight: Double?  // 添加体重字段
    let hasExerciseHabit: Bool?  // 添加运动习惯字段
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
        case height
        case weight
        case hasExerciseHabit = "has_exercise_habit"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isNewUser = "is_new_user"
        case isProfileCompleted = "is_profile_completed"
    }
    
    // 添加直接初始化方法，方便创建实例
    init(id: String, phone: String, nickname: String?, avatar: String?, gender: String?,
         height: Double?, weight: Double?, hasExerciseHabit: Bool?,
         createdAt: String?, updatedAt: String?, isNewUser: Bool?, isProfileCompleted: Bool?) {
        self.id = id
        self.phone = phone
        self.nickname = nickname
        self.avatar = avatar
        self.gender = gender
        self.height = height
        self.weight = weight
        self.hasExerciseHabit = hasExerciseHabit
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isNewUser = isNewUser
        self.isProfileCompleted = isProfileCompleted
    }
    
    // 自定义解码初始化方法
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        phone = try container.decode(String.self, forKey: .phone)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        height = try container.decodeIfPresent(Double.self, forKey: .height)
        weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        hasExerciseHabit = try container.decodeIfPresent(Bool.self, forKey: .hasExerciseHabit)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        isNewUser = try container.decodeIfPresent(Bool.self, forKey: .isNewUser)
        isProfileCompleted = try container.decodeIfPresent(Bool.self, forKey: .isProfileCompleted)
    }
    
    /// 将APIUser转换为本地User模型
    func toLocalUser() -> User {
        // 根据性别字符串转换为枚举
        let userGender: User.Gender?
        if let gender = gender {
            userGender = User.Gender.fromApiString(gender)
        } else {
            userGender = nil
        }
        
        let user = User(
            phoneNumber: phone,
            nickname: nickname,
            avatar: avatar,
            gender: userGender,
            height: height,
            weight: weight,
            hasExerciseHabit: hasExerciseHabit,
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
    let gender: String?  // 修改为String类型，值应为"男"或"女"
    let height: Double?
    let weight: Double?
    let hasExerciseHabit: Bool?
}

/// API响应通用格式
struct APIResponse<T: Decodable>: Decodable {
    let code: Int
    let message: String
    let data: T
} 