//
//  ExerciseType.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

/// 运动类型
struct ExerciseType: Identifiable, Equatable {
    /// 唯一标识
    let id: Int
    
    /// 运动名称
    let name: String
    
    /// 运动图标
    let iconName: String
    
    /// 运动描述
    let description: String
    
    /// 每分钟消耗的卡路里（基于70kg体重的平均值）
    let caloriesPerMinute: Double
    
    /// 运动类别
    let category: Category
    
    /// 背景颜色
    let backgroundColor: Color
    
    /// 是否需要户外GPS
    let requiresGPS: Bool
    
    /// 预计完成时间（分钟）
    func estimatedTimeToComplete(calories: Double) -> Double {
        return calories / caloriesPerMinute
    }
    
    /// 运动类别
    enum Category: String, CaseIterable {
        case cardio = "有氧运动"
        case strength = "力量训练"
        case flexibility = "柔韧性训练"
        case walking = "步行"
        case other = "其他"
    }
}

/// 运动类型数据提供
struct ExerciseTypeData {
    /// 获取示例运动类型数据
    static func getSampleExerciseTypes() -> [ExerciseType] {
        return [
            ExerciseType(
                id: 1,
                name: "慢跑",
                iconName: "figure.run",
                description: "中等速度的户外或跑步机跑步，适合初学者",
                caloriesPerMinute: 10.5,
                category: .cardio,
                backgroundColor: Color(hex: "FF9901"),
                requiresGPS: true
            ),
            ExerciseType(
                id: 2,
                name: "快走",
                iconName: "figure.walk",
                description: "快速步行，是最适合所有人的基础运动",
                caloriesPerMinute: 5.0,
                category: .walking,
                backgroundColor: Color(hex: "4CD964"),
                requiresGPS: true
            ),
            ExerciseType(
                id: 3,
                name: "骑行",
                iconName: "figure.outdoor.cycle",
                description: "户外自行车骑行或室内动感单车",
                caloriesPerMinute: 8.0,
                category: .cardio,
                backgroundColor: Color(hex: "5AC8FA"),
                requiresGPS: true
            ),
            ExerciseType(
                id: 4,
                name: "瑜伽",
                iconName: "figure.mind.and.body",
                description: "改善柔韧性和姿势的瑜伽练习",
                caloriesPerMinute: 3.5,
                category: .flexibility,
                backgroundColor: Color(hex: "AF52DE"),
                requiresGPS: false
            ),
            ExerciseType(
                id: 5,
                name: "家庭健身",
                iconName: "figure.strengthtraining.traditional",
                description: "在家进行的基础力量训练，无需器械",
                caloriesPerMinute: 7.0,
                category: .strength,
                backgroundColor: Color(hex: "FE2D55"),
                requiresGPS: false
            ),
            ExerciseType(
                id: 6,
                name: "跳绳",
                iconName: "figure.jumprope",
                description: "高效的有氧运动，随时随地可进行",
                caloriesPerMinute: 12.0,
                category: .cardio,
                backgroundColor: Color(hex: "FF9500"),
                requiresGPS: false
            ),
            ExerciseType(
                id: 7,
                name: "舞蹈",
                iconName: "figure.dance",
                description: "随音乐起舞，有趣且有效的燃脂运动",
                caloriesPerMinute: 7.8,
                category: .cardio,
                backgroundColor: Color(hex: "FF2D55"),
                requiresGPS: false
            ),
            ExerciseType(
                id: 8,
                name: "爬楼梯",
                iconName: "figure.stairs",
                description: "高效的心肺训练，适合城市生活",
                caloriesPerMinute: 8.5,
                category: .cardio,
                backgroundColor: Color(hex: "34C759"),
                requiresGPS: false
            )
        ]
    }
} 