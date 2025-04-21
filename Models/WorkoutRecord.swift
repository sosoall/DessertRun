//
//  WorkoutRecord.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import Foundation
import SwiftUI

/// 运动记录模型
struct WorkoutRecord: Identifiable, Codable {
    /// 唯一标识符
    let id: UUID
    
    /// 相关甜品
    let dessert: DessertItem
    
    /// 运动类型
    let exerciseType: ExerciseType
    
    /// 完成日期
    let completionDate: Date
    
    /// 运动时长（分钟）
    let duration: Double
    
    /// 实际消耗卡路里
    let caloriesBurned: Double
    
    /// 运动距离（米），仅用于跑步等类型
    var distance: Double?
    
    /// 运动截图URL
    var exerciseImageURL: URL?
    
    /// 甜品照片URL
    var dessertImageURL: URL?
    
    /// 备注
    var notes: String?
    
    /// 是否完成目标
    var isGoalAchieved: Bool {
        // 目标卡路里
        let targetCalories = Double(dessert.calories) ?? 0
        // 消耗卡路里是否达到或超过目标
        return caloriesBurned >= targetCalories
    }
    
    /// 消耗卡路里与目标的比例
    var progressRatio: Double {
        let targetCalories = Double(dessert.calories) ?? 1 // 避免除以0
        return min(caloriesBurned / targetCalories, 1.0)
    }
    
    /// 初始化方法
    init(id: UUID = UUID(), dessert: DessertItem, exerciseType: ExerciseType, completionDate: Date, duration: Double, caloriesBurned: Double, distance: Double? = nil, exerciseImageURL: URL? = nil, dessertImageURL: URL? = nil, notes: String? = nil) {
        self.id = id
        self.dessert = dessert
        self.exerciseType = exerciseType
        self.completionDate = completionDate
        self.duration = duration
        self.caloriesBurned = caloriesBurned
        self.distance = distance
        self.exerciseImageURL = exerciseImageURL
        self.dessertImageURL = dessertImageURL
        self.notes = notes
    }
    
    // MARK: - 格式化属性
    
    /// 格式化的日期
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: completionDate)
    }
    
    /// 格式化的时间
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: completionDate)
    }
    
    /// 格式化的运动时长
    var formattedDuration: String {
        let hours = Int(duration) / 60
        let minutes = Int(duration) % 60
        
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
    
    // MARK: - Codable支持
    
    enum CodingKeys: String, CodingKey {
        case id, dessert, exerciseType, completionDate, duration, caloriesBurned, distance
        case exerciseImageURL, dessertImageURL, notes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        dessert = try container.decode(DessertItem.self, forKey: .dessert)
        // 解码ExerciseType(需要特殊处理，因为它是枚举)
        let exerciseTypeRawValue = try container.decode(Int.self, forKey: .exerciseType)
        guard let decodedExerciseType = ExerciseType(rawValue: exerciseTypeRawValue) else {
            throw DecodingError.dataCorruptedError(forKey: .exerciseType, in: container, debugDescription: "无效的运动类型")
        }
        exerciseType = decodedExerciseType
        completionDate = try container.decode(Date.self, forKey: .completionDate)
        duration = try container.decode(Double.self, forKey: .duration)
        caloriesBurned = try container.decode(Double.self, forKey: .caloriesBurned)
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)
        exerciseImageURL = try container.decodeIfPresent(URL.self, forKey: .exerciseImageURL)
        dessertImageURL = try container.decodeIfPresent(URL.self, forKey: .dessertImageURL)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(dessert, forKey: .dessert)
        try container.encode(exerciseType.rawValue, forKey: .exerciseType)
        try container.encode(completionDate, forKey: .completionDate)
        try container.encode(duration, forKey: .duration)
        try container.encode(caloriesBurned, forKey: .caloriesBurned)
        try container.encodeIfPresent(distance, forKey: .distance)
        try container.encodeIfPresent(exerciseImageURL, forKey: .exerciseImageURL)
        try container.encodeIfPresent(dessertImageURL, forKey: .dessertImageURL)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
}

// MARK: - 扩展功能

extension WorkoutRecord {
    /// 创建测试用运动记录
    static func createSample(date: Date = Date()) -> WorkoutRecord {
        let dessert = DessertData.getSampleDesserts().randomElement()!
        let exerciseType = ExerciseType.allCases.randomElement()!
        
        return WorkoutRecord(
            dessert: dessert,
            exerciseType: exerciseType,
            completionDate: date,
            duration: Double.random(in: 20...60),
            caloriesBurned: Double(dessert.calories)! * Double.random(in: 0.8...1.2),
            distance: exerciseType.usesDistance ? Double.random(in: 1000...5000) : nil,
            notes: Bool.random() ? "这是一条测试备注" : nil
        )
    }
} 