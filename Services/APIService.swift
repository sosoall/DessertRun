import Foundation
import Combine
import SwiftUI
import AVFoundation

// 直接导入APIRequestModels文件（如果需要特别导入）
// import APIRequestModels

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

// MARK: - API响应模型

// 注意：API响应类型定义在DessertRun/Models/DessertAPIModels.swift文件中
// 包括：DessertListResponse、DessertSearchResponse、DessertDetailResponse、CategoryListResponse

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
    
    // MARK: - 美食相关API
    
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
    
    // MARK: - 运动相关 API
    
    /// 获取所有运动类型
    /// - Returns: 包含运动类型列表的发布者
    func fetchExerciseTypes() -> AnyPublisher<[APIExerciseType], APIServiceError> {
        let endpoint = ApiEndpoints.Exercise.types
        let urlString = Config.API.baseURL + endpoint
        
        guard let url = URL(string: urlString) else {
            return Fail(error: APIServiceError.unknown).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = Config.API.timeout
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                DRInfo("[APIService] 获取运动类型响应: 状态码=\(httpResponse.statusCode), 数据大小=\(data.count)字节")
                if let jsonString = String(data: data, encoding: .utf8) {
                    DRInfo("[APIService] 运动类型响应数据: \(jsonString)")
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NetworkError.serverError(httpResponse.statusCode, "服务器错误")
                }
                
                return data
            }
            .tryMap { data -> [APIExerciseType] in
                do {
                    // 先尝试解码标准响应格式
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(ExerciseTypesResponse.self, from: data)
                    
                    if response.code != 200 {
                        throw NetworkError.serverError(response.code, response.message)
                    }
                    
                    // 确保data字段不为nil
                    return response.data
                } catch {
                    // 如果解码标准格式失败，尝试直接解码为运动类型数组
                    DRWarning("[APIService] 标准解码失败，尝试直接解码为运动类型数组：\(error)")
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let dataArray = jsonObject["data"] as? [[String: Any]] {
                        // 有data字段但格式可能不标准，尝试手动解析
                        let decoder = JSONDecoder()
                        let dataData = try JSONSerialization.data(withJSONObject: dataArray, options: [])
                        return try decoder.decode([APIExerciseType].self, from: dataData)
                    } else {
                        // 没有data字段，可能直接是数组
                        let decoder = JSONDecoder()
                        return try decoder.decode([APIExerciseType].self, from: data)
                    }
                }
            }
            .mapError { error -> APIServiceError in
                if let networkError = error as? NetworkError {
                    return .networkError(APINetworkError(error: networkError))
                } else if let decodingError = error as? DecodingError {
                    DRError("[APIService] 解析运动类型失败: \(decodingError)")
                    return .networkError(APINetworkError(error: .decodingFailed(decodingError)))
                } else {
                    return .unknown
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// 计算消耗指定卡路里所需的运动时间
    /// - Parameters:
    ///   - exerciseType: 运动类型标识
    ///   - calories: 目标卡路里
    /// - Returns: 包含计算结果的发布者
    func calculateExerciseTime(exerciseType: String, calories: Double) -> AnyPublisher<ExerciseTimeResponse?, APIServiceError> {
        let endpoint = ApiEndpoints.Exercise.calculateTime
        
        return networkManager.request(
            endpoint: endpoint,
            method: .get,
            parameters: [
                "type": exerciseType,
                "calories": "\(calories)"
            ],
            requiresAuth: true
        )
        .map { (response: ApiResponse<ExerciseTimeResponse>) -> ExerciseTimeResponse? in
            // 如果没有数据返回nil，由调用者处理
            guard let data = response.data else {
                DRWarning("[APIService] 计算运动时间API没有返回数据")
                return nil
            }
            return data
        }
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
    
    /// 计算消耗指定卡路里所需的运动距离
    /// - Parameters:
    ///   - exerciseType: 运动类型标识
    ///   - calories: 目标卡路里
    /// - Returns: 包含计算结果的发布者
    func calculateExerciseDistance(exerciseType: String, calories: Double) -> AnyPublisher<ExerciseDistanceResponse?, APIServiceError> {
        let endpoint = ApiEndpoints.Exercise.calculateDistance
        
        return networkManager.request(
            endpoint: endpoint,
            method: .get,
            parameters: [
                "type": exerciseType,
                "calories": "\(calories)"
            ],
            requiresAuth: true
        )
        .map { (response: ApiResponse<ExerciseDistanceResponse>) -> ExerciseDistanceResponse? in
            // 如果没有数据返回nil，由调用者处理
            guard let data = response.data else {
                DRWarning("[APIService] 计算运动距离API没有返回数据")
                return nil
            }
            return data
        }
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
    
    /// 获取单个运动类型的详细信息
    /// - Parameter type: 运动类型标识符
    /// - Returns: 包含运动类型详情的发布者
    func getExerciseTypeInfo(type: String) -> AnyPublisher<APIExerciseType?, APIServiceError> {
        let endpoint = "/api/v1/exercises/types/\(type)"
        
        return networkManager.request(
            endpoint: endpoint,
            method: .get,
            parameters: nil,
            requiresAuth: false
        )
        .map { (response: ApiResponse<APIExerciseType>) -> APIExerciseType? in
            // 如果没有数据返回nil，由调用者处理
            guard let data = response.data else {
                DRWarning("[APIService] 获取运动类型详情API没有返回数据")
                return nil
            }
            return data
        }
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 运动与打卡相关接口
    
    /// 创建运动与美食打卡记录
    func createWorkoutRecord(params: [String: Any]) -> AnyPublisher<WorkoutRecord?, APIServiceError> {
        let endpoint = ApiEndpoints.Workout.base
        
        // 打印详细的请求参数
        DRDebug("发起createWorkoutRecord请求: \(endpoint)")
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                DRDebug("请求参数: \n\(jsonString)")
            }
        } catch {
            DRError("序列化请求参数失败: \(error.localizedDescription)")
        }
        
        return networkManager.request(
            endpoint: endpoint,
            method: .post,
            parameters: params,
            requiresAuth: true
        )
        .handleEvents(receiveOutput: { responseData in
            DRDebug("收到createWorkoutRecord响应")
        })
        .map { (responseData: EmptyResponseData) -> WorkoutRecord? in
            // 将响应直接解析为WorkoutRecord对象
            // 这里通常API会返回创建的记录，但如果不返回，我们可以返回nil
            return nil
        }
        .mapError { [weak self] networkError -> APIServiceError in
            guard let self = self else { return .unknown }
            
            DRError("createWorkoutRecord网络错误: \(networkError)")
            
            // 针对特定错误类型进行更详细的错误提取
            if case .badRequest(let message) = networkError {
                DRError("请求参数错误详情: \(message)")
                
                // 尝试从错误消息中解析更多信息
                if message.contains("{") && message.contains("}") {
                    DRError("服务器可能返回了JSON格式的错误信息")
                }
            }
            
            // 针对网络错误进行特殊处理
            if case .unauthorized = networkError {
                return self.handleError(networkError)
            } else {
                return .networkError(APINetworkError(error: networkError))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 获取用户的打卡记录列表，同时返回总记录数
    /// - Parameters:
    ///   - page: 页码，默认为1
    ///   - limit: 每页记录数，默认为20
    /// - Returns: 包含记录列表和总记录数的Publisher
    func getUserWorkoutRecordsWithTotal(page: Int = 1, limit: Int = 20) -> AnyPublisher<(records: [WorkoutRecord], total: Int), APIServiceError> {
        let endpoint = ApiEndpoints.Workout.base + "?page=\(page)&limit=\(limit)"
        
        // 创建一个可解码的包装类型，修改为匹配新的API响应格式
        struct WorkoutRecordsResponse: Decodable {
            let code: Int
            let message: String
            let data: WorkoutData
            
            struct WorkoutData: Decodable {
                let total: Int
                let page: Int
                let limit: Int
                let items: [WorkoutRecordDTO]
            }
            
            struct WorkoutRecordDTO: Decodable {
                let id: String
                let user_id: String
                let exercise_type: String
                let exercise_name: String?
                let duration: Int?
                let distance: Double?
                let calories_burned: Double
                let completion_date: String
                let dessert_id: String
                let dessert_name: String
                let dessert_calories: Double
                let equivalent_dessert_count: Double
                let workout_tag: String?
                let created_at: String
            }
        }
        
        // 添加调试日志
        DRDebug("[APIService] 请求运动记录带总数: \(endpoint)")
        
        // 使用JSON直接解析，避免嵌套的APIResponse结构
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
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                // 打印响应信息
                DRDebug("[APIService] 运动记录API响应: 状态码=\(httpResponse.statusCode), 数据大小=\(data.count)字节")
                if let jsonString = String(data: data, encoding: .utf8) {
                    DRDebug("[APIService] 运动记录响应数据: \(jsonString)")
                }
                
                // 验证状态码
                guard (200..<300).contains(httpResponse.statusCode) else {
                    throw NetworkError.serverError(httpResponse.statusCode, "服务器错误")
                }
                
                return data
            }
            .tryMap { data -> WorkoutRecordsResponse in
                do {
                    // 首先尝试验证JSON是否包含根级别的code和data字段
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        // 检查关键字段是否存在
                        if json["code"] == nil {
                            DRError("[APIService] 响应缺少code字段")
                            throw NetworkError.decodingFailed(DecodingError.keyNotFound(
                                CustomCodingKey(stringValue: "code"), 
                                DecodingError.Context(codingPath: [], debugDescription: "找不到键: code")
                            ))
                        }
                        
                        if json["data"] == nil {
                            DRError("[APIService] 响应缺少data字段")
                            throw NetworkError.decodingFailed(DecodingError.keyNotFound(
                                CustomCodingKey(stringValue: "data"), 
                                DecodingError.Context(codingPath: [], debugDescription: "找不到键: data")
                            ))
                        }
                    }
                    
                    // 解码完整的响应
                    let decoder = JSONDecoder()
                    return try decoder.decode(WorkoutRecordsResponse.self, from: data)
                } catch {
                    DRError("[APIService] 运动记录数据解析错误: \(error)")
                    throw NetworkError.decodingFailed(error as? DecodingError ?? DecodingError.dataCorrupted(
                        DecodingError.Context(codingPath: [], debugDescription: "无效的JSON格式")
                    ))
                }
            }
            .map { (response: WorkoutRecordsResponse) -> (records: [WorkoutRecord], total: Int) in
                // 从API响应的data.items字段获取记录和总数
                DRDebug("[APIService] 获取到\(response.data.items.count)条运动记录，总数: \(response.data.total)")
                
                // 验证响应状态码
                guard response.code == 0 || response.code == 200 else {
                    DRError("[APIService] API返回错误码: \(response.code), 错误信息: \(response.message)")
                    return (records: [], total: 0)
                }
                
                let records = response.data.items.compactMap { (dto: WorkoutRecordsResponse.WorkoutRecordDTO) -> WorkoutRecord? in
                    // 直接使用后端返回的运动类型和名称，不进行任何翻译或处理
                    let exerciseType = APIExerciseType.fromString(dto.exercise_type, name: dto.exercise_name)
                    
                    // 创建一个甜品对象
                    let dessert = DessertItem(
                        id: dto.dessert_id,  // 直接使用原始uuid字符串
                        name: dto.dessert_name,
                        imageName: dto.dessert_id,  // 使用ID而不是构造一个假的图片名称
                        calories: "\(dto.dessert_calories)",
                        category: .dessert,
                        description: "",
                        backgroundColor: nil,
                        isFeatured: false,
                        relatedItems: [],
                        categoryId: "0",  
                        categoryName: "默认分类",
                        displayOrder: 0,
                        images: []
                    )
                    
                    // 改进日期解析，采用更完备的方式
                    let dateFormatter = ISO8601DateFormatter()
                    dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    
                    var createdAtDate: Date?
                    // 尝试多种日期解析方法
                    if let date = dateFormatter.date(from: dto.completion_date) {
                        // 首先尝试带有毫秒的ISO8601格式解析
                        createdAtDate = date
                    } else {
                        // 如果失败，尝试不带毫秒的格式
                        dateFormatter.formatOptions = [.withInternetDateTime]
                        if let date = dateFormatter.date(from: dto.completion_date) {
                            createdAtDate = date
                        } else {
                            // 如果仍然失败，尝试其他格式
                            let backupFormatter = DateFormatter()
                            backupFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                            if let date = backupFormatter.date(from: dto.completion_date) {
                                createdAtDate = date
                            } else {
                                // 尝试简单的年月日格式
                                backupFormatter.dateFormat = "yyyy-MM-dd"
                                if let date = backupFormatter.date(from: dto.completion_date) {
                                    createdAtDate = date
                                } else {
                                    // 日期解析失败，记录错误并返回nil
                                    DRError("[APIService] 无法解析日期: \(dto.completion_date)")
                                    return nil
                                }
                            }
                        }
                    }
                    
                    // 确保有有效的日期
                    guard let finalDate = createdAtDate else {
                        DRError("[APIService] 日期解析失败，忽略此记录")
                        return nil
                    }
                    
                    // 创建WorkoutRecord对象
                    return WorkoutRecord(
                        id: dto.id,
                        userId: dto.user_id,
                        exerciseType: exerciseType,
                        duration: dto.duration.map { TimeInterval($0) },
                        distance: dto.distance,
                        caloriesBurned: dto.calories_burned,
                        dessert: dessert,
                        date: finalDate,
                        workoutTag: dto.workout_tag ?? "",
                        equivalentDessertCount: dto.equivalent_dessert_count
                    )
                }
                
                // 返回记录列表和总数
                return (records: records, total: response.data.total)
            }
            .mapError { error -> APIServiceError in
                if let decodingError = error as? DecodingError {
                    DRError("[APIService] 运动记录解析错误: \(decodingError)")
                    return .decodeError(decodingError.localizedDescription)
                } else if let networkError = error as? NetworkError {
                    DRError("[APIService] 网络错误: \(networkError)")
                    return .networkError(APINetworkError(error: networkError))
                } else {
                    DRError("[APIService] 获取运动记录失败: \(error)")
                    return .networkError(APINetworkError(error: NetworkError.requestFailed(error)))
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// 获取用户的打卡记录列表
    func getUserWorkoutRecords(page: Int = 1, limit: Int = 20) -> AnyPublisher<[WorkoutRecord], APIServiceError> {
        return getUserWorkoutRecordsWithTotal(page: page, limit: limit)
            .map { result in
                return result.records
            }
            .eraseToAnyPublisher()
    }
    
    /// 获取用户的美食券列表
    func getUserVouchers(status: String? = nil, page: Int = 1, limit: Int = 20) -> AnyPublisher<[DessertVoucher], APIServiceError> {
        var endpoint = ApiEndpoints.Vouchers.list + "?page=\(page)&limit=\(limit)"
        if let status = status {
            endpoint += "&status=\(status)"
        }
        
        // 创建一个可解码的包装类型
        struct VouchersResponse: Decodable {
            let code: Int
            let message: String
            let data: VoucherData
            
            struct VoucherData: Decodable {
                let total: Int
                let page: Int
                let limit: Int
                let items: [VoucherDTO]
            }
            
            struct VoucherDTO: Decodable {
                let id: String
                let user_id: String
                let dessert_id: String
                let dessert_name: String
                let calories_value: Double  // 修改字段名，与API响应匹配
                let equivalent_dessert_count: Double
                let workout_record_id: String?
                let status: String
                let created_at: String
                let updated_at: String?
                let expire_at: String?
                let image_id: String?
                let image_url: String?
            }
        }
        
        // 添加调试日志
        DRDebug("[APIService] 请求美食券: \(endpoint)")
        
        // 使用JSON直接解析，避免嵌套的APIResponse结构
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
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                // 打印响应信息
                DRDebug("[APIService] 美食券API响应: 状态码=\(httpResponse.statusCode), 数据大小=\(data.count)字节")
                // 移除响应数据的打印，减少日志冗余
                // if let jsonString = String(data: data, encoding: .utf8) {
                //     DRDebug("[APIService] 美食券响应数据: \(jsonString)")
                // }
                
                // 验证状态码
                guard (200..<300).contains(httpResponse.statusCode) else {
                    throw NetworkError.serverError(httpResponse.statusCode, "服务器错误")
                }
                
                return data
            }
            .tryMap { data -> VouchersResponse in
                do {
                    // 尝试解析原始JSON以检查时间戳格式 - 移除不必要的日志
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let dataDict = json["data"] as? [String: Any],
                       let items = dataDict["items"] as? [[String: Any]] {
                        
                        // 移除不必要的时间戳调试日志
                        /* if let firstItem = items.first {
                            let createdAt = firstItem["created_at"] as? String ?? "无时间戳"
                            let expireAt = firstItem["expire_at"] as? String ?? "无过期时间"
                            let updatedAt = firstItem["updated_at"] as? String ?? "无更新时间"
                            
                            DRDebug("[APIService] 美食券原始时间戳格式:")
                            DRDebug("[APIService] created_at: \(createdAt)")
                            DRDebug("[APIService] expire_at: \(expireAt)")
                            DRDebug("[APIService] updated_at: \(updatedAt)")
                        } */
                    }
                    
                    // 首先尝试验证JSON是否包含根级别的code和data字段
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        // 检查关键字段是否存在
                        if json["code"] == nil {
                            DRError("[APIService] 美食券响应缺少code字段")
                            throw NetworkError.decodingFailed(DecodingError.keyNotFound(
                                CustomCodingKey(stringValue: "code"), 
                                DecodingError.Context(codingPath: [], debugDescription: "找不到键: code")
                            ))
                        }
                        
                        if json["data"] == nil {
                            DRError("[APIService] 美食券响应缺少data字段")
                            throw NetworkError.decodingFailed(DecodingError.keyNotFound(
                                CustomCodingKey(stringValue: "data"), 
                                DecodingError.Context(codingPath: [], debugDescription: "找不到键: data")
                            ))
                        }
                    }
                    
                    // 解码完整的响应
                    let decoder = JSONDecoder()
                    return try decoder.decode(VouchersResponse.self, from: data)
                } catch {
                    DRError("[APIService] 美食券数据解析错误: \(error)")
                    throw NetworkError.decodingFailed(error as? DecodingError ?? DecodingError.dataCorrupted(
                        DecodingError.Context(codingPath: [], debugDescription: "无效的JSON格式")
                    ))
                }
            }
            .map { (response: VouchersResponse) -> [DessertVoucher] in
                // 从API响应的data.items字段获取记录
                DRDebug("[APIService] 获取到\(response.data.items.count)张美食券，总数: \(response.data.total)")
                
                // 验证响应状态码
                guard response.code == 0 || response.code == 200 else {
                    DRError("[APIService] API返回错误码: \(response.code), 错误信息: \(response.message)")
                    return []
                }
                
                // 专门用于解析ISO8601格式的日期格式化器
                let dateFormatter = ISO8601DateFormatter()
                // 设置时区为UTC以正确解析UTC格式日期（后端返回的是UTC时间）
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                // 启用完整的ISO8601格式支持，包括毫秒和时区
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                
                // 尝试多种时间格式的解析方法 - 减少不必要的日志
                func parseDate(from string: String) -> Date? {
                    // 方法1: 使用ISO8601DateFormatter
                    if let date = dateFormatter.date(from: string) {
                        return date
                    }
                    
                    // 方法2: 使用DateFormatter尝试多种时间格式
                    let backupFormatter = DateFormatter()
                    backupFormatter.locale = Locale(identifier: "en_US_POSIX")
                    backupFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                    
                    // 尝试不同的时间格式
                    let timeFormats = [
                        "yyyy-MM-dd'T'HH:mm:ss.SSSZ",       // 带毫秒和时区
                        "yyyy-MM-dd'T'HH:mm:ssZ",           // 带时区不带毫秒
                        "yyyy-MM-dd HH:mm:ss.SSSZ",         // 空格分隔带毫秒和时区
                        "yyyy-MM-dd HH:mm:ssZ",             // 空格分隔带时区
                        "yyyy-MM-dd HH:mm:ss.SSS",          // 带毫秒不带时区
                        "yyyy-MM-dd HH:mm:ss"               // 基本格式
                    ]
                    
                    for format in timeFormats {
                        backupFormatter.dateFormat = format
                        if let date = backupFormatter.date(from: string) {
                            return date
                        }
                    }
                    
                    DRError("[APIService] 无法解析日期: \(string)")
                    return nil
                }
                
                // 移除不必要的日期字符串调试日志
                // if let firstItem = response.data.items.first {
                //     DRDebug("[APIService] 美食券第一项日期字符串: created_at=\(firstItem.created_at), expire_at=\(firstItem.expire_at ?? "nil")")
                // }
                
                // 将DTO转换为领域模型，从data.items获取
                return response.data.items.compactMap { dto in
                    // 解析创建日期 - 不再使用兜底逻辑
                    guard let createdAt = parseDate(from: dto.created_at) else {
                        // 日期解析失败，直接记录错误并跳过此项
                        DRError("[APIService] 无法解析美食券创建日期: \(dto.created_at)")
                        // 抛出解析错误，中断整个处理
                        fatalError("时间戳解析失败: \(dto.created_at)")
                    }
                    
                    // 解析过期日期 - 可选，但如果存在也必须解析成功
                    var expireDate: Date? = nil
                    if let expireString = dto.expire_at, !expireString.isEmpty {
                        guard let parsedDate = parseDate(from: expireString) else {
                            DRError("[APIService] 无法解析美食券过期日期: \(expireString)")
                            // 抛出解析错误，中断整个处理
                            fatalError("时间戳解析失败: \(expireString)")
                        }
                        expireDate = parsedDate
                    }
                    
                    // 解析更新日期 - 可选，但如果存在也必须解析成功
                    var updateDate: Date? = nil
                    if let updateString = dto.updated_at, !updateString.isEmpty {
                        guard let parsedDate = parseDate(from: updateString) else {
                            DRError("[APIService] 无法解析美食券更新日期: \(updateString)")
                            // 抛出解析错误，中断整个处理
                            fatalError("时间戳解析失败: \(updateString)")
                        }
                        updateDate = parsedDate
                    }
                    
                    // 记录解析后的创建日期，用于调试
                    let dateDebugFormatter = DateFormatter()
                    dateDebugFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    DRDebug("[APIService] 美食券[\(dto.id)]解析后的日期: 创建=\(dateDebugFormatter.string(from: createdAt)), 过期=\(expireDate != nil ? dateDebugFormatter.string(from: expireDate!) : "nil")")
                    
                    // 创建DessertVoucher对象
                    return DessertVoucher(
                        id: dto.id,
                        userId: dto.user_id,
                        dessertId: dto.dessert_id,
                        dessertName: dto.dessert_name,
                        equivalentDessertCount: dto.equivalent_dessert_count,
                        caloriesValue: dto.calories_value, // 字段名与API响应匹配为calories_value
                        workoutRecordId: dto.workout_record_id,
                        status: dto.status,
                        createdAt: createdAt,
                        updatedAt: updateDate,
                        expireAt: expireDate,
                        imageId: dto.image_id,
                        imageURL: dto.image_url
                    )
                }
            }
            .mapError { error -> APIServiceError in
                if let decodingError = error as? DecodingError {
                    DRError("[APIService] 美食券解析错误: \(decodingError)")
                    return .decodeError(decodingError.localizedDescription)
                } else if let networkError = error as? NetworkError {
                    DRError("[APIService] 网络错误: \(networkError)")
                    
                    // 针对网络错误进行特殊处理
                    if case .unauthorized = networkError {
                        return self.handleError(networkError)
                    } else {
                        return .networkError(APINetworkError(error: networkError))
                    }
                } else {
                    DRError("[APIService] 获取美食券失败: \(error)")
                    return .networkError(APINetworkError(error: NetworkError.requestFailed(error)))
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 统计相关 API
    
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
    
    // MARK: - 文件服务相关 API
    
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
    
    // MARK: - 私有辅助方法
    
    /// 处理网络错误
    /// - Parameter error: 网络错误
    /// - Returns: API服务错误
    private func handleError(_ error: NetworkError) -> APIServiceError {
        // 处理token过期情况
        if case .unauthorized(let message) = error,
           (message.contains("过期") || message.contains("token") || message.contains("Token")) {
            // 清除本地令牌
            UserDefaults.standard.removeObject(forKey: Config.UserData.tokenKey)
            UserDefaults.standard.removeObject(forKey: Config.UserData.userIdKey)
            
            // 通知认证服务处理token过期
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
                case 400..<500:
                    if httpResponse.statusCode == 401 {
                        return .tokenExpired
                    } else {
                        return .networkError(APINetworkError(error: .serverError(httpResponse.statusCode, message)))
                    }
                default:
                    return .networkError(APINetworkError(error: .serverError(httpResponse.statusCode, message)))
                }
            } else {
                // 如果无法提取错误信息，则使用状态码生成通用错误
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
    
    /// 获取用户运动统计数据
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份（可选）
    /// - Returns: 包含统计数据的Publisher
    func getUserWorkoutStats(year: Int, month: Int? = nil) -> AnyPublisher<WorkoutStatsResponse, APIServiceError> {
        // 构建查询参数
        var queryItems = [URLQueryItem(name: "year", value: "\(year)")]
        if let month = month {
            queryItems.append(URLQueryItem(name: "month", value: "\(month)"))
        }
        
        var urlComponents = URLComponents(string: Config.API.baseURL + "/api/v1/workouts/stats")
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            return Fail(error: APIServiceError.unknown).eraseToAnyPublisher()
        }
        
        DRDebug("[APIService] 请求运动统计数据: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = Config.API.timeout
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加认证令牌
        if let token = UserDefaults.standard.string(forKey: Config.UserData.tokenKey) {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                // 打印响应信息
                DRDebug("[APIService] 运动统计API响应: 状态码=\(httpResponse.statusCode), 数据大小=\(data.count)字节")
                if let jsonString = String(data: data, encoding: .utf8) {
                    DRDebug("[APIService] 运动统计响应数据: \(jsonString)")
                }
                
                // 验证状态码
                guard (200..<300).contains(httpResponse.statusCode) else {
                    throw NetworkError.serverError(httpResponse.statusCode, "服务器错误")
                }
                
                return data
            }
            .decode(type: WorkoutStatsResponse.self, decoder: JSONDecoder())
            .mapError { error -> APIServiceError in
                if let decodingError = error as? DecodingError {
                    DRError("[APIService] 运动统计数据解析错误: \(decodingError)")
                    return .decodeError(decodingError.localizedDescription)
                } else if let networkError = error as? NetworkError {
                    DRError("[APIService] 网络错误: \(networkError)")
                    return .networkError(APINetworkError(error: networkError))
                } else {
                    DRError("[APIService] 获取运动统计失败: \(error)")
                    return .networkError(APINetworkError(error: NetworkError.requestFailed(error)))
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
}

// MARK: - 数据模型

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
    let birthYear: Int?  // 添加出生年份字段
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
        case birthYear = "birth_year"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isNewUser = "is_new_user"
        case isProfileCompleted = "is_profile_completed"
    }
    
    // 添加直接初始化方法，方便创建实例
    init(id: String, phone: String, nickname: String?, avatar: String?, gender: String?,
         birthYear: Int?, createdAt: String?, updatedAt: String?, isNewUser: Bool?, isProfileCompleted: Bool?) {
        self.id = id
        self.phone = phone
        self.nickname = nickname
        self.avatar = avatar
        self.gender = gender
        self.birthYear = birthYear
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
        birthYear = try container.decodeIfPresent(Int.self, forKey: .birthYear)
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
            birthYear: birthYear,
            isProfileCompleted: isProfileCompleted ?? false,
            isNewUser: isNewUser ?? true,
            apiUserId: id
        )
        return user
    }
}

// MARK: - 新增用户信息API模型

// 导入APIRequestModels.swift中的模型类型
// 这些类型已经在APIRequestModels.swift中定义，此处移除重复定义

// MARK: - 导入API请求模型
// 这里不再重复定义这些类型 

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
