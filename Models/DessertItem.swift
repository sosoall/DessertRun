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
            DessertItem(id: 15, name: "香草冰淇淋", imageName: "vanilla_icecream", price: "¥22", calories: "220", backgroundColor: Color(hex: "FFF8E1"))
        ]
    }
} 