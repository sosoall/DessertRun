import Foundation

/// 用户模型，存储用户基本信息和认证状态
class User: Identifiable, Codable, ObservableObject {
    let id: UUID
    @Published var phoneNumber: String
    @Published var nickname: String?
    @Published var avatar: String?
    @Published var gender: Gender?
    @Published var birthYear: Int?
    @Published var registerDate: Date
    @Published var isProfileCompleted: Bool
    @Published var isNewUser: Bool
    
    // 存储后端用户ID (与UUID区分)
    var apiUserId: String?
    
    // 新增：身体数据和运动习惯作为独立对象
    @Published var bodyData: BodyData?
    @Published var exerciseHabit: ExerciseHabit?
    
    enum Gender: String, Codable {
        case male = "男"
        case female = "女"
        
        // 转换为API期望的字符串格式（与rawValue相同）
        var toApiValue: String {
            return self.rawValue
        }
        
        // 从API字符串格式转换（不再需要int转换）
        static func fromApiString(_ value: String) -> Gender? {
            switch value {
            case "男": return .male
            case "女": return .female
            default: return nil
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, phoneNumber, nickname, avatar, gender
        case birthYear
        case registerDate, isProfileCompleted, apiUserId
        case isNewUser
        case bodyData, exerciseHabit
    }
    
    init(id: UUID = UUID(), 
         phoneNumber: String, 
         nickname: String? = nil,
         avatar: String? = nil,
         gender: Gender? = nil,
         birthYear: Int? = nil,
         bodyData: BodyData? = nil,
         exerciseHabit: ExerciseHabit? = nil,
         isProfileCompleted: Bool = false,
         isNewUser: Bool = true,
         apiUserId: String? = nil) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.nickname = nickname
        self.avatar = avatar
        self.gender = gender
        self.birthYear = birthYear
        self.bodyData = bodyData
        self.exerciseHabit = exerciseHabit
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
        birthYear = try container.decodeIfPresent(Int.self, forKey: .birthYear)
        bodyData = try container.decodeIfPresent(BodyData.self, forKey: .bodyData)
        exerciseHabit = try container.decodeIfPresent(ExerciseHabit.self, forKey: .exerciseHabit)
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
        try container.encodeIfPresent(birthYear, forKey: .birthYear)
        try container.encodeIfPresent(bodyData, forKey: .bodyData)
        try container.encodeIfPresent(exerciseHabit, forKey: .exerciseHabit)
        try container.encode(registerDate, forKey: .registerDate)
        try container.encode(isProfileCompleted, forKey: .isProfileCompleted)
        try container.encode(isNewUser, forKey: .isNewUser)
        try container.encodeIfPresent(apiUserId, forKey: .apiUserId)
    }
    
    /// 为API更新请求准备数据 - 这个方法仅用于旧的更新接口，将来可能会弃用
    func prepareProfileUpdateRequest() -> UpdateProfileRequest {
        return UpdateProfileRequest(
            nickname: nickname,
            avatar: avatar,
            gender: gender?.toApiValue,
            height: bodyData?.height,
            weight: bodyData?.weight,
            hasExerciseHabit: exerciseHabit?.hasExerciseHabit
        )
    }
    
    /// 为API更新基本信息请求准备数据
    func prepareBasicInfoUpdateRequest() -> UpdateBasicInfoRequest {
        return UpdateBasicInfoRequest(
            nickname: nickname,
            avatar: avatar,
            gender: gender?.toApiValue,
            birthYear: birthYear
        )
    }
    
    /// 为API更新身体数据请求准备数据
    func prepareBodyDataUpdateRequest() -> UpdateBodyDataRequest {
        return UpdateBodyDataRequest(
            height: bodyData?.height,
            weight: bodyData?.weight
        )
    }
    
    /// 为API更新运动习惯请求准备数据
    func prepareExerciseHabitUpdateRequest() -> UpdateExerciseHabitRequest {
        return UpdateExerciseHabitRequest(
            hasExerciseHabit: exerciseHabit?.hasExerciseHabit,
            exerciseFrequency: exerciseHabit?.exerciseFrequency,
            exerciseDuration: exerciseHabit?.exerciseDuration
        )
    }
}

/// 用户身体数据模型
class BodyData: Codable, ObservableObject {
    @Published var height: Double?  // 身高（厘米）
    @Published var weight: Double?  // 体重（公斤）
    
    enum CodingKeys: String, CodingKey {
        case height, weight
    }
    
    init(height: Double? = nil, weight: Double? = nil) {
        self.height = height
        self.weight = weight
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        height = try container.decodeIfPresent(Double.self, forKey: .height)
        weight = try container.decodeIfPresent(Double.self, forKey: .weight)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encodeIfPresent(weight, forKey: .weight)
    }
}

/// 用户运动习惯模型
class ExerciseHabit: Codable, ObservableObject {
    @Published var hasExerciseHabit: Bool?  // 是否有运动习惯
    @Published var exerciseFrequency: Int?  // 运动频率（次/周）
    @Published var exerciseDuration: Int?   // 运动时长（分钟/次）
    
    enum CodingKeys: String, CodingKey {
        case hasExerciseHabit, exerciseFrequency, exerciseDuration
    }
    
    init(hasExerciseHabit: Bool? = nil, exerciseFrequency: Int? = nil, exerciseDuration: Int? = nil) {
        self.hasExerciseHabit = hasExerciseHabit
        self.exerciseFrequency = exerciseFrequency
        self.exerciseDuration = exerciseDuration
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hasExerciseHabit = try container.decodeIfPresent(Bool.self, forKey: .hasExerciseHabit)
        exerciseFrequency = try container.decodeIfPresent(Int.self, forKey: .exerciseFrequency)
        exerciseDuration = try container.decodeIfPresent(Int.self, forKey: .exerciseDuration)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(hasExerciseHabit, forKey: .hasExerciseHabit)
        try container.encodeIfPresent(exerciseFrequency, forKey: .exerciseFrequency)
        try container.encodeIfPresent(exerciseDuration, forKey: .exerciseDuration)
    }
} 