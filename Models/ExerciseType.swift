//
//  ExerciseType.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

/// 运动类型
enum ExerciseType: Int, Identifiable, Equatable, CaseIterable {
    case running = 1
    case walking = 2
    case cycling = 3
    case yoga = 4
    case homeWorkout = 5
    case jumpRope = 6
    case dancing = 7
    case stairClimbing = 8
    
    /// 实现Identifiable协议
    var id: Int { rawValue }
    
    /// 运动名称
    var name: String {
        switch self {
        case .running: return "慢跑"
        case .walking: return "快走"
        case .cycling: return "骑行"
        case .yoga: return "瑜伽"
        case .homeWorkout: return "家庭健身"
        case .jumpRope: return "跳绳"
        case .dancing: return "舞蹈"
        case .stairClimbing: return "爬楼梯"
        }
    }
    
    /// 用于显示的名称（兼容性）
    var displayName: String { name }
    
    /// 运动图标
    var iconName: String {
        switch self {
        case .running: return "figure.run"
        case .walking: return "figure.walk"
        case .cycling: return "figure.outdoor.cycle"
        case .yoga: return "figure.mind.and.body"
        case .homeWorkout: return "figure.strengthtraining.traditional"
        case .jumpRope: return "figure.jumprope"
        case .dancing: return "figure.dance"
        case .stairClimbing: return "figure.stairs"
        }
    }
    
    /// 运动描述
    var description: String {
        switch self {
        case .running: return "中等速度的户外或跑步机跑步，适合初学者"
        case .walking: return "快速步行，是最适合所有人的基础运动"
        case .cycling: return "户外自行车骑行或室内动感单车"
        case .yoga: return "改善柔韧性和姿势的瑜伽练习"
        case .homeWorkout: return "在家进行的基础力量训练，无需器械"
        case .jumpRope: return "高效的有氧运动，随时随地可进行"
        case .dancing: return "随音乐起舞，有趣且有效的燃脂运动"
        case .stairClimbing: return "高效的心肺训练，适合城市生活"
        }
    }
    
    /// 每分钟消耗的卡路里（基于70kg体重的平均值）
    var caloriesPerMinute: Double {
        switch self {
        case .running: return 10.5
        case .walking: return 5.0
        case .cycling: return 8.0
        case .yoga: return 3.5
        case .homeWorkout: return 7.0
        case .jumpRope: return 12.0
        case .dancing: return 7.8
        case .stairClimbing: return 8.5
        }
    }
    
    /// 运动类别
    var category: Category {
        switch self {
        case .running, .cycling, .jumpRope, .dancing, .stairClimbing: return .cardio
        case .walking: return .walking
        case .homeWorkout: return .strength
        case .yoga: return .flexibility
        }
    }
    
    /// 背景颜色
    var backgroundColor: Color {
        switch self {
        case .running: return Color(hex: "FF9901")
        case .walking: return Color(hex: "4CD964")
        case .cycling: return Color(hex: "5AC8FA")
        case .yoga: return Color(hex: "AF52DE")
        case .homeWorkout: return Color(hex: "FE2D55")
        case .jumpRope: return Color(hex: "FF9500")
        case .dancing: return Color(hex: "FF2D55")
        case .stairClimbing: return Color(hex: "34C759")
        }
    }
    
    /// 是否需要户外GPS
    var requiresGPS: Bool {
        switch self {
        case .running, .walking, .cycling: return true
        default: return false
        }
    }
    
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
    /// 获取示例运动类型数据（兼容旧代码）
    static func getSampleExerciseTypes() -> [ExerciseType] {
        return ExerciseType.allCases
    }
} 