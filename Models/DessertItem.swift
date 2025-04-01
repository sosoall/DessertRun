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
    case regular       // 常规风格
    case animated      // 动画风格
    case voucher       // 优惠券风格
    case celebration   // 庆祝风格
    case custom(type: String)  // 自定义风格
}

/// 美食数据模型
struct DessertItem: Identifiable, Codable {
    /// 唯一标识符
    let id: Int
    
    /// 美食名称
    let name: String
    
    /// 主图片名称（在Assets.xcassets中）
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
    
    /// 获取特定风格的图片名称
    func getImageName(for style: FoodImageStyle = .regular) -> String {
        switch style {
        case .regular:
            return imageName
        case .animated:
            return "\(imageName)_animated"
        case .voucher:
            return "\(imageName)_voucher"
        case .celebration:
            return "\(imageName)_celebration"
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
            // 蛋糕类
            DessertItem(id: 1, name: "蛋糕卷", imageName: "cake_roll", calories: "280", category: .cake, description: "松软的海绵蛋糕卷，内部填充鲜奶油，甜而不腻", backgroundColor: Color(hex: "FFD6D6")),
            DessertItem(id: 2, name: "巧克力切块", imageName: "slices_of_chocolate_cake", calories: "320", category: .cake, description: "浓郁的巧克力蛋糕，口感湿润，香甜可口", backgroundColor: Color(hex: "D6A988")),
            DessertItem(id: 3, name: "提拉米苏", imageName: "tiramisu", calories: "350", category: .cake, description: "经典意大利甜点，咖啡浸泡的手指饼干与马斯卡彭芝士的完美结合", backgroundColor: Color(hex: "D6E5FF")),
            DessertItem(id: 4, name: "红丝绒", imageName: "red_velvet", calories: "310", category: .cake, description: "红色天鹅绒般的蛋糕，搭配奶油芝士糖霜，质地细腻", backgroundColor: Color(hex: "FFCECE")),
            DessertItem(id: 5, name: "提拉米苏", imageName: "tiramisu", calories: "300", category: .cake, description: "经典意大利甜点，咖啡浸泡的手指饼干与马斯卡彭芝士的完美结合", backgroundColor: Color(hex: "E5D6C3")),
            
            // 甜点类
            DessertItem(id: 6, name: "瑞士卷", imageName: "swiss_roll", calories: "270", category: .dessert, description: "传统欧式甜点，细软的蛋糕与甜馅的完美结合", backgroundColor: Color(hex: "D8EFDC")),
            DessertItem(id: 7, name: "柠檬塔", imageName: "lemon_tart", calories: "240", category: .dessert, description: "酸甜可口的柠檬塔，脆皮与柠檬馅的完美搭配", backgroundColor: Color(hex: "FFFBD6")),
            DessertItem(id: 8, name: "焦糖布蕾", imageName: "creme_brulee", calories: "290", category: .dessert, description: "经典法式甜点，表面焦糖脆皮，内里丝滑柔软", backgroundColor: Color(hex: "F0E4D0")),
            DessertItem(id: 9, name: "树莓舒芙蕾", imageName: "raspberry_souffle", calories: "260", category: .dessert, description: "空气般轻盈的蛋奶酥，散发着浓郁的树莓香气", backgroundColor: Color(hex: "FFD6E5")),
            DessertItem(id: 10, name: "奥利奥杯", imageName: "oreo_cup", calories: "310", category: .dessert, description: "层叠的奥利奥饼干与奶油慕斯，口感丰富", backgroundColor: Color(hex: "E0E0E0")),
            
            // 冰品类
            DessertItem(id: 11, name: "芒果冰沙", imageName: "mango_smoothie", calories: "200", category: .iceCream, description: "新鲜芒果制成的冰沙，清凉爽口，酸甜可口", backgroundColor: Color(hex: "FFE8C4")),
            DessertItem(id: 12, name: "香草冰淇淋", imageName: "ice_cream", calories: "210", category: .iceCream, description: "纯正香草风味的冰淇淋，口感丝滑细腻", backgroundColor: Color(hex: "C9E6C0")),
            DessertItem(id: 13, name: "抹茶冰淇淋", imageName: "matcha_icecream", calories: "210", category: .iceCream, description: "浓郁抹茶风味的冰淇淋，微苦回甘", backgroundColor: Color(hex: "C9E6C0")),
            DessertItem(id: 14, name: "覆盆子雪糕", imageName: "raspberry_icecream", calories: "240", category: .iceCream, description: "酸甜覆盆子风味的雪糕，色泽艳丽，口感细腻", backgroundColor: Color(hex: "FFC0CB")),
            DessertItem(id: 15, name: "巧克力圣代", imageName: "chocolate_sundae", calories: "320", category: .iceCream, description: "丰盛的巧克力圣代，搭配巧克力酱，香浓可口", backgroundColor: Color(hex: "8B4513")),
            
            // 饮品类
            DessertItem(id: 16, name: "珍珠奶茶", imageName: "milk_tea", calories: "350", category: .drink, description: "香浓奶茶搭配弹牙珍珠，经典台式饮品", backgroundColor: Color(hex: "E0C9A6")),
            DessertItem(id: 17, name: "椰香拿铁", imageName: "coconut_latte", calories: "240", category: .drink, description: "浓郁咖啡与香甜椰奶的完美结合，热带风情", backgroundColor: Color(hex: "F8F8F8")),
            DessertItem(id: 18, name: "草莓气泡水", imageName: "strawberry_soda", calories: "150", category: .drink, description: "气泡水搭配新鲜草莓，酸甜爽口，低热量选择", backgroundColor: Color(hex: "FFD1DC")),
            DessertItem(id: 19, name: "蓝莓思慕雪", imageName: "blueberry_smoothie", calories: "180", category: .drink, description: "蓝莓与酸奶制成的思慕雪，营养丰富，味道浓郁", backgroundColor: Color(hex: "B0C4DE")),
            DessertItem(id: 20, name: "芒果气泡冰", imageName: "mango_bubble", calories: "190", category: .drink, description: "清爽芒果气泡冰，热带风情，消暑解渴", backgroundColor: Color(hex: "FFCC66")),
            
            // 咖啡类
            DessertItem(id: 21, name: "焦糖玛奇朵", imageName: "caramel_macchiato", calories: "250", category: .coffee, description: "香浓的意式浓缩咖啡与焦糖的完美融合", backgroundColor: Color(hex: "D2B48C"), isFeatured: true),
            DessertItem(id: 22, name: "摩卡咖啡", imageName: "mocha_coffee", calories: "230", category: .coffee, description: "咖啡与巧克力的经典组合，甜而不腻", backgroundColor: Color(hex: "8B5A2B")),
            DessertItem(id: 23, name: "香草拿铁", imageName: "vanilla_latte", calories: "210", category: .coffee, description: "细腻的泡沫拿铁，加入香草风味，温暖怡人", backgroundColor: Color(hex: "D3D3D3")),
            DessertItem(id: 24, name: "冰滴咖啡", imageName: "cold_brew", calories: "15", category: .coffee, description: "冷萃工艺制作的咖啡，风味温和，低酸低苦", backgroundColor: Color(hex: "4A3728")),
            DessertItem(id: 25, name: "榛果美式", imageName: "hazelnut_americano", calories: "80", category: .coffee, description: "清爽的美式咖啡，加入榛果风味，香气怡人", backgroundColor: Color(hex: "967259")),
            
            // 面包类
            DessertItem(id: 26, name: "肉桂面包卷", imageName: "cinnamon_roll", calories: "380", category: .bread, description: "软糯的面包卷，带有浓浓的肉桂风味，表面铺满糖霜", backgroundColor: Color(hex: "D2B48C")),
            DessertItem(id: 27, name: "芝士面包", imageName: "cheese_bread", calories: "290", category: .bread, description: "松软的面包中充满了浓郁的芝士风味，咸香可口", backgroundColor: Color(hex: "F5DEB3")),
            DessertItem(id: 28, name: "巧克力可颂", imageName: "chocolate_croissant", calories: "340", category: .bread, description: "酥脆的可颂面包，内有巧克力馅料，层次丰富", backgroundColor: Color(hex: "D2691E")),
            DessertItem(id: 29, name: "吐司", imageName: "toast", calories: "260", category: .bread, description: "金黄酥脆的吐司，简单美味的经典早餐", backgroundColor: Color(hex: "F0E68C")),
            DessertItem(id: 30, name: "抹茶红豆包", imageName: "matcha_bread", calories: "220", category: .bread, description: "抹茶风味的面包，内馅是甜甜的红豆沙，东方风味", backgroundColor: Color(hex: "90EE90")),
            
            // 包装零食
            DessertItem(id: 31, name: "鸡肉块", imageName: "chicken_nuggets", calories: "230", category: .snack, description: "外酥里嫩的鸡肉块，配上特制酱料，美味可口", backgroundColor: Color(hex: "F5F5DC")),
            DessertItem(id: 32, name: "章鱼小丸子", imageName: "octopus_balls", calories: "280", category: .snack, description: "日式小吃，外酥内软，浇上特制酱汁，风味独特", backgroundColor: Color(hex: "F4A460")),
            DessertItem(id: 33, name: "巧克力曲奇", imageName: "chocolate_cookies", calories: "260", category: .snack, description: "香脆的巧克力曲奇，满口巧克力香", backgroundColor: Color(hex: "8B4513")),
            DessertItem(id: 34, name: "奶油爆米花", imageName: "butter_popcorn", calories: "240", category: .snack, description: "奶油风味的爆米花，香气四溢，口感松脆", backgroundColor: Color(hex: "FFF8DC")),
            DessertItem(id: 35, name: "果冻糖", imageName: "jelly_beans", calories: "170", category: .snack, description: "多彩的果冻糖豆，各种水果风味，缤纷可爱", backgroundColor: Color(hex: "FFB6C1")),
            
            // 巧克力类
            DessertItem(id: 36, name: "巧克力酱", imageName: "nutella", calories: "210", category: .chocolate, description: "浓郁的巧克力榛子酱，甜蜜顺滑", backgroundColor: Color(hex: "3C2218"), isFeatured: true),
            DessertItem(id: 37, name: "榛子巧克力", imageName: "hazelnut_chocolate", calories: "270", category: .chocolate, description: "细腻的巧克力中加入了脆脆的榛子，香气浓郁", backgroundColor: Color(hex: "8B4513")),
            DessertItem(id: 38, name: "草莓松露", imageName: "strawberry_truffle", calories: "180", category: .chocolate, description: "草莓风味的巧克力松露，外层撒上可可粉，精致美味", backgroundColor: Color(hex: "FFB6C1")),
            DessertItem(id: 39, name: "薄荷巧克力", imageName: "mint_chocolate", calories: "190", category: .chocolate, description: "清新的薄荷风味巧克力，回味悠长", backgroundColor: Color(hex: "98FB98")),
            DessertItem(id: 40, name: "巧克力蜂巢", imageName: "chocolate_honeycomb", calories: "220", category: .chocolate, description: "外脆内软的蜂巢状巧克力，口感丰富有趣", backgroundColor: Color(hex: "CD853F"))
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