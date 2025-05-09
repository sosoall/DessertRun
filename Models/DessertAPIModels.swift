import Foundation

// MARK: - 美食列表响应
struct DessertListResponse: Decodable {
    let total: Int
    let items: [DessertItemResponse]
}

// MARK: - 美食项响应
struct DessertItemResponse: Decodable, Identifiable {
    let id: String
    let name: String
    let categoryID: String
    let categoryName: String
    let calories: Double
    let description: String
    let displayOrder: Int
    let isImportant: Bool
    let images: [String: String] // 类型 -> URL
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case categoryID = "category_id"
        case categoryName = "category_name"
        case calories
        case description
        case displayOrder = "display_order"
        case isImportant = "is_important"
        case images
    }
    
    // 转换为本地DessertItem
    func toDessertItem() -> DessertItem {
        let categoryEnum = FoodCategory(rawValue: categoryName) ?? .dessert
        let imageName = name.replacingOccurrences(of: " ", with: "")
        
        // 转换图片数据
        var dessertImages: [DessertImage] = []
        for (type, url) in images {
            dessertImages.append(DessertImage(
                id: UUID().uuidString, // 使用UUID字符串作为图片ID
                url: url,
                type: type,
                displayOrder: 1
            ))
        }
        
        return DessertItem(
            id: id, // 直接使用原始id字符串
            name: name,
            imageName: imageName,
            calories: String(format: "%.0f", calories),
            category: categoryEnum,
            description: description,
            isFeatured: isImportant, // 使用isImportant值设置isFeatured
            categoryId: categoryID, // 直接使用原始categoryID字符串
            categoryName: categoryName,
            displayOrder: displayOrder,
            images: dessertImages
        )
    }
}

// MARK: - 美食详情响应
struct DessertDetailResponse: Decodable {
    let id: String
    let name: String
    let categoryID: String
    let categoryName: String
    let calories: Double
    let protein: Double?
    let fat: Double?
    let carbohydrates: Double?
    let description: String
    let servingSize: String
    let displayOrder: Int
    let isImportant: Bool
    let images: [String: String]
    let keywords: [String]?
    let createdAt: Date
    let updatedAt: Date
    let isUserDefined: Bool
    let creatorID: String?
    let creatorName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case categoryID = "category_id"
        case categoryName = "category_name"
        case calories
        case protein
        case fat
        case carbohydrates
        case description
        case servingSize = "serving_size"
        case displayOrder = "display_order"
        case isImportant = "is_important"
        case images
        case keywords
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isUserDefined = "is_user_defined"
        case creatorID = "creator_id"
        case creatorName = "creator_name"
    }
}

// MARK: - 美食搜索响应
struct DessertSearchResponse: Decodable {
    let items: [DessertSearchItem]
}

// MARK: - 美食搜索项
struct DessertSearchItem: Decodable, Identifiable {
    let id: String
    let name: String
    let categoryName: String
    let calories: Double
    let imageURL: String
    let similarity: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case categoryName = "category_name"
        case calories
        case imageURL = "image_url"
        case similarity
    }
}

// MARK: - 分类列表响应
struct CategoryListResponse: Decodable {
    let categories: [CategoryItemResponse]
}

// MARK: - 分类项响应
struct CategoryItemResponse: Decodable, Identifiable {
    let id: String
    let name: String
    let parentID: String?
    let displayOrder: Int
    let hasChildren: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case parentID = "parent_id"
        case displayOrder = "display_order"
        case hasChildren = "has_children"
    }
} 