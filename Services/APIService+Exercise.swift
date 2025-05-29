import Foundation
import Combine
import SwiftUI

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
        
        return NetworkManager.shared.requestRaw(
            endpoint: endpoint,
            method: .get,
            parameters: [
                "type": exerciseType,
                "calories": "\(calories)"
            ],
            requiresAuth: true
        )
        .tryMap { data, _ -> ExerciseTimeResponse? in
            // 打印原始响应数据，用于调试
            if let jsonString = String(data: data, encoding: .utf8) {
                DRDebug("[APIService] calculateExerciseTime 原始响应: \(jsonString)")
            }
            
            // 解析JSON为字典
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                throw NetworkError.decodingFailed(NSError(domain: "JSON解析错误", code: -1, userInfo: nil))
            }
            
            // 检查响应状态
            guard let code = json["code"] as? Int, (code == 0 || code == 200) else {
                let message = json["message"] as? String ?? "未知错误"
                throw NetworkError.badRequest(message)
            }
            
            // 解析data字段
            guard let dataObj = json["data"] as? [String: Any] else {
                DRError("[APIService] calculateExerciseTime 响应缺少data字段")
                throw NetworkError.decodingFailed(NSError(domain: "缺少data字段", code: -1, userInfo: nil))
            }
            
            // 提取各个字段
            guard let exerciseTypeStr = dataObj["exercise_type"] as? String,
                  let caloriesValue = dataObj["calories"] as? Double,
                  let durationValue = dataObj["duration"] as? Double,
                  let weightValue = dataObj["weight"] as? Double else {
                DRError("[APIService] calculateExerciseTime data字段格式不正确: \(dataObj)")
                throw NetworkError.decodingFailed(NSError(domain: "data字段格式错误", code: -1, userInfo: nil))
            }
            
            // 创建响应对象
            return ExerciseTimeResponse(
                exerciseType: exerciseTypeStr,
                calories: caloriesValue,
                duration: durationValue,
                weight: weightValue
            )
        }
        .mapError { error -> APIServiceError in
            DRError("[APIService] 计算运动时间API错误: \(error)")
            
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

        return NetworkManager.shared.requestRaw(
            endpoint: endpoint,
            method: .get,
            parameters: [
                "type": exerciseType,
                "calories": "\(calories)"
            ],
            requiresAuth: true
        )
        .tryMap { data, _ -> ExerciseDistanceResponse? in
            // 打印原始响应数据，用于调试
            if let jsonString = String(data: data, encoding: .utf8) {
                DRDebug("[APIService] calculateExerciseDistance 原始响应: \(jsonString)")
            }
            
            // 解析JSON为字典
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                throw NetworkError.decodingFailed(NSError(domain: "JSON解析错误", code: -1, userInfo: nil))
            }
            
            // 检查响应状态
            guard let code = json["code"] as? Int, (code == 0 || code == 200) else {
                let message = json["message"] as? String ?? "未知错误"
                throw NetworkError.badRequest(message)
            }
            
            // 解析data字段
            guard let dataObj = json["data"] as? [String: Any] else {
                DRError("[APIService] calculateExerciseDistance 响应缺少data字段")
                throw NetworkError.decodingFailed(NSError(domain: "缺少data字段", code: -1, userInfo: nil))
            }
            
            // 提取各个字段
            guard let exerciseTypeStr = dataObj["exercise_type"] as? String,
                  let caloriesValue = dataObj["calories"] as? Double,
                  let distanceValue = dataObj["distance"] as? Double,
                  let weightValue = dataObj["weight"] as? Double else {
                DRError("[APIService] calculateExerciseDistance data字段格式不正确: \(dataObj)")
                throw NetworkError.decodingFailed(NSError(domain: "data字段格式错误", code: -1, userInfo: nil))
            }
            
            // 创建响应对象
            return ExerciseDistanceResponse(
                exerciseType: exerciseTypeStr,
                calories: caloriesValue,
                distance: distanceValue,
                weight: weightValue
            )
        }
        .mapError { error -> APIServiceError in
            DRError("[APIService] 计算运动距离API错误: \(error)")
            
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