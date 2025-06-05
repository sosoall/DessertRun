import Foundation
import Combine
import SwiftUI
import AVFoundation
import UIKit

// 导入API错误类型
// 确保导入我们新创建的文件
// 导入定义的错误类型

// 直接导入APIRequestModels文件（如果需要特别导入）
// import APIRequestModels

// MARK: - API响应模型

// 注意：API响应类型定义在DessertRun/Models/DessertAPIModels.swift文件中
// 包括：DessertListResponse、DessertSearchResponse、DessertDetailResponse、CategoryListResponse

/// API服务类
class APIService {
    static let shared = APIService()
    
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // 添加跳过缓存的控制变量
    private var skipCache: Bool = false
    
    private init() {}
    
    /// 设置是否跳过缓存
    /// - Parameter skip: 是否跳过缓存
    func setSkipCache(_ skip: Bool) {
        skipCache = skip
        DRDebug("[APIService] 设置skipCache=\(skip)")
    }
    
    // MARK: - 处理错误的私有方法
    
    /// 处理网络错误
    /// - Parameter error: 网络错误
    /// - Returns: API服务错误
    private func handleError(_ error: NetworkError) -> APIServiceError {
        // 处理token过期情况
        if case .unauthorized(let message) = error {
            DRInfo("检测到401错误: \(message)")
            // 清除本地令牌
            UserDefaults.standard.removeObject(forKey: Config.UserData.tokenKey)
            UserDefaults.standard.removeObject(forKey: Config.UserData.userIdKey)
            
            // 通知认证服务处理token过期
            DispatchQueue.main.async {
                AuthService.shared.handleTokenExpired()
            }
            return .tokenExpired
        }
        
        // 处理401场景，但被包装成serverError而非unauthorized
        if case .serverError(let status, let message) = error, status == 401 {
            DRInfo("检测到401 serverError: \(message)")
            // 清除本地令牌
            UserDefaults.standard.removeObject(forKey: Config.UserData.tokenKey)
            UserDefaults.standard.removeObject(forKey: Config.UserData.userIdKey)
            DispatchQueue.main.async {
                AuthService.shared.handleTokenExpired()
            }
            return .tokenExpired
        }
        
        // 处理其他所有网络错误
        return .networkError(APINetworkError(error: error))
    }
    
    /// 处理API错误（从data和response）
    private func handleError(data: Data, response: URLResponse) -> APIServiceError {
        if let httpResponse = response as? HTTPURLResponse {
            // 尝试从响应数据中提取错误信息
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = json["message"] as? String {
                
                switch httpResponse.statusCode {
                case 401:
                    DRInfo("检测到401错误状态码: \(message)")
                    // 清除本地令牌
                    UserDefaults.standard.removeObject(forKey: Config.UserData.tokenKey)
                    UserDefaults.standard.removeObject(forKey: Config.UserData.userIdKey)
                    
                    // 通知认证服务处理token过期
                    DispatchQueue.main.async {
                        AuthService.shared.handleTokenExpired()
                    }
                    return .tokenExpired
                case 400..<500:
                    return .networkError(APINetworkError(error: .serverError(httpResponse.statusCode, message)))
                default:
                    return .networkError(APINetworkError(error: .serverError(httpResponse.statusCode, message)))
                }
            } else {
                // 如果无法提取错误信息，则使用状态码生成通用错误
                if httpResponse.statusCode == 401 {
                    DRInfo("检测到401错误状态码（无消息）")
                    // 清除本地令牌
                    UserDefaults.standard.removeObject(forKey: Config.UserData.tokenKey)
                    UserDefaults.standard.removeObject(forKey: Config.UserData.userIdKey)
                    
                    // 通知认证服务处理token过期
                    DispatchQueue.main.async {
                        AuthService.shared.handleTokenExpired()
                    }
                    return .tokenExpired
                }
                return .networkError(APINetworkError(error: .serverError(httpResponse.statusCode, "服务器返回错误：\(httpResponse.statusCode)")))
            }
        } else {
            // 如果不是HTTP响应，则返回未知错误
            return .unknown
        }
    }
    
    /// 处理通用API请求错误
    private func handleAPIError(_ error: Error) -> APIServiceError {
        if let networkError = error as? NetworkError {
            return .networkError(APINetworkError(error: networkError))
        } else if let decodingError = error as? DecodingError {
            return .decodeError(decodingError.localizedDescription)
        } else {
            return .unknown
        }
    }
    
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
                    birthYear: nil,
                    createdAt: nil,
                    updatedAt: nil,
                    isNewUser: wrapper.data.isNewUser,
                    isProfileCompleted: false
                )
            })
            .mapError { error -> APIServiceError in
                print("登录解析错误: \(error)")
                if let networkError = error as? NetworkError {
                    // 针对网络错误进行特殊处理
                    if case .unauthorized = networkError {
                        return self.handleError(networkError)
                    } else {
                        return .networkError(APINetworkError(error: networkError))
                    }
                } else if let decodingError = error as? DecodingError {
                    // 针对解码错误提供详细的日志
                    DRError("[APIService] 数据解析错误: \(decodingError)")
                    
                    // 根据解码错误类型提供更具体的信息
                    switch decodingError {
                    case .keyNotFound(let key, _):
                        DRError("[APIService] 找不到键: \(key.stringValue)")
                    case .valueNotFound(let type, _):
                        DRError("[APIService] 找不到值，期望类型: \(type)")
                    case .typeMismatch(let type, _):
                        DRError("[APIService] 类型不匹配，期望类型: \(type)")
                    default:
                        break
                    }
                    
                    return .networkError(APINetworkError(error: .decodingFailed(decodingError)))
                } else {
                    // 处理其他未知错误
                    DRError("[APIService] 未知错误: \(error)")
                    return .unknown
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
                    birthYear: nil,
                    createdAt: nil,
                    updatedAt: nil,
                    isNewUser: wrapper.data.isNewUser,
                    isProfileCompleted: false
                )
            })
            .mapError { error -> APIServiceError in
                print("登录解析错误: \(error)")
                if let networkError = error as? NetworkError {
                    // 针对网络错误进行特殊处理
                    if case .unauthorized = networkError {
                        return self.handleError(networkError)
                    } else {
                        return .networkError(APINetworkError(error: networkError))
                    }
                } else if let decodingError = error as? DecodingError {
                    // 针对解码错误提供详细的日志
                    DRError("[APIService] 数据解析错误: \(decodingError)")
                    
                    // 根据解码错误类型提供更具体的信息
                    switch decodingError {
                    case .keyNotFound(let key, _):
                        DRError("[APIService] 找不到键: \(key.stringValue)")
                    case .valueNotFound(let type, _):
                        DRError("[APIService] 找不到值，期望类型: \(type)")
                    case .typeMismatch(let type, _):
                        DRError("[APIService] 类型不匹配，期望类型: \(type)")
                    default:
                        break
                    }
                    
                    return .networkError(APINetworkError(error: .decodingFailed(decodingError)))
                } else {
                    // 处理其他未知错误
                    DRError("[APIService] 未知错误: \(error)")
                    return .unknown
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
                                                birthYear: nil,
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
    
    /// 更新用户基本信息（昵称、头像、性别等）
    /// - Parameter info: 用户基本信息
    /// - Returns: 包含更新后用户基本信息的发布者
    func updateUserBasicInfo(info: UpdateBasicInfoRequest) -> AnyPublisher<UserBasicInfoResponse, APIServiceError> {
        let endpoint = ApiEndpoints.User.basicInfo
        
        var parameters: [String: Any] = [:]
        if let nickname = info.nickname {
            parameters["nickname"] = nickname
        }
        if let avatar = info.avatar {
            parameters["avatar"] = avatar
        }
        if let gender = info.gender {
            parameters["gender"] = gender
        }
        if let birthYear = info.birthYear {
            parameters["birth_year"] = birthYear
        }
        
        print("发送用户基本信息更新请求: \(parameters)")
        
        return networkManager.request(
            endpoint: endpoint,
            method: .put,
            parameters: parameters
        )
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
    
    /// 获取用户基本信息
    /// - Returns: 包含用户基本信息的发布者
    func getUserBasicInfo() -> AnyPublisher<UserBasicInfoResponse, APIServiceError> {
        let endpoint = ApiEndpoints.User.basicInfo
        
        return networkManager.request(
            endpoint: endpoint,
            method: .get
        )
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
    
    /// 更新用户身体数据（身高、体重）
    /// - Parameter bodyData: 用户身体数据
    /// - Returns: 包含更新后用户身体数据的发布者
    func updateUserBodyData(bodyData: UpdateBodyDataRequest) -> AnyPublisher<UserBodyDataResponse, APIServiceError> {
        let endpoint = ApiEndpoints.User.bodyData
        
        var parameters: [String: Any] = [:]
        if let height = bodyData.height {
            parameters["height"] = height
        }
        if let weight = bodyData.weight {
            parameters["weight"] = weight
        }
        
        print("发送用户身体数据更新请求: \(parameters)")
        
        return networkManager.request(
            endpoint: endpoint,
            method: .post,
            parameters: parameters
        )
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
    
    /// 获取用户身体数据
    /// - Returns: 包含用户身体数据的发布者
    func getUserBodyData() -> AnyPublisher<UserBodyDataResponse, APIServiceError> {
        let endpoint = ApiEndpoints.User.bodyData + "/latest"
        
        return networkManager.request(
            endpoint: endpoint,
            method: .get
        )
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
    
    /// 更新用户运动习惯
    /// - Parameter exerciseHabit: 用户运动习惯
    /// - Returns: 包含更新后用户运动习惯的发布者
    func updateUserExerciseHabit(exerciseHabit: UpdateExerciseHabitRequest) -> AnyPublisher<UserExerciseHabitResponse, APIServiceError> {
        let endpoint = ApiEndpoints.User.exerciseHabit
        
        var parameters: [String: Any] = [:]
        if let hasExerciseHabit = exerciseHabit.hasExerciseHabit {
            parameters["has_exercise_habit"] = hasExerciseHabit
        }
        if let exerciseFrequency = exerciseHabit.exerciseFrequency {
            parameters["exercise_frequency"] = exerciseFrequency
        }
        if let exerciseDuration = exerciseHabit.exerciseDuration {
            parameters["exercise_duration"] = exerciseDuration
        }
        
        print("发送用户运动习惯更新请求: \(parameters)")
        
        return networkManager.request(
            endpoint: endpoint,
            method: .post,
            parameters: parameters
        )
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
    
    /// 获取用户运动习惯
    /// - Returns: 包含用户运动习惯的发布者
    func getUserExerciseHabit() -> AnyPublisher<UserExerciseHabitResponse, APIServiceError> {
        let endpoint = ApiEndpoints.User.exerciseHabit + "/latest"
        
        return networkManager.request(
            endpoint: endpoint,
            method: .get
        )
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 甜品相关API扩展
    /// 获取所有美食
    func getAllDesserts() -> AnyPublisher<DessertListResponse, APIServiceError> {
        return processAPIRequest(
            endpoint: "/api/v1/desserts",
            method: .get,
            parameters: nil,
            requiresAuth: false
        )
    }
    
    /// 按分类获取美食
    func getDessertsByCategory(categoryID: String, page: Int = 1, limit: Int = 20) -> AnyPublisher<DessertListResponse, APIServiceError> {
        return processAPIRequest(
            endpoint: "/api/v1/desserts",
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
            endpoint: "/api/v1/desserts/search",
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
            endpoint: "/api/v1/desserts/\(id)",
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
            endpoint: "/api/v1/categories",
            method: .get,
            parameters: params,
            requiresAuth: false
        )
    }
    
    // MARK: - 美食排行榜相关 API
    
    /// 获取用户消费最多的美食排行榜
    /// - Parameter limit: 返回结果数量限制，默认为5
    /// - Returns: 包含排行榜数据的发布者
    func getUserTopDesserts(limit: Int = 5) -> AnyPublisher<TopDessertResponse, APIServiceError> {
        let endpoint = "/api/v1/stats/top-desserts?limit=\(limit)"
        
        // 创建URL请求
        let urlString = Config.API.baseURL + endpoint
        guard let url = URL(string: urlString) else {
            return Fail(error: APIServiceError.unknown).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = Config.API.timeout
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加认证令牌
        if let token = UserDefaults.standard.string(forKey: Config.UserData.tokenKey) {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 从UserDefaults获取当前尝试次数
        let retryKey = "topDessertsRetryCount"
        let retryCount = UserDefaults.standard.integer(forKey: retryKey)
        
        // 如果已经尝试3次并且失败，直接返回空数据
        if retryCount >= 3 {
            DRInfo("[APIService] 排行榜数据已尝试3次，返回空数据")
            // 创建一个空的响应数据
            let emptyResponse = TopDessertResponse(
                code: 0,
                message: "暂无数据",
                data: TopDessertStatsResponse(items: [])
            )
            return Just(emptyResponse)
                .setFailureType(to: APIServiceError.self)
                .eraseToAnyPublisher()
        }
        
        // 执行请求并手动解析响应
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                // 打印响应信息
                DRDebug("[APIService] 排行榜API响应: 状态码=\(httpResponse.statusCode), 数据大小=\(data.count)字节")
                if let jsonString = String(data: data, encoding: .utf8) {
                    DRDebug("[APIService] 排行榜响应数据: \(jsonString)")
                }
                
                // 处理HTTP状态码
                switch httpResponse.statusCode {
                case 200..<300:
                    // 重置尝试次数
                    UserDefaults.standard.set(0, forKey: retryKey)
                    return data
                case 401:
                    // 处理401错误 - 令牌过期
                    if UserDefaults.standard.string(forKey: Config.UserData.tokenKey) != nil {
                        UserDefaults.standard.removeObject(forKey: Config.UserData.tokenKey)
                        UserDefaults.standard.removeObject(forKey: Config.UserData.userIdKey)
                        
                        // 通知认证服务处理token过期
                        DispatchQueue.main.async {
                            AuthService.shared.handleTokenExpired()
                        }
                    }
                    throw NetworkError.unauthorized("登录已过期，请重新登录")
                default:
                    // 增加尝试次数
                    UserDefaults.standard.set(retryCount + 1, forKey: retryKey)
                    
                    if let jsonString = String(data: data, encoding: .utf8) {
                        throw NetworkError.serverError(httpResponse.statusCode, jsonString)
                    } else {
                        throw NetworkError.serverError(httpResponse.statusCode, "服务器错误")
                    }
                }
            }
            .decode(type: TopDessertResponse.self, decoder: JSONDecoder())
            .mapError { error -> APIServiceError in
                if let networkError = error as? NetworkError {
                    if case .unauthorized = networkError {
                        return .tokenExpired
                    }
                    return .networkError(APINetworkError(error: networkError))
                } else if let decodingError = error as? DecodingError {
                    DRError("[APIService] 排行榜数据解析错误: \(decodingError)")
                    return .decodeError(decodingError.localizedDescription)
                } else {
                    return .unknown
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 从obs获取图片url链接服务相关 API
    
    /// 根据文件键获取图片URL
    /// - Parameter fkey: 文件键
    /// - Returns: 包含图片URL的发布者
    func getImageURLByFKey(fkey: String) -> AnyPublisher<ImageURLResponse, APIServiceError> {
        let endpoint = "/api/v1/file/url"
        
        return networkManager.request(
            endpoint: endpoint,
            method: .get,
            parameters: ["fkey": fkey],
            requiresAuth: false
        )
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
    
    // 图片URL响应模型
    struct ImageURLResponse: Codable {
        let url: String
        
        enum CodingKeys: String, CodingKey {
            case url
        }
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
            print("API请求错误: 无效的URL")
            return Fail(error: APIServiceError.unknown).eraseToAnyPublisher()
        }
        
        // 打印请求信息(调试)
        print("发送API请求: \(method.rawValue) \(url.absoluteString)")
        
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
                print("API请求错误: 无法序列化请求参数")
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
            .map { $0.data! }  // 强制解包可选值
            .mapError { error -> APIServiceError in
                if let networkError = error as? NetworkError {
                    // 针对网络错误进行特殊处理
                    if case .unauthorized = networkError {
                        return self.handleError(networkError)
                    } else {
                        return .networkError(APINetworkError(error: networkError))
                    }
                } else if let decodingError = error as? DecodingError {
                    // 针对解码错误提供详细的日志
                    DRError("[APIService] 数据解析错误: \(decodingError)")
                    
                    // 根据解码错误类型提供更具体的信息
                    switch decodingError {
                    case .keyNotFound(let key, _):
                        DRError("[APIService] 找不到键: \(key.stringValue)")
                    case .valueNotFound(let type, _):
                        DRError("[APIService] 找不到值，期望类型: \(type)")
                    case .typeMismatch(let type, _):
                        DRError("[APIService] 类型不匹配，期望类型: \(type)")
                    default:
                        break
                    }
                    
                    return .networkError(APINetworkError(error: .decodingFailed(decodingError)))
                } else {
                    // 处理其他未知错误
                    DRError("[APIService] 未知错误: \(error)")
                    return .unknown
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 美食图片相关
    
    /// 获取美食图片URL
    /// - Parameters:
    ///   - dessertId: 美食ID
    ///   - type: 图片类型（如icon、regular、voucher等）
    /// - Returns: 美食图片URL
    func getDessertImageURL(dessertId: String, type: String) -> URL? {
        let baseURL = Config.API.baseURL
        // 统一使用一种URL路径格式
        let endpoint = "/api/v1/desserts/\(dessertId)/images/\(type)"
        return URL(string: baseURL + endpoint)
    }
    
    /// 获取指定ID的美食图片URL
    /// - Parameters:
    ///   - dessertId: 美食ID
    ///   - type: 图片类型（如icon、regular、voucher等）
    ///   - imageId: 图片ID，用于获取特定图片而非随机图片
    /// - Returns: 美食图片URL
    func getDessertImageURLWithImageID(dessertId: String, type: String, imageId: String) -> URL? {
        let baseURL = Config.API.baseURL
        let endpoint = "/api/v1/desserts/\(dessertId)/images/\(type)?image_id=\(imageId)"
        return URL(string: baseURL + endpoint)
    }
    
    // 获取美食图片URL（处理重定向）- 旧版本，已弃用
    func getDessertImageURLOld(dessertId: String, type: String = "regular") -> URL? {
        let baseURLString = Config.API.baseURL
        let endpoint = "api/v1/desserts/\(dessertId)/image?type=\(type)"
        let urlString = "\(baseURLString)/\(endpoint)"
        
        // 直接返回URL，让URLSession处理重定向
        // ImageCacheService已经被改进为可以处理重定向
        return URL(string: urlString)
    }
    
    // MARK: - 新用户状态检查
    
    /// 检查用户是否有打卡记录
    func checkUserHasWorkoutRecords(userId: String) -> AnyPublisher<Bool, APIServiceError> {
        let endpoint = "/api/v1/users/\(userId)/has-workout-records"
        
        return networkManager.request(
            endpoint: endpoint,
            method: .get,
            requiresAuth: true
        )
        .map { (response: HasWorkoutRecordsResponse) -> Bool in
            response.hasRecords
        }
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
}

/// API错误类型
enum APIError: Error {
    case networkError(String)
    case serverError(Int, String)
    case authError(String)
    case validationError(String)
    case decodingError
    case unknown
    
    var errorMessage: String {
        switch self {
        case .networkError(let message):
            return "网络错误: \(message)"
        case .serverError(let code, let message):
            return "服务器错误(\(code)): \(message)"
        case .authError(let message):
            return "认证错误: \(message)"
        case .validationError(let message):
            return "数据验证错误: \(message)"
        case .decodingError:
            return "数据解析错误"
        case .unknown:
            return "未知错误"
        }
    }
}

/// 空响应类型（用于没有返回数据的API）
typealias EmptyResponse = EmptyResponseData

// MARK: - 错误处理

// 自定义CodingKey实现，用于创建动态键路径
private struct CustomCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}