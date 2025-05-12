import SwiftUI

// 导入APIModels中定义的APIExerciseType
// ExerciseType.swift仅保留类型别名定义

// 兼容原有代码的类型别名，降低对现有代码的影响
typealias ExerciseType = APIExerciseType 

// 扩展APIExerciseType添加fromString静态方法
extension APIExerciseType {
    /// 根据类型字符串创建运动类型
    static func fromString(_ typeStr: String, name: String? = nil) -> APIExerciseType {
        // 直接使用后端提供的名称，没有提供时才使用默认值
        return APIExerciseType(
            type: typeStr,
            name: name ?? typeStr, // 优先使用后端提供的name，没有时直接使用typeStr
            description: "运动类型",
            iconName: getIconName(for: typeStr),
            usesDistance: isDistanceBasedExercise(typeStr),
            backgroundColor: getBackgroundColor(for: typeStr),
            caloriesPerMinPerKg: getCaloriesPerMinute(for: typeStr),
            caloriesPerKmPerKg: getCaloriesPerKm(for: typeStr),
            displayOrder: getDisplayOrder(for: typeStr)
        )
    }
    
    // 获取图标名称
    private static func getIconName(for type: String) -> String {
        switch type.lowercased() {
        case "running": return "figure.run"
        case "walking": return "figure.walk"
        case "cycling": return "figure.outdoor.cycle" 
        case "swimming": return "figure.pool.swim"
        case "yoga": return "figure.mind.and.body"
        default: return "figure.strengthtraining.traditional"
        }
    }
    
    // 判断是否基于距离的运动
    private static func isDistanceBasedExercise(_ type: String) -> Bool {
        let distanceTypes = ["running", "walking", "cycling", "hiking"]
        return distanceTypes.contains(type.lowercased())
    }
    
    // 获取背景颜色
    private static func getBackgroundColor(for type: String) -> String {
        switch type.lowercased() {
        case "running": return "#FF6B6B"
        case "walking": return "#4ECDC4"
        case "cycling": return "#FF9F1C"
        case "swimming": return "#2EC4B6"
        case "yoga": return "#A57EDD"
        default: return "#888888"
        }
    }
    
    // 获取每分钟每公斤消耗的卡路里
    private static func getCaloriesPerMinute(for type: String) -> Double {
        switch type.lowercased() {
        case "running": return 0.1
        case "walking": return 0.05
        case "cycling": return 0.08
        case "swimming": return 0.12
        case "yoga": return 0.05
        default: return 0.07
        }
    }
    
    // 获取每公里每公斤消耗的卡路里
    private static func getCaloriesPerKm(for type: String) -> Double {
        switch type.lowercased() {
        case "running": return 0.8
        case "walking": return 0.5
        case "cycling": return 0.3
        default: return 0.0
        }
    }
    
    // 获取显示顺序
    private static func getDisplayOrder(for type: String) -> Int {
        switch type.lowercased() {
        case "running": return 1
        case "walking": return 2
        case "cycling": return 3
        case "swimming": return 4
        case "yoga": return 5
        default: return 99
        }
    }
} 