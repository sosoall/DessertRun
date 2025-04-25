//
//  DessertItem.swift
//  DessertRun
//
//  Created by Claude on 2025/3/24.
//

import Foundation
import SwiftUI

/// 美食分类
enum FoodCategory: String, Codable, CaseIterable {
    case cake = "蛋糕"
    case dessert = "甜点"
    case iceCream = "冰品"
    case drink = "饮品"
    case coffee = "咖啡"
    case bread = "面包"
    case snack = "零食"
    case chocolate = "巧克力"
    
    var icon: String {
        switch self {
        case .cake: return "birthday.cake"
        case .dessert: return "cup.and.saucer"
        case .iceCream: return "snowflake"
        case .drink: return "mug"
        case .coffee: return "cup.and.saucer.fill"
        case .bread: return "staroflife"
        case .snack: return "gift"
        case .chocolate: return "rectangle.fill.on.rectangle.fill"
        }
    }
}

/// 美食图片风格
enum FoodImageStyle {
    case regular       // 常规风格 (气泡UI)
    case animated      // 动画风格 (运动中激励页)
    case paused        // 暂停风格 (运动暂停页)
    case celebration   // 庆祝风格 (运动结束页)
    case voucher       // 优惠券风格
    case custom(type: String)  // 自定义风格
}

/// 美食数据模型
struct DessertItem: Identifiable, Codable {
    /// 唯一标识符
    let id: Int
    
    /// 美食名称
    let name: String
    
    /// 主图片名称（基础名称，不包含后缀）
    let imageName: String
    
    /// 美食分类
    var category: FoodCategory = .dessert
    
    /// 卡路里
    let calories: String
    
    /// 美食描述
    var description: String = ""
    
    /// 是否特色美食
    var isFeatured: Bool = false
    
    /// 可选的背景颜色
    var backgroundColor: Color?
    
    /// 相关食品（如配对饮品/甜点）
    var relatedItems: [Int] = []
    
    // MARK: - 扩展功能方法
    
    /// 获取基本图片名称（不带目录）
    func getImageName() -> String {
        return imageName
    }
    
    /// 获取完整图片名称（包含目录）
    func getFullImageName(for style: FoodImageStyle = .regular) -> String {
        switch style {
        case .regular:
            return "\(imageName)_regular"
        case .animated:
            return "\(imageName)_animated"
        case .paused:
            return "\(imageName)_paused"
        case .celebration:
            return "\(imageName)_celebration"
        case .voucher:
            return "\(imageName)_voucher"
        case .custom(let type):
            return "\(imageName)_\(type)"
        }
    }
    
    /// 获取美食基本信息字符串
    var infoString: String {
        return "\(name) - \(calories) 卡路里"
    }
    
    /// 生成分享卡片文本
    func generateShareText() -> String {
        return "我在DessertRun运动后获得了\(name)奖励！一共消耗了\(calories)卡路里！"
    }
    
    // MARK: - Codable 支持
    
    enum CodingKeys: String, CodingKey {
        case id, name, imageName, calories, description, isFeatured, relatedItems, category
        case backgroundColorHex
    }
    
    init(id: Int, name: String, imageName: String, calories: String, category: FoodCategory = .dessert, description: String = "", backgroundColor: Color? = nil, isFeatured: Bool = false, relatedItems: [Int] = []) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.calories = calories
        self.category = category
        self.description = description
        self.backgroundColor = backgroundColor
        self.isFeatured = isFeatured
        self.relatedItems = relatedItems
    }
    
    // 解码
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        imageName = try container.decode(String.self, forKey: .imageName)
        calories = try container.decode(String.self, forKey: .calories)
        category = try container.decodeIfPresent(FoodCategory.self, forKey: .category) ?? .dessert
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured) ?? false
        relatedItems = try container.decodeIfPresent([Int].self, forKey: .relatedItems) ?? []
        
        if let colorHex = try container.decodeIfPresent(String.self, forKey: .backgroundColorHex) {
            backgroundColor = Color(hex: colorHex)
        } else {
            backgroundColor = nil
        }
    }
    
    // 编码
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(imageName, forKey: .imageName)
        try container.encode(calories, forKey: .calories)
        try container.encode(category, forKey: .category)
        try container.encode(description, forKey: .description)
        try container.encode(isFeatured, forKey: .isFeatured)
        try container.encode(relatedItems, forKey: .relatedItems)
        
        // 将颜色转换为十六进制字符串存储
        if let bgColor = backgroundColor, let uiColor = bgColor.uiColor {
            let colorHex = uiColor.toHex()
            try container.encode(colorHex, forKey: .backgroundColorHex)
        }
    }
}

/// 美食数据提供者
struct DessertData {
    /// 获取示例美食数据
    static func getSampleDesserts() -> [DessertItem] {
        return [
            // 首屏显示的7个甜品
            DessertItem(id: 1, name: "芝芝云顶奶茶", imageName: "MilkTea", calories: "344", category: .drink, description: "全糖大杯奶茶，650ml", backgroundColor: Color(hex: "E0C9A6")),
            DessertItem(id: 2, name: "珍珠奶茶", imageName: "BubbleTea", calories: "354", category: .drink, description: "全糖大杯珍珠奶茶，650ml", backgroundColor: Color(hex: "FFFBD6")),
            DessertItem(id: 3, name: "拿铁", imageName: "Latte", calories: "265", category: .drink, description: "风味拿铁，450ml", backgroundColor: Color(hex: "D2B48C")),
            DessertItem(id: 8, name: "瑞士卷", imageName: "SwissRoll", calories: "256", category: .cake, description: "瑞士卷，85克", backgroundColor: Color(hex: "D8EFDC")),
            DessertItem(id: 9, name: "提拉米苏", imageName: "Tiramisu", calories: "318", category: .cake, description: "提拉米苏，100克", backgroundColor: Color(hex: "E5D6C3")),
            DessertItem(id: 18, name: "甜筒", imageName: "IceCreamCone", calories: "173", category: .iceCream, description: "甜筒，60克", backgroundColor: Color(hex: "C9E6C0")),
            DessertItem(id: 21, name: "方便面", imageName: "InstantNoodles", calories: "510", category: .snack, description: "辛拉面，120克", backgroundColor: Color(hex: "F5DEB3")),
            
            // 饮料类
            DessertItem(id: 5, name: "原味可乐", imageName: "CocaCola", calories: "215", category: .drink, description: "经典原味可乐，500ml", backgroundColor: Color(hex: "3C2218")),
            
            // 蛋糕类
            DessertItem(id: 7, name: "千层切角", imageName: "MilleCrepes", calories: "156", category: .cake, description: "千层切角蛋糕，60克", backgroundColor: Color(hex: "D6E5FF")),
            DessertItem(id: 10, name: "巧克力甜品", imageName: "ChocolateCake", calories: "430", category: .cake, description: "巧克力蛋糕/甜品，100克", backgroundColor: Color(hex: "FFE8C4")),
            DessertItem(id: 11, name: "拿破仑", imageName: "Napoleon", calories: "413", category: .cake, description: "拿破仑，90克", backgroundColor: Color(hex: "FFCECE")),
            DessertItem(id: 12, name: "奶油蛋糕", imageName: "CreamCake", calories: "312", category: .cake, description: "奶油芝士蛋糕/巴斯克，130克", backgroundColor: Color(hex: "D6E5FF")),
            DessertItem(id: 13, name: "芝士蛋糕", imageName: "CheeseCake", calories: "341", category: .cake, description: "芝士蛋糕/巴斯克，100克", backgroundColor: Color(hex: "D6E5FF")),
            
            // 甜点类
            DessertItem(id: 14, name: "大福", imageName: "Daifuku", calories: "218", category: .dessert, description: "大福/雪媚娘，50克", backgroundColor: Color(hex: "FFCECE")),
            DessertItem(id: 15, name: "蛋挞", imageName: "EggTart", calories: "192", category: .dessert, description: "蛋挞，45克", backgroundColor: Color(hex: "FFE8C4")),
            DessertItem(id: 16, name: "蛋黄酥", imageName: "EggYolkPastry", calories: "221", category: .dessert, description: "蛋黄酥/凤梨酥/肉松/月饼，50克/一块", backgroundColor: Color(hex: "FFD6E5")),
            
            // 冰淇淋类
            DessertItem(id: 17, name: "圣代", imageName: "Sundae", calories: "394", category: .iceCream, description: "圣代，120克", backgroundColor: Color(hex: "8B4513")),
            
            // 零食类
            DessertItem(id: 6, name: "面包", imageName: "Bread", calories: "358", category: .bread, description: "奶酪/芝士/风味糖浆面包，100克", backgroundColor: Color(hex: "F5DEB3")),
            DessertItem(id: 19, name: "好丽友派", imageName: "OrionPie", calories: "104", category: .snack, description: "蛋黄派/巧克力派，23克/一块", backgroundColor: Color(hex: "FFB6C1")),
            DessertItem(id: 20, name: "薯片", imageName: "PotatoChips", calories: "400", category: .snack, description: "乐事薯片，75克", backgroundColor: Color(hex: "FFF8DC"))
        ]
    }
    
    /// 按分类获取美食
    static func getFoodsByCategory(_ category: FoodCategory) -> [DessertItem] {
        return getSampleDesserts().filter { $0.category == category }
    }
    
    /// 获取特色美食
    static func getFeaturedFood() -> [DessertItem] {
        return getSampleDesserts().filter { $0.isFeatured }
    }
    
    /// 通过ID获取美食
    static func getFood(by id: Int) -> DessertItem? {
        return getSampleDesserts().first { $0.id == id }
    }
    
    /// 获取相关美食
    static func getRelatedFoods(for food: DessertItem) -> [DessertItem] {
        if food.relatedItems.isEmpty {
            // 如果没有指定相关美食，返回同类中随机3个
            let sameCategory = getSampleDesserts().filter { $0.category == food.category && $0.id != food.id }
            return Array(sameCategory.shuffled().prefix(3))
        } else {
            // 返回指定的相关美食
            return food.relatedItems.compactMap { id in
                return getFood(by: id)
            }
        }
    }
}

// MARK: - 扩展支持

extension Color {
    var uiColor: UIColor? {
        if #available(iOS 14.0, *) {
            return UIColor(self)
        } else {
            // iOS 14以下版本的回退方案
            let scanner = Scanner(string: "")
            var rgbValue: UInt64 = 0
            scanner.scanHexInt64(&rgbValue)
            
            let r = (rgbValue & 0xff0000) >> 16
            let g = (rgbValue & 0xff00) >> 8
            let b = rgbValue & 0xff
            
            return UIColor(
                red: CGFloat(r) / 0xff,
                green: CGFloat(g) / 0xff,
                blue: CGFloat(b) / 0xff,
                alpha: 1
            )
        }
    }
}

extension UIColor {
    func toHex() -> String {
        guard let components = cgColor.components, components.count >= 3 else {
            return "000000"
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "%02lX%02lX%02lX",
                      lroundf(r * 255),
                      lroundf(g * 255),
                      lroundf(b * 255))
    }
} 
