import Foundation
import Combine

// MARK: - 运动打卡与美食券相关API扩展，包括运动统计数据、运动打卡历史记录（单个、批量、列表获取等）、美食券的创建/获取等
extension APIService {
    
    /// 获取用户运动统计数据
    /// - Parameters:
    ///   - year: 年份（可选），如果不传则获取所有时间
    ///   - month: 月份（可选），如果不传则获取全年数据
    /// - Returns: 包含统计数据的发布者
    func getUserWorkoutStats(year: Int? = nil, month: Int? = nil) -> AnyPublisher<APIWorkoutStatsResponse, APIServiceError> {
        var queryParams: [String: String] = [:]
        if let year = year {
            queryParams["year"] = "\(year)"
            if let month = month {
                queryParams["month"] = "\(month)"
            }
        }
        
        // 构建URL
        var urlComponents = URLComponents(string: Config.API.baseURL + "/api/v1/workouts/stats")
        
        // 添加查询参数
        if !queryParams.isEmpty {
            urlComponents?.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
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
                
                
                // 验证状态码
                guard (200..<300).contains(httpResponse.statusCode) else {
                    throw NetworkError.serverError(httpResponse.statusCode, "服务器错误")
                }
                
                return data
            }
            .decode(type: APIWorkoutStatsResponse.self, decoder: JSONDecoder())
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
    
    /// 获取用户运动打卡历史记录和总数
    /// - Parameters:
    ///   - page: 页码
    ///   - limit: 每页数量
    /// - Returns: 包含记录列表和总数的发布者
    func getUserWorkoutRecordsWithTotal(page: Int = 1, limit: Int = 20) -> AnyPublisher<([WorkoutRecord], Int), APIServiceError> {
        let endpoint = "/api/v1/workouts"
        let queryParams = ["page": "\(page)", "limit": "\(limit)"]
        
        // 构建URL
        var urlComponents = URLComponents(string: Config.API.baseURL + endpoint)
        urlComponents?.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let url = urlComponents?.url else {
            DRError("[APIService] getUserWorkoutRecords: 无效URL")
            return Fail(error: APIServiceError.unknown).eraseToAnyPublisher()
        }
        
        DRInfo("[APIService] 获取运动记录列表: \(url)")
        
        // 使用requestRaw替代原来的request方法，以获取更多控制
        return NetworkManager.shared.requestRaw(
            endpoint: endpoint,
            method: .get,
            parameters: queryParams,
            requiresAuth: true
        )
        .tryMap { data, response -> ([WorkoutRecord], Int) in
            // 打印原始响应数据
            if let jsonString = String(data: data, encoding: .utf8) {
                // 限制输出长度以避免日志过大
                let maxLength = 1000
                let truncatedString = jsonString.count > maxLength ? 
                    String(jsonString.prefix(maxLength)) + "..." : jsonString
                DRDebug("[APIService] 运动记录原始响应: \(truncatedString)")
            }
            
            // 先尝试解析为字典，检查基本结构
            if let jsonObj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // 检查关键字段是否存在
                if let code = jsonObj["code"] as? Int {
                    DRDebug("[APIService] 运动记录响应code: \(code)")
                } else {
                    DRError("[APIService] 运动记录响应缺少code字段")
                }
                
                if let message = jsonObj["message"] as? String {
                    DRDebug("[APIService] 运动记录响应message: \(message)")
                }
                
                // 检查data字段结构
                if let dataObj = jsonObj["data"] as? [String: Any] {
                    DRDebug("[APIService] 运动记录数据字段结构: \(dataObj.keys)")
                    
                    if let total = dataObj["total"] as? Int {
                        DRDebug("[APIService] 运动记录总数: \(total)")
                    } else {
                        DRError("[APIService] 运动记录数据缺少total字段")
                    }
                    
                    if let items = dataObj["items"] as? [[String: Any]] {
                        DRDebug("[APIService] 运动记录数量: \(items.count)")
                        if let firstItem = items.first {
                            DRDebug("[APIService] 第一条运动记录字段: \(firstItem.keys)")
                        }
                    } else {
                        DRError("[APIService] 运动记录数据缺少items数组或格式不正确")
                    }
                } else {
                    DRError("[APIService] 运动记录响应缺少data字段或格式不正确")
                }
            }
            
            // 尝试解码
            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(WorkoutRecordsResponse.self, from: data)
                DRInfo("[APIService] 成功解码WorkoutRecordsResponse: 总数=\(response.data.total), 当前页=\(response.data.page)")
                
                // 检查项目数量
                if response.data.items.isEmpty {
                    DRWarning("[APIService] 运动记录列表为空")
                } else {
                    DRInfo("[APIService] 收到\(response.data.items.count)条运动记录")
                }
                
                // 将API记录转换为领域模型
                let records = self.mapAPIWorkoutRecords(response.data.items)
                return (records, response.data.total)
            } catch {
                DRError("[APIService] 解码WorkoutRecordsResponse失败: \(error)")
                
                // 提供更详细的解码错误信息
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        DRError("[APIService] 找不到键: \(key.stringValue), 路径: \(context.codingPath.map { $0.stringValue })")
                    case .valueNotFound(let type, let context):
                        DRError("[APIService] 找不到\(type)类型的值, 路径: \(context.codingPath.map { $0.stringValue })")
                    case .typeMismatch(let type, let context):
                        DRError("[APIService] 类型不匹配: 期望\(type), 路径: \(context.codingPath.map { $0.stringValue })")
                    case .dataCorrupted(let context):
                        DRError("[APIService] 数据损坏: \(context.debugDescription)")
                    @unknown default:
                        DRError("[APIService] 未知解码错误: \(decodingError)")
                    }
                }
                
                throw error
            }
        }
        .mapError { error -> APIServiceError in
            DRError("[APIService] 获取运动记录失败: \(error)")
            
            if let decodingError = error as? DecodingError {
                return APIServiceError.decodeError(decodingError.localizedDescription)
            } else if let networkError = error as? NetworkError {
                if case .unauthorized = networkError {
                    return APIServiceError.tokenExpired
                } else {
                    return APIServiceError.networkError(APINetworkError(error: networkError))
                }
            } else {
                return APIServiceError.unknown
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// 获取用户的运动打卡记录列表
    func getUserWorkoutRecords(page: Int = 1, limit: Int = 20) -> AnyPublisher<[WorkoutRecord], APIServiceError> {
        return getUserWorkoutRecordsWithTotal(page: page, limit: limit)
            .map { result in
                return result.0
            }
            .eraseToAnyPublisher()
    }

    /// 获取单个运动记录
    /// - Parameter recordId: 要获取的运动记录ID
    /// - Returns: 返回单个运动记录对象的发布者
    func getWorkoutRecord(recordId: String) -> AnyPublisher<WorkoutRecord, APIServiceError> {
        // 构建API端点
        let endpoint = "/api/v1/workouts/\(recordId)"
        
        DRInfo("[APIService] 获取单个运动记录: ID=\(recordId)")
        
        // 创建结构体来匹配API的真实返回格式
        struct WorkoutRecordResponse: Decodable {
            let code: Int
            let message: String
            let data: WorkoutRecordDTO
        }
        
        return NetworkManager.shared.request(
            endpoint: endpoint,
            method: .get,
            parameters: nil,
            requiresAuth: true,
            responseType: WorkoutRecordResponse.self
        )
        .tryMap { response -> WorkoutRecord in
            // 将DTO转换为领域模型
            let record = response.data.toDomainModel()
            DRInfo("[APIService] 成功获取运动记录 ID=\(recordId)")
            return record
        }
        .mapError { error -> APIServiceError in
            DRError("[APIService] 获取运动记录失败 ID=\(recordId): \(error)")
            if let apiError = error as? APIServiceError {
                return apiError
            }
            if let networkError = error as? NetworkError {
                if case .unauthorized = networkError {
                    return .tokenExpired
                } else {
                    return .networkError(APINetworkError(error: networkError))
                }
            }
            // 对于其他类型的错误，创建一个通用的APIServiceError
            return .unknown
        }
        .eraseToAnyPublisher()
    }
    
    /// 根据多个ID批量获取运动记录
    /// - Parameter recordIds: 逗号分隔的记录ID字符串，例如："id1,id2,id3"
    /// - Returns: 返回运动记录对象的发布者
    func getWorkoutRecordsByIds(recordIds: String) -> AnyPublisher<[WorkoutRecord], APIServiceError> {
        // 构建API端点
        let endpoint = "/api/v1/workouts/batch?ids=\(recordIds)"
        
        DRInfo("[APIService] 批量获取指定ID的运动记录: IDs=\(recordIds)")
        
        // 创建结构体来匹配API的真实返回格式
        struct WorkoutBatchResponse: Decodable {
            let code: Int
            let message: String
            let data: [WorkoutRecordDTO]
        }
        
        return NetworkManager.shared.request(
            endpoint: endpoint,
            method: .get,
            parameters: nil,
            requiresAuth: true,
            responseType: WorkoutBatchResponse.self
        )
        .tryMap { response -> [WorkoutRecord] in
            // 将DTO转换为领域模型
            let records = response.data.map { dto in
                return dto.toDomainModel()
            }
            
            DRInfo("[APIService] 成功获取\(records.count)条指定的运动记录")
            return records
        }
        .mapError { error -> APIServiceError in
            DRError("[APIService] 批量获取运动记录失败: \(error)")
            if let apiError = error as? APIServiceError {
                return apiError
            }
            if let networkError = error as? NetworkError {
                if case .unauthorized = networkError {
                    return .tokenExpired
                } else {
                    return .networkError(APINetworkError(error: networkError))
                }
            }
            // 对于其他类型的错误，创建一个通用的APIServiceError
            return .unknown
        }
        .eraseToAnyPublisher()
    }

    /// 将API响应的运动打卡记录转换为App中使用的模型
    private func mapAPIWorkoutRecords(_ apiRecords: [APIWorkoutRecord]) -> [WorkoutRecord] {
        return apiRecords.map { apiRecord in
            // 根据API返回值创建运动类型对象
            let exerciseType = APIExerciseType.fromString(apiRecord.exerciseType, name: apiRecord.exerciseName)
            
            // 创建甜品对象
            let dessert = DessertItem(
                id: apiRecord.dessertId,
                name: apiRecord.dessertName,
                imageName: "",
                calories: "\(Int(apiRecord.dessertCalories))",
                category: .dessert,
                description: "",
                backgroundColor: nil,
                isFeatured: false,
                relatedItems: [],
                categoryId: "",
                categoryName: "",
                displayOrder: 0,
                images: []
            )
            
            // 创建并返回运动记录
            return WorkoutRecord(
                id: apiRecord.id,
                userId: apiRecord.userId,
                exerciseType: exerciseType,
                duration: apiRecord.duration,
                distance: apiRecord.distance,
                caloriesBurned: apiRecord.caloriesBurned,
                dessert: dessert,
                date: apiRecord.completionDate,
                workoutTag: apiRecord.note ?? "",
                equivalentDessertCount: apiRecord.equivalentDessertCount
            )
        }
    }

    /// 创建运动与美食打卡记录并创建美食券
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
        
        // 定义API响应结构
        struct WorkoutRecordResponse: Decodable {
            let code: Int
            let message: String
            let data: WorkoutRecordDTO
            
            struct WorkoutRecordDTO: Decodable {
                let id: String
                let user_id: String
                let exercise_type: String
                let exercise_name: String
                let duration: Double?
                let distance: Double?
                let calories_burned: Double
                let dessert_id: String
                let dessert_name: String
                let dessert_calories: Double
                let completion_date: String
                let equivalent_dessert_count: Double
                let workout_tag: String
                let created_at: String
            }
        }
        
        return NetworkManager.shared.requestRaw(
            endpoint: endpoint,
            method: .post,
            parameters: params,
            requiresAuth: true
        )
        .tryMap { data, response -> WorkoutRecord? in
            // 打印响应数据，用于调试
            if let jsonString = String(data: data, encoding: .utf8) {
                DRDebug("[APIService] 创建打卡响应: \(jsonString)")
            }
            
            // 解析响应
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(WorkoutRecordResponse.self, from: data)
            
            // 检查响应状态
            guard apiResponse.code == 0 || apiResponse.code == 200 else {
                DRError("[APIService] 创建打卡失败，错误码: \(apiResponse.code), 消息: \(apiResponse.message)")
                return nil
            }
            
            let dto = apiResponse.data
            
            // 解析日期
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            var completionDate: Date?
            // 尝试多种日期解析方法
            if let date = dateFormatter.date(from: dto.completion_date) {
                completionDate = date
            } else {
                // 如果失败，尝试不带毫秒的格式
                dateFormatter.formatOptions = [.withInternetDateTime]
                if let date = dateFormatter.date(from: dto.completion_date) {
                    completionDate = date
                } else {
                    // 使用更简单的格式再次尝试
                    let backupFormatter = DateFormatter()
                    backupFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    completionDate = backupFormatter.date(from: dto.completion_date) ?? Date()
                }
            }
            
            // 获取运动类型
            let exerciseType = APIExerciseType.fromString(dto.exercise_type, name: dto.exercise_name)
            
            // 创建甜品对象
            let dessert = DessertItem(
                id: dto.dessert_id,
                name: dto.dessert_name,
                imageName: "dessert_placeholder",
                calories: String(format: "%.0f", dto.dessert_calories),
                category: .dessert,
                description: "",
                backgroundColor: nil,
                isFeatured: false,
                relatedItems: [],
                categoryId: "0",
                categoryName: "甜点",
                displayOrder: 0,
                images: []
            )
            
            // 创建并返回WorkoutRecord对象
            return WorkoutRecord(
                id: dto.id,
                userId: dto.user_id,
                exerciseType: exerciseType,
                duration: dto.duration.map { TimeInterval($0) },
                distance: dto.distance,
                caloriesBurned: dto.calories_burned,
                dessert: dessert,
                date: completionDate ?? Date(),
                workoutTag: dto.workout_tag,
                equivalentDessertCount: dto.equivalent_dessert_count
            )
        }
        .mapError { error -> APIServiceError in
            if let networkError = error as? NetworkError {
                DRError("createWorkoutRecord网络错误: \(networkError)")
                
                // 针对特定错误类型进行更详细的错误提取
                if case .badRequest(let message) = networkError {
                    DRError("请求参数错误详情: \(message)")
                }
                
                // 针对网络错误进行特殊处理
                if case .unauthorized = networkError {
                    return .tokenExpired
                } else {
                    return .networkError(APINetworkError(error: networkError))
                }
            } else if let decodingError = error as? DecodingError {
                DRError("创建打卡记录响应解析错误: \(decodingError)")
                return .decodeError(decodingError.localizedDescription)
            } else {
                DRError("创建打卡记录未知错误: \(error)")
                return .unknown
            }
        }
        .eraseToAnyPublisher()
    }

    /// 获取用户的美食券列表
    func getUserVouchers(status: String? = nil, page: Int = 1, limit: Int = 20) -> AnyPublisher<[DessertVoucher], APIError> {
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
            return Fail(error: APIError.networkError("无法创建URL")).eraseToAnyPublisher()
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
                       let _ = dataDict["items"] as? [[String: Any]] {
                        
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
                                WorkoutCodingKey(stringValue: "code")!, 
                                DecodingError.Context(codingPath: [], debugDescription: "找不到键: code")
                            ))
                        }
                        
                        if json["data"] == nil {
                            DRError("[APIService] 美食券响应缺少data字段")
                            throw NetworkError.decodingFailed(DecodingError.keyNotFound(
                                WorkoutCodingKey(stringValue: "data")!, 
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
                        imageURL: dto.image_url,
                        exerciseType: nil,
                        exerciseName: nil
                    )
                }
            }
            .mapError { error -> APIError in
                if let decodingError = error as? DecodingError {
                    DRError("[APIService] 美食券解析错误: \(decodingError)")
                    return APIError.decodingError
                } else if let networkError = error as? NetworkError {
                    DRError("[APIService] 网络错误: \(networkError)")
                    return APIError.networkError(networkError.localizedDescription)
                } else {
                    DRError("[APIService] 获取美食券失败: \(error)")
                    return APIError.unknown
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// 获取美食券列表并包含图片信息
    func getUserVouchersWithImages(status: String = "", page: Int = 1, limit: Int = 10) -> AnyPublisher<BatchVoucherResponseWithDessertVoucher, APIError> {
        // 构建API端点 - 使用包含美食券、图片和记录信息的批量API
        let endpoint = "/api/v1/vouchers/batch?status=\(status)&page=\(page)&limit=\(limit)"
        
        DRDebug("[APIService] 获取美食券列表和图片: status=\(status), page=\(page), limit=\(limit)")
        
        return NetworkManager.shared.requestRaw(
            endpoint: endpoint,
            method: .get,
            parameters: nil,
            requiresAuth: true
        )
        .tryMap { data, response -> BatchVoucherResponseWithDessertVoucher in
            // 打印响应数据，用于调试
            if let jsonString = String(data: data, encoding: .utf8) {
                DRDebug("[APIService] 美食券批量API响应: \(jsonString)")
            }
            
            // 先尝试解析为字典，检查基本结构
            do {
                if let jsonObj = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // 检查关键字段是否存在
                    if let code = jsonObj["code"] as? Int {
                        DRDebug("[APIService] 响应code: \(code)")
                    } else {
                        DRError("[APIService] 响应缺少code字段")
                    }
                    
                    if let message = jsonObj["message"] as? String {
                        DRDebug("[APIService] 响应message: \(message)")
                    }
                    
                    if let dataObj = jsonObj["data"] as? [String: Any] {
                        DRDebug("[APIService] 数据字段结构: \(dataObj.keys)")
                        
                        // 检查是否有total字段
                        if let total = dataObj["total"] as? Int {
                            DRDebug("[APIService] 总记录数: \(total)")
                        } else {
                            DRError("[APIService] 数据缺少total字段")
                        }
                        
                        // 检查vouchers数组
                        if let vouchers = dataObj["vouchers"] as? [[String: Any]] {
                            DRDebug("[APIService] 美食券数量: \(vouchers.count)")
                            if let firstVoucher = vouchers.first {
                                DRDebug("[APIService] 第一个美食券字段: \(firstVoucher.keys)")
                            }
                        } else {
                            DRError("[APIService] 数据缺少vouchers数组或格式不正确")
                        }
                    } else {
                        DRError("[APIService] 响应缺少data字段或格式不正确")
                    }
                }
            } catch {
                DRError("[APIService] 解析原始JSON失败: \(error)")
            }
            
            // 尝试解码完整结构
            let decoder = JSONDecoder()
            do {
                let response = try decoder.decode(BatchVoucherResponse.self, from: data)
                DRDebug("[APIService] 成功解析BatchVoucherResponse: 总数=\(response.data.total), 当前页=\(response.data.page)")
                
                // 尝试转换为最终结构
                let vouchers = response.data.vouchers.map { voucherDTO in
                    return voucherDTO.toDessertVoucher(imageURLs: response.data.images, iconURLs: response.data.dessertIcons)
                }
                
                DRDebug("[APIService] 成功创建\(vouchers.count)个DessertVoucher对象")
                
                return BatchVoucherResponseWithDessertVoucher(
                    total: response.data.total,
                    page: response.data.page,
                    limit: response.data.limit,
                    vouchers: vouchers
                )
            } catch {
                DRError("[APIService] 解析BatchVoucherResponse失败: \(error)")
                throw error
            }
        }
        .mapError { error -> APIError in
            // 增强错误诊断
            DRError("[APIService] 获取美食券失败，详细错误: \(error)")
            
            if let apiError = error as? APIError {
                DRError("[APIService] 已知API错误: \(apiError.errorMessage)")
                return apiError
            }
            
            if let networkError = error as? NetworkError {
                DRError("[APIService] 网络错误类型: \(String(describing: networkError))")
                if case .unauthorized = networkError {
                    return .authError("登录已过期")
                } else if case .decodingFailed(let err) = networkError {
                    DRError("[APIService] 解码错误: \(err)")
                    return .decodingError
                } else {
                    return .networkError(networkError.localizedDescription)
                }
            }
            
            // 对于其他类型的错误，创建一个通用的APIError
            return .unknown
        }
        .eraseToAnyPublisher()
    }
    
    /// 获取美食券详情
    func getVoucherDetail(voucherId: String) -> AnyPublisher<DessertVoucher?, APIError> {
        let endpoint = ApiEndpoints.Vouchers.detail.replacingOccurrences(of: ":id", with: voucherId)
        
        // 单个美食券响应的包装结构
        struct VoucherDetailResponse: Decodable {
            let code: Int
            let message: String
            let data: VoucherDTO
            
            struct VoucherDTO: Decodable {
                let id: String
                let user_id: String
                let dessert_id: String
                let dessert_name: String
                let calories_value: Double
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
        
        DRDebug("[APIService] 请求美食券详情: \(endpoint)")
        
        return NetworkManager.shared.requestRaw(
            endpoint: endpoint,
            method: .get,
            parameters: nil,
            requiresAuth: true
        )
        .tryMap { data, response -> DessertVoucher? in
            // 打印响应数据，用于调试
            if let jsonString = String(data: data, encoding: .utf8) {
                DRDebug("[APIService] 美食券详情响应: \(jsonString)")
            }
            
            // 解析响应
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(VoucherDetailResponse.self, from: data)
            
            // 检查响应状态
            guard apiResponse.code == 0 || apiResponse.code == 200 else {
                DRError("[APIService] 获取美食券详情失败，错误码: \(apiResponse.code), 消息: \(apiResponse.message)")
                return nil
            }
            
            let dto = apiResponse.data
            
            // 解析日期
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            var createdAt: Date?
            // 尝试多种日期解析方法
            if let date = dateFormatter.date(from: dto.created_at) {
                createdAt = date
            } else {
                // 如果失败，尝试不带毫秒的格式
                dateFormatter.formatOptions = [.withInternetDateTime]
                if let date = dateFormatter.date(from: dto.created_at) {
                    createdAt = date
                } else {
                    // 使用更简单的格式再次尝试
                    let backupFormatter = DateFormatter()
                    backupFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    createdAt = backupFormatter.date(from: dto.created_at) ?? Date()
                }
            }
            
            // 解析可选日期
            var updatedAt: Date? = nil
            if let updatedAtStr = dto.updated_at, !updatedAtStr.isEmpty {
                if let date = dateFormatter.date(from: updatedAtStr) {
                    updatedAt = date
                } else {
                    let backupFormatter = DateFormatter()
                    backupFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    updatedAt = backupFormatter.date(from: updatedAtStr)
                }
            }
            
            var expireAt: Date? = nil
            if let expireAtStr = dto.expire_at, !expireAtStr.isEmpty {
                if let date = dateFormatter.date(from: expireAtStr) {
                    expireAt = date
                } else {
                    let backupFormatter = DateFormatter()
                    backupFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    expireAt = backupFormatter.date(from: expireAtStr)
                }
            }
            
            // 创建并返回美食券对象
            return DessertVoucher(
                id: dto.id,
                userId: dto.user_id,
                dessertId: dto.dessert_id,
                dessertName: dto.dessert_name,
                equivalentDessertCount: dto.equivalent_dessert_count,
                caloriesValue: dto.calories_value,
                workoutRecordId: dto.workout_record_id,
                status: dto.status,
                createdAt: createdAt ?? Date(),
                updatedAt: updatedAt,
                expireAt: expireAt,
                imageId: dto.image_id,
                imageURL: dto.image_url,
                exerciseType: nil,
                exerciseName: nil
            )
        }
        .mapError { error -> APIError in
            if let networkError = error as? NetworkError {
                DRError("[APIService] 获取美食券详情网络错误: \(networkError)")
                return APIError.networkError(networkError.localizedDescription)
            } else if let decodingError = error as? DecodingError {
                DRError("[APIService] 美食券详情解析错误: \(decodingError)")
                return APIError.decodingError
            } else {
                DRError("[APIService] 获取美食券详情失败: \(error)")
                return APIError.unknown
            }
        }
        .eraseToAnyPublisher()
    }

    /// 获取单条运动打卡记录
    func loadSingleWorkoutRecord(id: String) -> AnyPublisher<WorkoutRecord?, APIServiceError> {
        let endpoint = ApiEndpoints.Workout.base + "/\(id)"
        
        // 创建可解码的响应结构
        struct WorkoutRecordResponse: Decodable {
            let code: Int
            let message: String
            let data: WorkoutRecordDTO
        }
        
        // 从网络请求运动打卡记录
        return NetworkManager.shared.request(
            endpoint: endpoint,
            method: .get,
            parameters: nil,
            requiresAuth: true,
            responseType: WorkoutRecordResponse.self
        )
        .tryMap { response -> WorkoutRecord in
            // 将API响应中的DTO转换为应用内使用的领域模型
            let record = response.data.toDomainModel()
            return record
        }
        .map { record -> WorkoutRecord? in
            return record
        }
        .mapError { error -> APIServiceError in
            DRError("[APIService] 获取单条运动记录失败: \(error)")
            if let apiError = error as? APIServiceError {
                return apiError
            }
            if let networkError = error as? NetworkError {
                if case .unauthorized = networkError {
                    return .tokenExpired
                } else {
                    return .networkError(APINetworkError(error: networkError))
                }
            }
            return .unknown
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - 运动打卡记录响应模型

/// 运动打卡记录列表响应
struct WorkoutRecordsResponse: Codable {
    let code: Int
    let message: String
    let data: WorkoutRecordsData
    
    struct WorkoutRecordsData: Codable {
        let total: Int
        let page: Int
        let limit: Int
        let items: [APIWorkoutRecord]
    }
}

/// API响应的运动打卡记录
struct APIWorkoutRecord: Codable {
    let id: String
    let userId: String
    let dessertId: String
    let dessertName: String
    let dessertCalories: Double
    let exerciseType: String
    let exerciseName: String
    let completionDate: Date
    let duration: Double
    let distance: Double?
    let caloriesBurned: Double
    let equivalentDessertCount: Double
    let exerciseImageURL: String
    let dessertImageURL: String
    let note: String?
    let imageId: String?
    let imageURL: String?
    let dessertIconURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case dessertId = "dessert_id"
        case dessertName = "dessert_name"
        case dessertCalories = "dessert_calories"
        case exerciseType = "exercise_type"
        case exerciseName = "exercise_name"
        case completionDate = "completion_date"
        case duration
        case distance
        case caloriesBurned = "calories_burned"
        case equivalentDessertCount = "equivalent_dessert_count"
        case exerciseImageURL = "exercise_image_url"
        case dessertImageURL = "dessert_image_url"
        case note
        case imageId = "image_id"
        case imageURL = "image_url"
        case dessertIconURL = "dessert_icon_url"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        dessertId = try container.decode(String.self, forKey: .dessertId)
        dessertName = try container.decode(String.self, forKey: .dessertName)
        dessertCalories = try container.decode(Double.self, forKey: .dessertCalories)
        exerciseType = try container.decode(String.self, forKey: .exerciseType)
        exerciseName = try container.decode(String.self, forKey: .exerciseName)
        
        // 日期转换
        let dateString = try container.decode(String.self, forKey: .completionDate)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = dateFormatter.date(from: dateString) {
            completionDate = date
        } else {
            // 尝试备用格式
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            if let date = dateFormatter.date(from: dateString) {
                completionDate = date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .completionDate, in: container, debugDescription: "日期格式无法解析: \(dateString)")
            }
        }
        
        duration = try container.decode(Double.self, forKey: .duration)
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)
        caloriesBurned = try container.decode(Double.self, forKey: .caloriesBurned)
        equivalentDessertCount = try container.decode(Double.self, forKey: .equivalentDessertCount)
        exerciseImageURL = try container.decode(String.self, forKey: .exerciseImageURL)
        dessertImageURL = try container.decode(String.self, forKey: .dessertImageURL)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        imageId = try container.decodeIfPresent(String.self, forKey: .imageId)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        dessertIconURL = try container.decodeIfPresent(String.self, forKey: .dessertIconURL)
    }
} 

// MARK: - 美食记录DTO

/// 美食打卡记录DTO
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
    
    /// 将DTO转换为领域模型
    func toDomainModel() -> WorkoutRecord {
        // 1. 处理运动类型
        let exerciseType = APIExerciseType.fromString(exercise_type, name: exercise_name)
        
        // 2. 创建甜品对象
        let dessert = DessertItem(
            id: dessert_id,
            name: dessert_name,
            imageName: dessert_id,
            calories: "\(dessert_calories)",
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
        
        // 3. 处理日期
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var recordDate: Date?
        // 尝试多种日期解析方法
        if let date = dateFormatter.date(from: completion_date) {
            recordDate = date
        } else {
            // 如果失败，尝试不带毫秒的格式
            dateFormatter.formatOptions = [.withInternetDateTime]
            if let date = dateFormatter.date(from: completion_date) {
                recordDate = date
            } else {
                // 如果仍然失败，尝试其他格式
                let backupFormatter = DateFormatter()
                backupFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                if let date = backupFormatter.date(from: completion_date) {
                    recordDate = date
                } else {
                    // 尝试简单的年月日格式
                    backupFormatter.dateFormat = "yyyy-MM-dd"
                    if let date = backupFormatter.date(from: completion_date) {
                        recordDate = date
                    } else {
                        // 日期解析失败，使用当前时间
                        DRError("[WorkoutRecordDTO] 无法解析日期: \(completion_date)，使用当前时间")
                        recordDate = Date()
                    }
                }
            }
        }
        
        // 4. 创建WorkoutRecord对象
        return WorkoutRecord(
            id: id,
            userId: user_id,
            exerciseType: exerciseType,
            duration: duration.map { TimeInterval($0) },
            distance: distance,
            caloriesBurned: calories_burned,
            dessert: dessert,
            date: recordDate ?? Date(),
            workoutTag: workout_tag ?? "",
            equivalentDessertCount: equivalent_dessert_count
        )
    }
}

// 修复自定义编码键相关问题
// 实现必要的公共CodingKey结构体
public struct WorkoutCodingKey: CodingKey {
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
