import Foundation

/// 用户模型，存储用户基本信息和认证状态
class User: Identifiable, Codable, ObservableObject {
    let id: UUID
    @Published var phoneNumber: String
    @Published var nickname: String?
    @Published var avatar: String?
    @Published var gender: Gender?
    @Published var height: Double?
    @Published var weight: Double?
    @Published var hasExerciseHabit: Bool?
    @Published var birthYear: Int?
    @Published var registerDate: Date
    @Published var isProfileCompleted: Bool
    @Published var isNewUser: Bool
    
    // 存储后端用户ID (与UUID区分)
    var apiUserId: String?
    
    enum Gender: String, Codable {
        case male = "男"
        case female = "女"
        
        // 转换为后端接受的整数格式
        var toApiValue: Int {
            return self == .male ? 1 : 2
        }
        
        // 从后端整数格式转换
        static func fromApiValue(_ value: Int) -> Gender? {
            switch value {
            case 1: return .male
            case 2: return .female
            default: return nil
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, phoneNumber, nickname, avatar, gender, height, weight, hasExerciseHabit
        case birthYear
        case registerDate, isProfileCompleted, apiUserId
        case isNewUser
    }
    
    init(id: UUID = UUID(), 
         phoneNumber: String, 
         nickname: String? = nil,
         avatar: String? = nil,
         gender: Gender? = nil, 
         height: Double? = nil, 
         weight: Double? = nil, 
         hasExerciseHabit: Bool? = nil,
         birthYear: Int? = nil,
         isProfileCompleted: Bool = false,
         isNewUser: Bool = true,
         apiUserId: String? = nil) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.nickname = nickname
        self.avatar = avatar
        self.gender = gender
        self.height = height
        self.weight = weight
        self.hasExerciseHabit = hasExerciseHabit
        self.birthYear = birthYear
        self.registerDate = Date()
        self.isProfileCompleted = isProfileCompleted
        self.isNewUser = isNewUser
        self.apiUserId = apiUserId
    }
    
    // Codable实现
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        phoneNumber = try container.decode(String.self, forKey: .phoneNumber)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        avatar = try container.decodeIfPresent(String.self, forKey: .avatar)
        gender = try container.decodeIfPresent(Gender.self, forKey: .gender)
        height = try container.decodeIfPresent(Double.self, forKey: .height)
        weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        hasExerciseHabit = try container.decodeIfPresent(Bool.self, forKey: .hasExerciseHabit)
        birthYear = try container.decodeIfPresent(Int.self, forKey: .birthYear)
        registerDate = try container.decode(Date.self, forKey: .registerDate)
        isProfileCompleted = try container.decode(Bool.self, forKey: .isProfileCompleted)
        isNewUser = try container.decode(Bool.self, forKey: .isNewUser)
        apiUserId = try container.decodeIfPresent(String.self, forKey: .apiUserId)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(nickname, forKey: .nickname)
        try container.encodeIfPresent(avatar, forKey: .avatar)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encodeIfPresent(hasExerciseHabit, forKey: .hasExerciseHabit)
        try container.encodeIfPresent(birthYear, forKey: .birthYear)
        try container.encode(registerDate, forKey: .registerDate)
        try container.encode(isProfileCompleted, forKey: .isProfileCompleted)
        try container.encode(isNewUser, forKey: .isNewUser)
        try container.encodeIfPresent(apiUserId, forKey: .apiUserId)
    }
    
    /// 为API更新请求准备数据
    func prepareProfileUpdateRequest() -> UpdateProfileRequest {
        return UpdateProfileRequest(
            nickname: nickname,
            avatar: avatar,
            gender: gender?.toApiValue,
            height: height,
            weight: weight,
            hasExerciseHabit: hasExerciseHabit
        )
    }
} 