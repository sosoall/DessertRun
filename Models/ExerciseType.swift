import SwiftUI

// 导入APIModels中定义的APIExerciseType
// ExerciseType.swift仅保留类型别名定义

// 兼容原有代码的类型别名，降低对现有代码的影响
typealias ExerciseType = APIExerciseType 

// 扩展APIExerciseType添加fromString静态方法
extension APIExerciseType {
    /// 根据类型字符串创建运动类型
    static func fromString(_ typeStr: String) -> APIExerciseType {
        // 提供一组预定义的运动类型
        switch typeStr {
        case "running":
            return APIExerciseType(
                type: "running",
                name: "跑步",
                description: "跑步是一种有氧运动，可以有效燃烧卡路里",
                iconName: "figure.run",
                usesDistance: true,
                backgroundColor: "#FF6B6B",
                caloriesPerMinPerKg: 0.1,
                caloriesPerKmPerKg: 0.8,
                displayOrder: 1
            )
        case "walking":
            return APIExerciseType(
                type: "walking",
                name: "步行",
                description: "步行是一种低强度有氧运动，适合所有人群",
                iconName: "figure.walk",
                usesDistance: true,
                backgroundColor: "#4ECDC4",
                caloriesPerMinPerKg: 0.05,
                caloriesPerKmPerKg: 0.5,
                displayOrder: 2
            )
        case "cycling":
            return APIExerciseType(
                type: "cycling",
                name: "骑行",
                description: "骑行是一种有效的全身性有氧运动",
                iconName: "figure.outdoor.cycle",
                usesDistance: true,
                backgroundColor: "#FF9F1C",
                caloriesPerMinPerKg: 0.08,
                caloriesPerKmPerKg: 0.3,
                displayOrder: 3
            )
        case "swimming":
            return APIExerciseType(
                type: "swimming",
                name: "游泳",
                description: "游泳是一种全身性运动，对关节冲击小",
                iconName: "figure.pool.swim",
                usesDistance: false,
                backgroundColor: "#2EC4B6",
                caloriesPerMinPerKg: 0.12,
                caloriesPerKmPerKg: 0,
                displayOrder: 4
            )
        case "yoga":
            return APIExerciseType(
                type: "yoga",
                name: "瑜伽",
                description: "瑜伽可以提高身体柔韧性和平衡能力",
                iconName: "figure.mind.and.body",
                usesDistance: false,
                backgroundColor: "#A57EDD",
                caloriesPerMinPerKg: 0.05,
                caloriesPerKmPerKg: 0,
                displayOrder: 5
            )
        default:
            // 默认返回跑步类型
            return APIExerciseType(
                type: typeStr,
                name: "其他运动",
                description: "自定义运动类型",
                iconName: "figure.strengthtraining.traditional",
                usesDistance: false,
                backgroundColor: "#888888",
                caloriesPerMinPerKg: 0.07,
                caloriesPerKmPerKg: 0,
                displayOrder: 99
            )
        }
    }
} 