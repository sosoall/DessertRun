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
} 