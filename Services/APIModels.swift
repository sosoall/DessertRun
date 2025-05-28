import Foundation
import SwiftUI

// 注意：
// 1. EmptyResponseData 和 APIResponse 已移至 NetworkManager.swift
// 2. API响应类型（DessertListResponse、DessertSearchResponse、DessertDetailResponse、CategoryListResponse）
//    已移至DessertRun/Models/DessertAPIModels.swift文件中
// 这里只保留特定于API的辅助模型

// MARK: - 用户相关模型

/// API用户模型
public struct APIUser: Decodable, Identifiable {
    public let id: String
    public let phone: String
    public let nickname: String?
    public let avatar: String?
    public let gender: String?  // 从服务器接收时仍为String类型("男"/"女")
    public let birthYear: Int?  // 添加出生年份字段
    public let createdAt: String?
    public let updatedAt: String?
    public let isNewUser: Bool?
    public let isProfileCompleted: Bool?
    
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
    public init(id: String, phone: String, nickname: String?, avatar: String?, gender: String?,
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
    public init(from decoder: Decoder) throws {
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

// MARK: - 运动相关模型

/// API返回的运动类型
struct APIExerciseType: Codable, Identifiable, Hashable {
    let type: String
    let name: String
    let description: String
    let iconName: String
    let usesDistance: Bool
    let backgroundColor: String
    let caloriesPerMinPerKg: Double
    let caloriesPerKmPerKg: Double?
    let displayOrder: Int
    
    var id: String { type }
    
    enum CodingKeys: String, CodingKey {
        case type, name, description
        case iconName = "icon_name"
        case usesDistance = "uses_distance"
        case backgroundColor = "background_color"
        case displayOrder = "display_order"
        case caloriesPerMinPerKg = "calories_per_min_per_kg"
        case caloriesPerKmPerKg = "calories_per_km_per_kg"
    }
    
    // 添加Hashable协议所需的函数
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
    }
    
    // 添加Equatable协议所需的函数
    static func == (lhs: APIExerciseType, rhs: APIExerciseType) -> Bool {
        return lhs.type == rhs.type
    }
    
    // 添加颜色转换计算属性
    var color: Color {
        Color(hex: backgroundColor)
    }
}

/// 运动类型响应
struct ExerciseTypesResponse: Codable {
    let code: Int
    let message: String
    let data: [APIExerciseType]
}

/// 运动时间响应
struct ExerciseTimeResponse: Codable {
    let exerciseType: String
    let calories: Double
    let duration: Double  // 单位：分钟
    let weight: Double    // 单位：公斤
    
    enum CodingKeys: String, CodingKey {
        case exerciseType = "exercise_type"
        case calories, duration, weight
    }
}

/// 运动距离响应
struct ExerciseDistanceResponse: Codable {
    let exerciseType: String
    let calories: Double
    let distance: Double  // 单位：公里
    let weight: Double    // 单位：公斤
    
    enum CodingKeys: String, CodingKey {
        case exerciseType = "exercise_type"
        case calories, distance, weight
    }
}

// MARK: - 甜品相关模型

/// API返回的美食项目
struct APIFoodItem: Codable {
    let id: String
    let name: String
    let categoryId: String
    let categoryName: String
    let description: String
    let calories: Int
    let keywords: String?
    let imageName: String?
    let displayOrder: Int
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, calories, keywords, displayOrder
        case categoryId = "category_id"
        case categoryName = "category_name"
        case imageName = "image_name"
        case isActive = "is_active"
    }
    
    /// 转换为DessertItem模型
    func toDessertItem() -> DessertItem {
        // 确定食品分类
        let foodCategory = FoodCategory.allCases.first { $0.rawValue == categoryName } ?? .dessert
        
        return DessertItem(
            id: id,  // 直接使用原始id字符串
            name: name,
            imageName: imageName ?? "default_food",
            calories: "\(calories)",
            category: foodCategory,
            description: description,
            backgroundColor: nil,
            isFeatured: false,
            relatedItems: [],
            categoryId: categoryId,  // 直接使用原始categoryId字符串
            categoryName: categoryName,
            displayOrder: displayOrder,
            images: [DessertImage(id: "1", url: imageName ?? "default_food", type: "regular", displayOrder: 1)]  // 使用字符串ID
        )
    }
}

/// API返回的分类
struct APICategory: Codable {
    let id: String
    let name: String
    let parentId: String?
    let displayOrder: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, displayOrder
        case parentId = "parent_id"
    }
}

/// 美食详情响应（内部使用）
struct APIDessertDetail: Codable {
    let id: String
    let name: String
    let categoryId: String
    let categoryName: String
    let description: String
    let calories: Int
    let keywords: String?
    let imageName: String?
    let displayOrder: Int
    let isActive: Bool
    let relatedItems: [APIFoodItem]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, calories, keywords, displayOrder, isActive
        case categoryId = "category_id"
        case categoryName = "category_name"
        case imageName = "image_name"
        case relatedItems = "related_items"
    }
}

// 将WorkoutStatsResponse重命名为APIWorkoutStatsResponse
struct APIWorkoutStatsResponse: Codable {
    let code: Int
    let message: String
    let data: WorkoutStatsData
    
    struct WorkoutStatsData: Codable {
        let totalWorkouts: Int
        let totalCalories: Double
        let totalDuration: Double
        let totalDistance: Double
        let workoutDays: Int
        let dailyStats: [DailyStatData]
        let exerciseTypes: [String: ExerciseTypeStats]
    }
    
    struct DailyStatData: Codable {
        let date: String
        let hasWorkout: Bool
        let totalDessertCount: Double?
        let caloriesBurned: Double?
        let mostPopularDessert: MostPopularDessert?
        
        struct MostPopularDessert: Codable {
            let dessertId: String
            let dessertName: String
        }
    }
    
    struct ExerciseTypeStats: Codable {
        let type: String
        let name: String
        let count: Int
        let totalCalories: Double
        let totalDuration: Double
    }
}

/// 认证响应数据
public struct AuthResponseData: Decodable {
    public let token: String
    public let userID: String
    public let isNewUser: Bool
    
    enum CodingKeys: String, CodingKey {
        case token
        case userID = "user_id"
        case isNewUser = "is_new_user"
    }
    
    public var uuid: UUID? {
        return UUID(uuidString: userID)
    }
}

/// 认证响应包装器（用于直接解析完整的API响应）
public struct AuthResponseWrapper: Decodable {
    public let code: Int
    public let message: String
    public let data: AuthResponseData
}

/// 周统计API响应
struct APIWeeklyWorkoutStatsResponse: Codable {
    let code: Int
    let message: String
    let data: WeeklyStatsData
    
    struct WeeklyStatsData: Codable {
        let totalWorkouts: Int
        let totalCalories: Double
        let totalDuration: Double
        let totalDistance: Double
        let workoutDays: Int
        let weekRange: WeekRange
        let dailyStats: [DailyStatData]
        
        struct WeekRange: Codable {
            let startDate: String
            let endDate: String
        }
        
        struct DailyStatData: Codable, Identifiable {
            let date: String
            let day: String
            let hasWorkout: Bool
            let caloriesBurned: Double
            let targetCalories: Double
            let dessertCount: Double
            let dessertId: String?
            let dessertName: String?
            
            var id: String { date }
            
            // 计算属性：是否完成目标
            var isTargetAchieved: Bool {
                return hasWorkout && caloriesBurned >= targetCalories
            }
            
            // 计算属性：目标完成百分比
            var targetAchievedPercentage: Double {
                guard targetCalories > 0 else { return 0 }
                return min(caloriesBurned / targetCalories, 1.0)
            }
        }
    }
}

// MARK: - 挑战相关模型

// 注意：ChallengeProgressResponse等模型已在ChallengeEnrollment.swift中定义
// 这里移除重复定义，使用现有的模型 