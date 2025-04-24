import Foundation

/// 用户模型，存储用户基本信息和认证状态
class User: Identifiable, Codable, ObservableObject {
    let id: UUID
    @Published var phoneNumber: String
    @Published var nickname: String?
    @Published var gender: Gender?
    @Published var height: Double?
    @Published var weight: Double?
    @Published var hasExerciseHabit: Bool?
    @Published var birthYear: Int?
    @Published var exerciseFrequency: ExerciseFrequency?
    @Published var exerciseDuration: ExerciseDuration?
    @Published var registerDate: Date
    @Published var isProfileCompleted: Bool
    
    enum Gender: String, Codable {
        case male = "男"
        case female = "女"
    }
    
    enum ExerciseFrequency: String, Codable {
        case none = "不经常运动"
        case oneToTwo = "每周1-2次"
        case threeToFive = "每周3-5次"
        case daily = "几乎每天"
    }
    
    enum ExerciseDuration: String, Codable {
        case lessThanThirty = "少于30分钟"
        case thirtyToSixty = "30-60分钟"
        case sixtyToNinety = "60-90分钟"
        case moreThanNinety = "90分钟以上"
    }
    
    enum CodingKeys: String, CodingKey {
        case id, phoneNumber, nickname, gender, height, weight, hasExerciseHabit
        case birthYear, exerciseFrequency, exerciseDuration
        case registerDate, isProfileCompleted
    }
    
    init(id: UUID = UUID(), 
         phoneNumber: String, 
         nickname: String? = nil, 
         gender: Gender? = nil, 
         height: Double? = nil, 
         weight: Double? = nil, 
         hasExerciseHabit: Bool? = nil,
         birthYear: Int? = nil,
         exerciseFrequency: ExerciseFrequency? = nil,
         exerciseDuration: ExerciseDuration? = nil,
         isProfileCompleted: Bool = false) {
        self.id = id
        self.phoneNumber = phoneNumber
        self.nickname = nickname
        self.gender = gender
        self.height = height
        self.weight = weight
        self.hasExerciseHabit = hasExerciseHabit
        self.birthYear = birthYear
        self.exerciseFrequency = exerciseFrequency
        self.exerciseDuration = exerciseDuration
        self.registerDate = Date()
        self.isProfileCompleted = isProfileCompleted
    }
    
    // Codable实现
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        phoneNumber = try container.decode(String.self, forKey: .phoneNumber)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        gender = try container.decodeIfPresent(Gender.self, forKey: .gender)
        height = try container.decodeIfPresent(Double.self, forKey: .height)
        weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        hasExerciseHabit = try container.decodeIfPresent(Bool.self, forKey: .hasExerciseHabit)
        birthYear = try container.decodeIfPresent(Int.self, forKey: .birthYear)
        exerciseFrequency = try container.decodeIfPresent(ExerciseFrequency.self, forKey: .exerciseFrequency)
        exerciseDuration = try container.decodeIfPresent(ExerciseDuration.self, forKey: .exerciseDuration)
        registerDate = try container.decode(Date.self, forKey: .registerDate)
        isProfileCompleted = try container.decode(Bool.self, forKey: .isProfileCompleted)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(phoneNumber, forKey: .phoneNumber)
        try container.encodeIfPresent(nickname, forKey: .nickname)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encodeIfPresent(hasExerciseHabit, forKey: .hasExerciseHabit)
        try container.encodeIfPresent(birthYear, forKey: .birthYear)
        try container.encodeIfPresent(exerciseFrequency, forKey: .exerciseFrequency)
        try container.encodeIfPresent(exerciseDuration, forKey: .exerciseDuration)
        try container.encode(registerDate, forKey: .registerDate)
        try container.encode(isProfileCompleted, forKey: .isProfileCompleted)
    }
} 