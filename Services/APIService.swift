import Foundation
import Combine
import SwiftUI

/// API服务错误类型
enum APIServiceError: Error, CustomStringConvertible {
    /// 网络相关错误
    case networkError(APINetworkError)
    /// 授权令牌过期
    case tokenExpired
    /// 未知错误
    case unknown
    
    /// 获取用户友好的错误消息
    var errorMessage: String {
        switch self {
        case .networkError(let error):
            return error.errorMessage
        case .tokenExpired:
            return "登录已过期，请重新登录"
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
            method: .put,
            parameters: parameters
        )
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
    
    /// 获取用户身体数据
    /// - Returns: 包含用户身体数据的发布者
    func getUserBodyData() -> AnyPublisher<UserBodyDataResponse, APIServiceError> {
        let endpoint = ApiEndpoints.User.bodyData
        
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
            method: .put,
            parameters: parameters
        )
        .mapError { self.handleError($0) }
        .eraseToAnyPublisher()
    }
    
    /// 获取用户运动习惯
    /// - Returns: 包含用户运动习惯的发布者
    func getUserExerciseHabit() -> AnyPublisher<UserExerciseHabitResponse, APIServiceError> {
        let endpoint = ApiEndpoints.User.exerciseHabit
        
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
                let decoder = JSONDecoder()
                let response = try decoder.decode(ExerciseTypesResponse.self, from: data)
                
                if response.code != 200 {
                    throw NetworkError.serverError(response.code, response.message)
                }
                
                // 直接返回API返回的运动类型，不进行转换
                return response.data
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
}

// MARK: - 数据模型

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

/// 用户基本信息响应
struct UserBasicInfoResponse: Codable {
    let nickname: String?
    let avatar: String?
    let gender: String?
    let birthYear: Int?
    
    enum CodingKeys: String, CodingKey {
        case nickname, avatar, gender
        case birthYear = "birth_year"
    }
}

/// 用户身体数据响应
struct UserBodyDataResponse: Codable {
    let height: Double?
    let weight: Double?
    
    enum CodingKeys: String, CodingKey {
        case height, weight
    }
}

/// 用户运动习惯响应
struct UserExerciseHabitResponse: Codable {
    let hasExerciseHabit: Bool?
    let exerciseFrequency: Int?
    let exerciseDuration: Int?
    
    enum CodingKeys: String, CodingKey {
        case hasExerciseHabit = "has_exercise_habit"
        case exerciseFrequency = "exercise_frequency"
        case exerciseDuration = "exercise_duration"
    }
}

// MARK: - 导入API请求模型
// 这里不再重复定义这些类型 