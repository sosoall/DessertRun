import Foundation
import SwiftUI
import Combine

/// API 请求模型
struct UpdateProfileRequest: Codable {
    let nickname: String?
    let avatar: String?
    let gender: String?
    let height: Double?
    let weight: Double?
    let hasExerciseHabit: Bool?
}

struct UpdateBasicInfoRequest: Codable {
    let nickname: String?
    let avatar: String?
    let gender: String?
    let birthYear: Int?
    
    enum CodingKeys: String, CodingKey {
        case nickname, avatar, gender
        case birthYear = "birth_year"
    }
}

struct UpdateBodyDataRequest: Codable {
    let height: Double?
    let weight: Double?
    
    enum CodingKeys: String, CodingKey {
        case height, weight
    }
}

struct UpdateExerciseHabitRequest: Codable {
    let hasExerciseHabit: Bool?
    let exerciseFrequency: Int?
    let exerciseDuration: Int?
    
    enum CodingKeys: String, CodingKey {
        case hasExerciseHabit = "has_exercise_habit"
        case exerciseFrequency = "exercise_frequency"
        case exerciseDuration = "exercise_duration"
    }
}

/// API响应模型
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

struct UserBodyDataResponse: Codable {
    let height: Double?
    let weight: Double?
    
    enum CodingKeys: String, CodingKey {
        case height, weight
    }
}

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