import Foundation
import Combine

extension APIService {
    struct UserProfileResponse: Decodable {
        let code: Int
        let message: String
        let data: APIUser
    }
    /// 获取当前登录用户资料
    func fetchUserProfile() -> AnyPublisher<APIUser, APIServiceError> {
        let endpoint = "/api/v1/users/profile"
        return NetworkManager.shared.request(endpoint: endpoint, method: .get, requiresAuth: true, responseType: UserProfileResponse.self)
            .map { $0.data }
            .mapError { APIServiceError.networkError(APINetworkError(error: $0)) }
            .eraseToAnyPublisher()
    }

    // MARK: - 运动习惯

    // DTO 对应 /exercise-habits/latest 返回的 data 字段
    struct APIExerciseHabitDTO: Decodable {
        let id: String
        let hasExerciseHabit: Bool?
        let exerciseFrequency: Int?
        let exerciseDuration: Int?
        let recordedAt: String?

        enum CodingKeys: String, CodingKey {
            case id
            case hasExerciseHabit = "has_exercise_habit"
            case exerciseFrequency = "exercise_frequency"
            case exerciseDuration = "exercise_duration"
            case recordedAt = "recorded_at"
        }
        // 自定义解码以兼容 "" 字符串
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            hasExerciseHabit = try container.decodeIfPresent(Bool.self, forKey: .hasExerciseHabit)

            // 频率/时长字段后端可能返回 ""，需要做容错
            if let freqInt = try? container.decodeIfPresent(Int.self, forKey: .exerciseFrequency) {
                exerciseFrequency = freqInt
            } else if let freqStr = try? container.decodeIfPresent(String.self, forKey: .exerciseFrequency),
                      let freq = Int(freqStr) {
                exerciseFrequency = freq
            } else {
                exerciseFrequency = nil
            }

            if let durInt = try? container.decodeIfPresent(Int.self, forKey: .exerciseDuration) {
                exerciseDuration = durInt
            } else if let durStr = try? container.decodeIfPresent(String.self, forKey: .exerciseDuration),
                      let dur = Int(durStr) {
                exerciseDuration = dur
            } else {
                exerciseDuration = nil
            }

            recordedAt = try container.decodeIfPresent(String.self, forKey: .recordedAt)
        }
    }

    struct ExerciseHabitResponse: Decodable {
        let code: Int
        let message: String
        let data: APIExerciseHabitDTO
    }

    /// 获取最新运动习惯
    func fetchUserExerciseHabit() -> AnyPublisher<APIExerciseHabitDTO, APIServiceError> {
        let endpoint = "/api/v1/exercise-habits/latest"
        return NetworkManager.shared.request(endpoint: endpoint, method: .get, requiresAuth: true, responseType: ExerciseHabitResponse.self)
            .tryMap { resp -> APIExerciseHabitDTO in
                if resp.code == 0 || resp.code == 200 {
                    return resp.data
                } else {
                    throw NetworkError.serverError(resp.code, resp.message)
                }
            }
            .mapError { error -> APIServiceError in
                if let network = error as? NetworkError {
                    return .networkError(APINetworkError(error: network))
                } else if let apiErr = error as? APIServiceError {
                    return apiErr
                } else {
                    return .unknown
                }
            }
            .eraseToAnyPublisher()
    }
} 