import Foundation
import Combine

// MARK: - 运动相关 API 获取运动类型、计算运动时间、计算运动距离、获取单个运动类型详细信息
extension APIService {

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

    return NetworkManager.shared.request(
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
    .mapError { error -> APIServiceError in
        if let networkError = error as? NetworkError {
            return .networkError(APINetworkError(error: networkError))
        } else {
            return .unknown
        }
    }
    .eraseToAnyPublisher()
    }

    /// 计算消耗指定卡路里所需的运动距离
    /// - Parameters:
    ///   - exerciseType: 运动类型标识
    ///   - calories: 目标卡路里
    /// - Returns: 包含计算结果的发布者
    func calculateExerciseDistance(exerciseType: String, calories: Double) -> AnyPublisher<ExerciseDistanceResponse?, APIServiceError> {
    let endpoint = ApiEndpoints.Exercise.calculateDistance

    return NetworkManager.shared.request(
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
    .mapError { error -> APIServiceError in
        if let networkError = error as? NetworkError {
            return .networkError(APINetworkError(error: networkError))
        } else {
            return .unknown
        }
    }
    .eraseToAnyPublisher()
    }

    /// 获取单个运动类型的详细信息
    /// - Parameter type: 运动类型标识符
    /// - Returns: 包含运动类型详情的发布者
    func getExerciseTypeInfo(type: String) -> AnyPublisher<APIExerciseType?, APIServiceError> {
    let endpoint = "/api/v1/exercises/types/\(type)"

    return NetworkManager.shared.request(
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
    .mapError { error -> APIServiceError in
        if let networkError = error as? NetworkError {
            return .networkError(APINetworkError(error: networkError))
        } else {
            return .unknown
        }
    }
    .eraseToAnyPublisher()
    }
}