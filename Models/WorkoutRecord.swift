//
//  WorkoutRecord.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import Foundation
import SwiftUI

/// 运动记录模型
struct WorkoutRecord: Identifiable, Equatable {
    /// 记录ID
    let id: String
    
    /// 美食
    let dessert: DessertItem
    
    /// 运动类型
    let exerciseType: ExerciseType
    
    /// 完成日期
    let date: Date
    
    /// 运动时长（分钟）
    let duration: TimeInterval?
    
    /// 消耗卡路里
    let caloriesBurned: Double
    
    /// 运动距离（米）
    let distance: Double?
    
    /// 消耗的甜品数量
    let equivalentDessertCount: Double
    
    /// 运动图片URL
    let exerciseImageURL: String?
    
    /// 美食图片URL
    let dessertImageURL: String?
    
    /// 备注
    let note: String
    
    /// 打卡标签
    let workoutTag: String
    
    /// 用户ID
    let userId: String
    
    /// 是否达成目标
    var isGoalAchieved: Bool {
        // 根据workoutTag判断是否达成目标
        return workoutTag == "运动量super!"
    }
    
    /// 用于显示的工作标签
    var displayWorkoutTag: String {
        // 直接使用原始workoutTag或根据等效甜品数量提供更友好的显示文本
        if !workoutTag.isEmpty {
            return workoutTag
        } else if equivalentDessertCount >= 1.0 {
            return "运动量super!"
        } else if equivalentDessertCount >= 0.8 {
            return "运动量不足"
        } else {
            return "继续加油"
        }
    }
    
    /// 默认初始化
    init(
        id: String,
        userId: String,
        exerciseType: ExerciseType,
        duration: TimeInterval?,
        distance: Double?,
        caloriesBurned: Double,
        dessert: DessertItem,
        date: Date,
        workoutTag: String,
        equivalentDessertCount: Double
    ) {
        self.id = id
        self.userId = userId
        self.exerciseType = exerciseType
        self.duration = duration
        self.distance = distance
        self.caloriesBurned = caloriesBurned
        self.dessert = dessert
        self.date = date
        self.workoutTag = workoutTag
        self.equivalentDessertCount = equivalentDessertCount
        self.exerciseImageURL = nil
        self.dessertImageURL = nil
        self.note = ""
    }
    
    /// 等价性检查
    static func == (lhs: WorkoutRecord, rhs: WorkoutRecord) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - 格式化属性
    
    /// 格式化的日期
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
    
    /// 格式化的时间
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    /// 格式化的运动时长
    var formattedDuration: String {
        let hours = Int(duration ?? 0) / 60
        let minutes = Int(duration ?? 0) % 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    /// 格式化的运动消耗卡路里
    var formattedCaloriesBurned: String {
        return String(format: "%.0f卡路里", caloriesBurned)
    }
    
    /// 格式化的运动距离（如果有）
    var formattedDistance: String? {
        guard let distance = distance else { return nil }
        
        if distance >= 1000 {
            return String(format: "%.2f公里", distance / 1000)
        } else {
            return String(format: "%.0f米", distance)
        }
    }
    
    // MARK: - 分享功能
    
    /// 生成分享文本
    func generateShareText() -> String {
        let goalStatus = isGoalAchieved ? "成功" : "努力"
        let emoji = isGoalAchieved ? "🎉" : "💪"
        
        var text = "今天我在DessertRun中\(goalStatus)消耗了\(formattedCaloriesBurned)，获得了\(dessert.name)的奖励！\(emoji)\n"
        
        if let distance = formattedDistance {
            text += "通过\(exerciseType.name)运动，完成了\(distance)的距离。"
        } else {
            text += "通过\(exerciseType.name)运动，坚持了\(formattedDuration)。"
        }
        
        return text
    }
}

// // MARK: - 扩展功能

// extension WorkoutRecord {
//     /// 创建测试用运动记录
//     static func createSample(date: Date = Date()) -> WorkoutRecord {
//         let dessert = DessertData.getSampleDesserts().randomElement()!
//         // 使用固定的测试运动类型
//         let exerciseType = ExerciseType(
//             type: "running",
//             name: "跑步",
//             description: "跑步是一种有氧运动，可以有效燃烧卡路里",
//             iconName: "figure.run",
//             usesDistance: true,
//             backgroundColor: "#FF6B6B",
//             caloriesPerMinPerKg: 0.1,
//             caloriesPerKmPerKg: 0.8,
//             displayOrder: 1
//         )
        
//         let caloriesBurned = Double(dessert.calories)! * Double.random(in: 0.8...1.2)
//         let isAchieved = caloriesBurned >= Double(dessert.calories)!
        
//         return WorkoutRecord(
//             id: UUID().uuidString,
//             userId: UUID().uuidString,
//             exerciseType: exerciseType,
//             duration: Double.random(in: 20...60),
//             distance: exerciseType.usesDistance ? Double.random(in: 1000...5000) : nil,
//             caloriesBurned: caloriesBurned,
//             dessert: dessert,
//             date: date,
//             workoutTag: isAchieved ? "运动量super!" : "已运动",
//             equivalentDessertCount: 1.0
//         )
//     }
// } 