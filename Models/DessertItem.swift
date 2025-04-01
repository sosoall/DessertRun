//
//  DessertItem.swift
//  DessertRun
//
//  Created by Claude on 2025/3/24.
//

import Foundation
import SwiftUI

/// 甜品数据模型
struct DessertItem: Identifiable {
    /// 唯一标识符
    let id: Int
    
    /// 甜品名称
    let name: String
    
    /// 图片名称
    let imageName: String
    
    /// 价格
    let price: String
    
    /// 卡路里
    let calories: String
    
    /// 可选的背景颜色
    var backgroundColor: Color?
}

/// 甜品数据提供者
struct DessertData {
    /// 获取示例甜品数据
    static func getSampleDesserts() -> [DessertItem] {
        return [
            DessertItem(id: 1, name: "草莓蛋糕", imageName: "strawberry_cake", price: "¥32", calories: "280", backgroundColor: Color(hex: "FFD6D6")),
            DessertItem(id: 2, name: "巧克力慕斯", imageName: "chocolate_mousse", price: "¥38", calories: "320", backgroundColor: Color(hex: "D6A988")),
            DessertItem(id: 3, name: "蓝莓芝士", imageName: "blueberry_cheese", price: "¥42", calories: "350", backgroundColor: Color(hex: "D6E5FF")),
            DessertItem(id: 4, name: "红丝绒", imageName: "red_velvet", price: "¥35", calories: "310", backgroundColor: Color(hex: "FFCECE")),
            DessertItem(id: 5, name: "提拉米苏", imageName: "tiramisu", price: "¥40", calories: "300", backgroundColor: Color(hex: "E5D6C3")),
            DessertItem(id: 6, name: "抹茶千层", imageName: "matcha_cake", price: "¥36", calories: "270", backgroundColor: Color(hex: "D8EFDC")),
            DessertItem(id: 7, name: "柠檬塔", imageName: "lemon_tart", price: "¥34", calories: "240", backgroundColor: Color(hex: "FFFBD6")),
            DessertItem(id: 8, name: "芒果冰沙", imageName: "mango_smoothie", price: "¥28", calories: "200", backgroundColor: Color(hex: "FFE8C4")),
            DessertItem(id: 9, name: "黑森林", imageName: "black_forest", price: "¥39", calories: "330", backgroundColor: Color(hex: "F1D6E0")),
            DessertItem(id: 10, name: "椰子布丁", imageName: "coconut_pudding", price: "¥25", calories: "180", backgroundColor: Color(hex: "F5F5F5")),
            DessertItem(id: 11, name: "焦糖布蕾", imageName: "creme_brulee", price: "¥37", calories: "290", backgroundColor: Color(hex: "F0E4D0")),
            DessertItem(id: 12, name: "奥利奥杯", imageName: "oreo_cup", price: "¥29", calories: "310", backgroundColor: Color(hex: "E0E0E0")),
            DessertItem(id: 13, name: "树莓舒芙蕾", imageName: "raspberry_souffle", price: "¥45", calories: "260", backgroundColor: Color(hex: "FFD6E5")),
            DessertItem(id: 14, name: "朗姆酒蛋糕", imageName: "rum_cake", price: "¥48", calories: "340", backgroundColor: Color(hex: "E5D6B9")),
            DessertItem(id: 15, name: "香草冰淇淋", imageName: "vanilla_icecream", price: "¥22", calories: "220", backgroundColor: Color(hex: "FFF8E1")),
            // 新增甜品
            DessertItem(id: 16, name: "榴莲蛋挞", imageName: "durian_tart", price: "¥42", calories: "360", backgroundColor: Color(hex: "FFFA94")),
            DessertItem(id: 17, name: "桂花糕", imageName: "osmanthus_cake", price: "¥28", calories: "220", backgroundColor: Color(hex: "FFEFC4")),
            DessertItem(id: 18, name: "抹茶冰淇淋", imageName: "matcha_icecream", price: "¥26", calories: "210", backgroundColor: Color(hex: "C9E6C0")),
            DessertItem(id: 19, name: "芋泥波波", imageName: "taro_bubble", price: "¥33", calories: "290", backgroundColor: Color(hex: "E2D1E8")),
            DessertItem(id: 20, name: "巧克力熔岩", imageName: "chocolate_lava", price: "¥46", calories: "380", backgroundColor: Color(hex: "9F6B53")),
            DessertItem(id: 21, name: "覆盆子慕斯", imageName: "raspberry_mousse", price: "¥41", calories: "310", backgroundColor: Color(hex: "FFC0CB")),
            DessertItem(id: 22, name: "黑加仑雪糕", imageName: "blackcurrant_icecream", price: "¥31", calories: "240", backgroundColor: Color(hex: "B592C9")),
            DessertItem(id: 23, name: "酸奶冻", imageName: "yogurt_jelly", price: "¥23", calories: "160", backgroundColor: Color(hex: "F2F2F2")),
            DessertItem(id: 24, name: "百香果布丁", imageName: "passionfruit_pudding", price: "¥27", calories: "190", backgroundColor: Color(hex: "FFEA99")),
            DessertItem(id: 25, name: "红豆沙冰", imageName: "red_bean_ice", price: "¥24", calories: "220", backgroundColor: Color(hex: "E8C0C0")),
            DessertItem(id: 26, name: "糯米糍", imageName: "rice_cake", price: "¥18", calories: "180", backgroundColor: Color(hex: "FFE4E1")),
            DessertItem(id: 27, name: "紫薯蛋糕", imageName: "purple_yam_cake", price: "¥37", calories: "260", backgroundColor: Color(hex: "D0C0E8")),
            DessertItem(id: 28, name: "奶黄月饼", imageName: "custard_mooncake", price: "¥45", calories: "350", backgroundColor: Color(hex: "FFE4B5")),
            DessertItem(id: 29, name: "椰汁西米露", imageName: "coconut_sago", price: "¥30", calories: "210", backgroundColor: Color(hex: "FFFAFA")),
            DessertItem(id: 30, name: "玫瑰饼干", imageName: "rose_cookies", price: "¥26", calories: "230", backgroundColor: Color(hex: "FFCCE5")),
            DessertItem(id: 31, name: "海盐焦糖", imageName: "sea_salt_caramel", price: "¥39", calories: "300", backgroundColor: Color(hex: "D4B08C")),
            DessertItem(id: 32, name: "栗子蒙布朗", imageName: "chestnut_montblanc", price: "¥48", calories: "370", backgroundColor: Color(hex: "DEB887")),
            DessertItem(id: 33, name: "绿茶曲奇", imageName: "green_tea_cookies", price: "¥32", calories: "250", backgroundColor: Color(hex: "C2D8B9")),
            DessertItem(id: 34, name: "核桃挞", imageName: "walnut_tart", price: "¥36", calories: "320", backgroundColor: Color(hex: "D8C4B1")),
            DessertItem(id: 35, name: "黄桃酸奶", imageName: "peach_yogurt", price: "¥27", calories: "180", backgroundColor: Color(hex: "FFECB3")),
            DessertItem(id: 36, name: "椰蓉球", imageName: "coconut_ball", price: "¥22", calories: "240", backgroundColor: Color(hex: "F8F8F8")),
            DessertItem(id: 37, name: "花生酥", imageName: "peanut_crisp", price: "¥25", calories: "280", backgroundColor: Color(hex: "EFD9B4")),
            DessertItem(id: 38, name: "葡萄柚冰沙", imageName: "grapefruit_smoothie", price: "¥29", calories: "170", backgroundColor: Color(hex: "FFD1D1")),
            DessertItem(id: 39, name: "南瓜派", imageName: "pumpkin_pie", price: "¥38", calories: "310", backgroundColor: Color(hex: "FFCC99")),
            DessertItem(id: 40, name: "枣泥糕", imageName: "jujube_cake", price: "¥24", calories: "220", backgroundColor: Color(hex: "D49A6A"))
        ]
    }
} 