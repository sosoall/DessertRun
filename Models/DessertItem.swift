//
//  DessertItem.swift
//  DessertRun
//
//  Created by Claude on 2025/3/24.
//

import Foundation
import SwiftUI
import Combine
// 导入日志功能
import OSLog

/// 美食图片模型
struct DessertImage: Codable, Hashable {
    /// 图片ID
    let id: String
    
    /// 图片URL
    let url: String
    
    /// 图片类型
    let type: String
    
    /// 显示顺序
    let displayOrder: Int
}

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
struct DessertItem: Identifiable, Hashable, Codable {
    /// 唯一标识符
    let id: String
    
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
    var relatedItems: [String] = []
    
    /// 美食分类ID
    let categoryId: String
    
    /// 美食分类名称
    let categoryName: String
    
    /// 显示顺序
    let displayOrder: Int
    
    /// 美食图片
    let images: [DessertImage]
    
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
    
    // MARK: - Equatable & Hashable
    static func == (lhs: DessertItem, rhs: DessertItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.imageName == rhs.imageName &&
               lhs.calories == rhs.calories &&
               lhs.category == rhs.category &&
               lhs.description == rhs.description &&
               lhs.isFeatured == rhs.isFeatured &&
               lhs.relatedItems == rhs.relatedItems &&
               lhs.categoryId == rhs.categoryId &&
               lhs.categoryName == rhs.categoryName &&
               lhs.displayOrder == rhs.displayOrder &&
               lhs.images == rhs.images
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(imageName)
        hasher.combine(calories)
        hasher.combine(category)
        hasher.combine(description)
        hasher.combine(isFeatured)
        hasher.combine(relatedItems)
        hasher.combine(categoryId)
        hasher.combine(categoryName)
        hasher.combine(displayOrder)
        hasher.combine(images)
    }
    
    // MARK: - Codable 支持
    
    enum CodingKeys: String, CodingKey {
        case id, name, imageName, calories, description, isFeatured, relatedItems, category, categoryId, categoryName, displayOrder, images
        case backgroundColorHex
    }
    
    init(id: String, name: String, imageName: String, calories: String, category: FoodCategory = .dessert, description: String = "", backgroundColor: Color? = nil, isFeatured: Bool = false, relatedItems: [String] = [], categoryId: String, categoryName: String, displayOrder: Int, images: [DessertImage]) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.calories = calories
        self.category = category
        self.description = description
        self.backgroundColor = backgroundColor
        self.isFeatured = isFeatured
        self.relatedItems = relatedItems
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.displayOrder = displayOrder
        self.images = images
    }
    
    // 解码
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        imageName = try container.decode(String.self, forKey: .imageName)
        calories = try container.decode(String.self, forKey: .calories)
        category = try container.decodeIfPresent(FoodCategory.self, forKey: .category) ?? .dessert
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        isFeatured = try container.decodeIfPresent(Bool.self, forKey: .isFeatured) ?? false
        relatedItems = try container.decodeIfPresent([String].self, forKey: .relatedItems) ?? []
        categoryId = try container.decode(String.self, forKey: .categoryId)
        categoryName = try container.decode(String.self, forKey: .categoryName)
        displayOrder = try container.decode(Int.self, forKey: .displayOrder)
        images = try container.decode([DessertImage].self, forKey: .images)
        
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
        try container.encode(categoryId, forKey: .categoryId)
        try container.encode(categoryName, forKey: .categoryName)
        try container.encode(displayOrder, forKey: .displayOrder)
        try container.encode(images, forKey: .images)
        
        // 将颜色转换为十六进制字符串存储
        if let bgColor = backgroundColor, let uiColor = bgColor.uiColor {
            let colorHex = uiColor.toHex()
            try container.encode(colorHex, forKey: .backgroundColorHex)
        }
    }
}

/// 美食数据提供者
struct DessertData {
    /// 缓存的美食数据
    private static var cachedDesserts: [DessertItem]?
    
    // 用于保存订阅的集合
    private static var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
    
    // 用于线程安全访问订阅集合的队列
    private static let queue = DispatchQueue(label: "com.dessertrun.cancellables", attributes: .concurrent)
    
    /// 获取所有美食数据（优先从API获取，失败则使用本地数据）
    static func getAllDesserts(completion: @escaping ([DessertItem]) -> Void) {
        // 如果已有缓存，直接返回
        if let cached = cachedDesserts {
            DRDebug("使用缓存的甜品数据，共\(cached.count)项")
            completion(cached)
            return
        }
        
        // 添加日志
        DRInfo("开始从API加载甜品数据...")
        
        // 创建本地变量存储订阅
        var subscription: AnyCancellable?
        
        // 尝试从API获取
        subscription = APIService.shared.getAllDesserts()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { result in
                    switch result {
                    case .failure(let error):
                        // API获取失败，使用本地数据
                        DRError("API获取甜品数据失败: \(error)，使用本地数据")
                        completion(getSampleDesserts())
                    case .finished:
                        DRDebug("API请求甜品数据完成")
                    }
                    // 完成后清理订阅
                    subscription = nil
                },
                receiveValue: { response in
                    // 将API响应转换为DessertItem模型
                    DRInfo("收到API甜品数据响应: \(response.items.count)个甜品")
                    let desserts = response.items.map { $0.toDessertItem() }
                    cachedDesserts = desserts
                    completion(desserts)
                }
            )
        
        // 线程安全地将订阅添加到集合中
        if let sub = subscription {
            queue.async(flags: .barrier) {
                cancellables.insert(sub)
            }
        }
    }
    
    /// 获取示例美食数据（本地数据）
    static func getSampleDesserts() -> [DessertItem] {
        return [
            // 首屏显示的7个甜品
            DessertItem(id: "00000000-0000-0000-0000-000000000001", name: "芝芝云顶奶茶", imageName: "MilkTea", calories: "344", category: .drink, description: "全糖大杯奶茶，650ml", backgroundColor: Color(hex: "E0C9A6"), isFeatured: true, relatedItems: [], categoryId: "1", categoryName: "饮品", displayOrder: 1, images: [DessertImage(id: "1", url: "MilkTea_regular", type: "regular", displayOrder: 1)]),
            DessertItem(id: "00000000-0000-0000-0000-000000000002", name: "珍珠奶茶", imageName: "BubbleTea", calories: "354", category: .drink, description: "全糖大杯珍珠奶茶，650ml", backgroundColor: Color(hex: "FFFBD6"), isFeatured: true, relatedItems: [], categoryId: "1", categoryName: "饮品", displayOrder: 2, images: [DessertImage(id: "2", url: "BubbleTea_regular", type: "regular", displayOrder: 1)]),
            DessertItem(id: "00000000-0000-0000-0000-000000000003", name: "拿铁", imageName: "Latte", calories: "265", category: .drink, description: "风味拿铁，450ml", backgroundColor: Color(hex: "D2B48C"), isFeatured: true, relatedItems: [], categoryId: "1", categoryName: "饮品", displayOrder: 3, images: [DessertImage(id: "3", url: "Latte_regular", type: "regular", displayOrder: 1)]),
            DessertItem(id: "00000000-0000-0000-0000-000000000008", name: "瑞士卷", imageName: "SwissRoll", calories: "256", category: .cake, description: "瑞士卷，85克", backgroundColor: Color(hex: "D8EFDC"), isFeatured: true, relatedItems: [], categoryId: "2", categoryName: "蛋糕", displayOrder: 1, images: [DessertImage(id: "8", url: "SwissRoll_regular", type: "regular", displayOrder: 1)]),
            DessertItem(id: "00000000-0000-0000-0000-000000000009", name: "提拉米苏", imageName: "Tiramisu", calories: "318", category: .cake, description: "提拉米苏，100克", backgroundColor: Color(hex: "E5D6C3"), isFeatured: true, relatedItems: [], categoryId: "2", categoryName: "蛋糕", displayOrder: 2, images: [DessertImage(id: "9", url: "Tiramisu_regular", type: "regular", displayOrder: 1)]),
            DessertItem(id: "00000000-0000-0000-0000-000000000018", name: "甜筒", imageName: "IceCreamCone", calories: "173", category: .iceCream, description: "甜筒，60克", backgroundColor: Color(hex: "C9E6C0"), isFeatured: true, relatedItems: [], categoryId: "3", categoryName: "冰品", displayOrder: 1, images: [DessertImage(id: "18", url: "IceCreamCone_regular", type: "regular", displayOrder: 1)]),
            DessertItem(id: "00000000-0000-0000-0000-000000000021", name: "方便面", imageName: "InstantNoodles", calories: "510", category: .snack, description: "辛拉面，120克", backgroundColor: Color(hex: "F5DEB3"), isFeatured: true, relatedItems: [], categoryId: "4", categoryName: "零食", displayOrder: 1, images: [DessertImage(id: "21", url: "InstantNoodles_regular", type: "regular", displayOrder: 1)]),
            
            // 饮料类
            DessertItem(id: "00000000-0000-0000-0000-000000000005", name: "原味可乐", imageName: "CocaCola", calories: "215", category: .drink, description: "经典原味可乐，500ml", backgroundColor: Color(hex: "3C2218"), isFeatured: true, relatedItems: [], categoryId: "1", categoryName: "饮品", displayOrder: 4, images: [DessertImage(id: "5", url: "CocaCola_regular", type: "regular", displayOrder: 1)]),
            
            // 蛋糕类
            DessertItem(id: "00000000-0000-0000-0000-000000000007", name: "千层切角", imageName: "MilleCrepes", calories: "156", category: .cake, description: "千层切角蛋糕，60克", backgroundColor: Color(hex: "D6E5FF"), isFeatured: true, relatedItems: [], categoryId: "2", categoryName: "蛋糕", displayOrder: 3, images: [DessertImage(id: "7", url: "MilleCrepes_regular", type: "regular", displayOrder: 1)]),
            DessertItem(id: "00000000-0000-0000-0000-000000000010", name: "巧克力甜品", imageName: "ChocolateCake", calories: "430", category: .cake, description: "巧克力蛋糕/甜品，100克", backgroundColor: Color(hex: "FFE8C4"), isFeatured: true, relatedItems: [], categoryId: "2", categoryName: "蛋糕", displayOrder: 4, images: [DessertImage(id: "10", url: "ChocolateCake_regular", type: "regular", displayOrder: 1)]),
            DessertItem(id: "00000000-0000-0000-0000-000000000011", name: "拿破仑", imageName: "Napoleon", calories: "413", category: .cake, description: "拿破仑，90克", backgroundColor: Color(hex: "FFCECE"), isFeatured: true, relatedItems: [], categoryId: "2", categoryName: "蛋糕", displayOrder: 5, images: [DessertImage(id: "11", url: "Napoleon_regular", type: "regular", displayOrder: 1)]),
            DessertItem(id: "00000000-0000-0000-0000-000000000012", name: "奶油蛋糕", imageName: "CreamCake", calories: "312", category: .cake, description: "奶油芝士蛋糕/巴斯克，130克", backgroundColor: Color(hex: "D6E5FF"), isFeatured: true, relatedItems: [], categoryId: "2", categoryName: "蛋糕", displayOrder: 6, images: [DessertImage(id: "12", url: "CreamCake_regular", type: "regular", displayOrder: 1)]),
            DessertItem(id: "00000000-0000-0000-0000-000000000013", name: "芝士蛋糕", imageName: "CheeseCake", calories: "341", category: .cake, description: "芝士蛋糕/巴斯克，100克", backgroundColor: Color(hex: "D6E5FF"), isFeatured: true, relatedItems: [], categoryId: "2", categoryName: "蛋糕", displayOrder: 7, images: [DessertImage(id: "13", url: "CheeseCake_regular", type: "regular", displayOrder: 1)]),
            
            // 甜点类
            DessertItem(id: "00000000-0000-0000-0000-000000000014", name: "大福", imageName: "Daifuku", calories: "218", category: .dessert, description: "大福/雪媚娘，50克", backgroundColor: Color(hex: "FFCECE"), isFeatured: true, relatedItems: [], categoryId: "4", categoryName: "甜点", displayOrder: 1, images: [DessertImage(id: "14", url: "Daifuku_regular", type: "regular", displayOrder: 1)]),
            DessertItem(id: "00000000-0000-0000-0000-000000000015", name: "蛋挞", imageName: "EggTart", calories: "192", category: .dessert, description: "蛋挞，45克", backgroundColor: Color(hex: "FFE8C4"), isFeatured: true, relatedItems: [], categoryId: "4", categoryName: "甜点", displayOrder: 2, images: [DessertImage(id: "15", url: "EggTart_regular", type: "regular", displayOrder: 1)]),
            DessertItem(id: "00000000-0000-0000-0000-000000000016", name: "蛋黄酥", imageName: "EggYolkPastry", calories: "221", category: .dessert, description: "蛋黄酥/凤梨酥/肉松/月饼，50克/一块", backgroundColor: Color(hex: "FFD6E5"), isFeatured: true, relatedItems: [], categoryId: "4", categoryName: "甜点", displayOrder: 3, images: [DessertImage(id: "16", url: "EggYolkPastry_regular", type: "regular", displayOrder: 1)])
        ]
    }
    
    /// 按分类获取美食
    static func getFoodsByCategory(_ category: FoodCategory, completion: @escaping ([DessertItem]) -> Void) {
        getAllDesserts { allDesserts in
            let filtered = allDesserts.filter { $0.category == category }
            completion(filtered)
        }
    }
    
    /// 获取特色美食
    static func getFeaturedFood(completion: @escaping ([DessertItem]) -> Void) {
        getAllDesserts { allDesserts in
            let featured = allDesserts.filter { $0.isFeatured }
            completion(featured)
        }
    }
    
    /// 通过ID获取美食
    static func getFood(by id: String, completion: @escaping (DessertItem?) -> Void) {
        getAllDesserts { allDesserts in
            let food = allDesserts.first { $0.id == id }
            completion(food)
        }
    }
    
    /// 获取相关美食
    static func getRelatedFoods(for food: DessertItem, completion: @escaping ([DessertItem]) -> Void) {
        getAllDesserts { allDesserts in
            if food.relatedItems.isEmpty {
                // 如果没有指定相关美食，返回同类中随机3个
                let sameCategory = allDesserts.filter { $0.category == food.category && $0.id != food.id }
                completion(Array(sameCategory.shuffled().prefix(3)))
            } else {
                // 返回指定的相关美食
                let related = food.relatedItems.compactMap { id in
                    return allDesserts.first { $0.id == id }
                }
                completion(related)
            }
        }
    }
    
    /// 清除所有缓存数据
    static func clearCache() {
        DRInfo("[DessertData] 清除美食数据缓存")
        cachedDesserts = nil
        
        // 清除所有订阅
        queue.async(flags: .barrier) {
            cancellables.removeAll()
        }
    }
    
    /// 预加载所有美食图片
    static func preloadAllImages() {
        getAllDesserts { desserts in
            DRInfo("[DessertData] 开始预加载所有美食图片，共\(desserts.count)项")
            
            // 在后台队列中预加载
            DispatchQueue.global(qos: .utility).async {
                // 先预加载前10项重要的图片
                let featuredItems = desserts.filter { $0.isFeatured }.prefix(10)
                for item in featuredItems {
                    item.preloadAllImages()
                }
                
                // 再预加载其他项的常规图片
                let otherItems = desserts.filter { !$0.isFeatured }
                for item in otherItems {
                    item.loadImage { _ in }
                }
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

// MARK: - 图片加载扩展

extension DessertItem {
    /// 食物图片类型
    enum ImageType: String {
        case regular = "regular"      // 常规图片
        case animated = "animated"    // 动画图片
        case paused = "paused"        // 暂停状态图片
        case celebration = "celebration" // 庆祝图片
        case voucher = "voucher"      // 优惠券图片
        case icon = "icon"            // 图标
    }
    
    /// 加载指定类型的图片
    /// - Parameters:
    ///   - type: 图片类型
    ///   - completion: 完成回调，返回加载的图片
    func loadImage(type: ImageType = .regular, completion: @escaping (UIImage?) -> Void) {
        // 查找特定类型的图片URL
        if let imageObject = images.first(where: { $0.type == type.rawValue }) {
            // 如果有URL，从缓存服务获取或下载图片
            let imageUrl = imageObject.url
            if !imageUrl.isEmpty {
                DRDebug("[DessertItem] 加载图片: \(name) - \(type.rawValue), URL: \(imageUrl)")
                ImageCacheService.shared.downloadAndCacheImage(url: imageUrl) { image in
                    completion(image)
                }
                return
            }
        }
        
        // 如果没有找到URL或URL为空，使用本地图片
        let localImageName = "\(self.imageName)_\(type.rawValue)"
        DRDebug("[DessertItem] 使用本地图片: \(localImageName)")
        completion(UIImage(named: localImageName))
    }
    
    /// 预加载所有图片
    func preloadAllImages() {
        DRInfo("[DessertItem] 开始预加载图片: \(name)")
        
        for imageType in [ImageType.regular, .animated, .paused, .celebration, .voucher, .icon] {
            loadImage(type: imageType) { _ in
                // 仅加载到缓存，不做其他操作
                DRDebug("[DessertItem] 预加载完成: \(self.name) - \(imageType.rawValue)")
            }
        }
    }
} 
