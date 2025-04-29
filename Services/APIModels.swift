import Foundation
import SwiftUI

// 注意：
// 1. EmptyResponseData 和 APIResponse 已移至 NetworkManager.swift
// 2. API响应类型（DessertListResponse、DessertSearchResponse、DessertDetailResponse、CategoryListResponse）
//    已移至DessertRun/Models/DessertAPIModels.swift文件中
// 这里只保留特定于API的辅助模型

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