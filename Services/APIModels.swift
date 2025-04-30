import Foundation
import SwiftUI

// 注意：
// 1. EmptyResponseData 和 APIResponse 已移至 NetworkManager.swift
// 2. API响应类型（DessertListResponse、DessertSearchResponse、DessertDetailResponse、CategoryListResponse）
//    已移至DessertRun/Models/DessertAPIModels.swift文件中
// 这里只保留特定于API的辅助模型

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
            id: Int(id) ?? 0,
            name: name,
            imageName: imageName ?? "default_food",
            calories: "\(calories)",
            category: foodCategory,
            description: description,
            backgroundColor: nil,
            isFeatured: false,
            relatedItems: [],
            categoryId: Int(categoryId) ?? 0,
            categoryName: categoryName,
            displayOrder: displayOrder,
            images: [DessertImage(id: 0, url: imageName ?? "default_food", type: "regular", displayOrder: 1)]
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