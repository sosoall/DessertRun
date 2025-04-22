//
//  ExerciseType.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

/// 运动类型
enum ExerciseType: Int, Identifiable, Equatable, CaseIterable {
    case houseCleaning = 1 // 打扫卫生
    case dogWalking = 2    // 遛狗
    case walking = 3       // 散步
    case running = 4       // 跑步
    case homeWorkout = 5   // 家庭健身（无深蹲无器械）
    case hiitWorkout = 6   // 家庭健身（HIIT高效燃脂版）
    case stairClimbing = 7 // 爬楼梯
    
    /// 实现Identifiable协议
    var id: Int { rawValue }
    
    /// 运动名称
    var name: String {
        switch self {
        case .houseCleaning: return "打扫卫生"
        case .dogWalking: return "遛狗"
        case .walking: return "散步"
        case .running: return "跑步"
        case .homeWorkout: return "家庭健身（基础版）"
        case .hiitWorkout: return "家庭健身（HIIT版）"
        case .stairClimbing: return "爬楼梯"
        }
    }
    
    /// 用于显示的名称（兼容性）
    var displayName: String { name }
    
    /// 运动图标
    var iconName: String {
        switch self {
        case .houseCleaning: return "house.fill"
        case .dogWalking: return "pawprint.fill"
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .homeWorkout: return "figure.strengthtraining.traditional"
        case .hiitWorkout: return "figure.highintensity.intervaltraining"
        case .stairClimbing: return "figure.stairs"
        }
    }
    
    /// 运动描述
    var description: String {
        switch self {
        case .houseCleaning: return "日常家务活动，含拖地、擦窗等中等强度活动"
        case .dogWalking: return "与宠物一同户外散步，放松心情的同时锻炼身体"
        case .walking: return "中等速度的步行，最适合所有人的基础运动"
        case .running: return "中等速度的慢跑，适合初学者"
        case .homeWorkout: return "在家进行的基础力量训练，无需器械"
        case .hiitWorkout: return "高强度间歇训练，短时间内高效燃脂"
        case .stairClimbing: return "利用楼梯进行的有氧训练，适合城市生活"
        }
    }
    
    /// 运动的MET值（代谢当量）
    var metValue: Double {
        switch self {
        case .houseCleaning: return 3.0
        case .dogWalking: return 3.0
        case .walking: return 3.5
        case .running: return 8.0 // 对于跑步，我们用距离计算，此值仅参考
        case .homeWorkout: return 4.5
        case .hiitWorkout: return 9.0
        case .stairClimbing: return 8.0
        }
    }
    
    /// 是否使用距离而非时间表示运动量
    var usesDistance: Bool {
        return self == .running
    }
    
    /// 背景颜色
    var backgroundColor: Color {
        switch self {
        case .houseCleaning: return Color(hex: "A59FE0")
        case .dogWalking: return Color(hex: "FFA726")
        case .walking: return Color(hex: "4CD964")
        case .running: return Color(hex: "FF9901")
        case .homeWorkout: return Color(hex: "FE2D55")
        case .hiitWorkout: return Color(hex: "FF2D55")
        case .stairClimbing: return Color(hex: "34C759")
        }
    }
    
    /// 是否需要户外GPS
    var requiresGPS: Bool {
        switch self {
        case .running, .walking, .dogWalking: return true
        default: return false
        }
    }
    
    /// 每分钟消耗的卡路里数（基于MET值和标准体重70公斤计算）
    var caloriesPerMinute: Double {
        // 卡路里/分钟 = MET值 * 体重(kg) / 60
        // 使用标准体重70公斤计算
        let weight = 70.0
        return metValue * weight / 60
    }
    
    /// 计算完成运动所需的距离（仅适用于跑步）
    /// - Parameters:
    ///   - calories: 目标卡路里
    ///   - weight: 体重（公斤）
    /// - Returns: 跑步距离（公里）
    func calculateRunningDistance(calories: Double, weight: Double = 70.0) -> Double {
        // 距离（公里）= 目标热量（kcal）/ 体重（公斤）
        let distance = calories / weight
        // 保留一位小数
        return (distance * 10).rounded() / 10
    }
    
    /// 计算完成运动所需的时间
    /// - Parameters:
    ///   - calories: 目标卡路里
    ///   - weight: 体重（公斤）
    /// - Returns: 运动时间（小时）
    func calculateExerciseTime(calories: Double, weight: Double = 70.0) -> Double {
        // 时长（小时）= 热量（kcal）/（体重（公斤）* MET值）
        let hours = calories / (weight * metValue)
        // 保留一位小数
        return (hours * 10).rounded() / 10
    }
    
    /// 获取运动完成估计（距离或时间）
    /// - Parameter calories: 目标卡路里
    /// - Returns: 格式化的估计文本
    func getEstimatedCompletion(calories: Double) -> String {
        if usesDistance {
            // 跑步使用距离表示
            let distance = calculateRunningDistance(calories: calories)
            return String(format: "约%.1f公里", distance)
        } else {
            // 其他运动使用时间表示
            let hours = calculateExerciseTime(calories: calories)
            if hours < 1.0 {
                // 不足1小时，用分钟表示
                let minutes = Int(hours * 60)
                return "约\(minutes)分钟"
            } else if hours.truncatingRemainder(dividingBy: 1) == 0 {
                // 整数小时
                return "约\(Int(hours))小时"
            } else {
                // 小时和分钟
                let wholeHours = Int(hours)
                let minutes = Int((hours - Double(wholeHours)) * 60)
                return "约\(wholeHours)小时\(minutes)分钟"
            }
        }
    }
}

/// 运动类型数据提供
struct ExerciseTypeData {
    /// 获取示例运动类型数据（兼容旧代码）
    static func getSampleExerciseTypes() -> [ExerciseType] {
        return ExerciseType.allCases
    }
} 