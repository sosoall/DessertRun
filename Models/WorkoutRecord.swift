import Foundation
import SwiftUI

/// 运动记录 - 记录用户打卡的运动信息
struct WorkoutRecord: Identifiable, Codable {
    /// 唯一标识符
    var id: UUID = UUID()
    
    /// 甜品信息
    let dessert: DessertItem
    
    /// 运动类型
    let exerciseType: ExerciseType
    
    /// 完成日期
    let completionDate: Date
    
    /// 运动时长（分钟）
    let duration: Double
    
    /// 运动消耗的卡路里
    let caloriesBurned: Double
    
    /// 运动截图URL
    var exerciseImageURL: String?
    
    /// 美食照片URL（可选）
    var dessertImageURL: String?
    
    /// 用户备注（可选）
    var notes: String?
    
    /// 计算属性: 格式化日期字符串
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: completionDate)
    }
    
    /// 计算属性: 格式化时长
    var formattedDuration: String {
        let hours = Int(duration) / 60
        let minutes = Int(duration) % 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    /// 初始化方法
    init(dessert: DessertItem, exerciseType: ExerciseType, completionDate: Date = Date(), duration: Double, caloriesBurned: Double) {
        self.dessert = dessert
        self.exerciseType = exerciseType
        self.completionDate = completionDate
        self.duration = duration
        self.caloriesBurned = caloriesBurned
    }
    
    // MARK: - Codable实现
    
    enum CodingKeys: String, CodingKey {
        case id, dessert, exerciseType, completionDate, duration, caloriesBurned
        case exerciseImageURL, dessertImageURL, notes
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        dessert = try container.decode(DessertItem.self, forKey: .dessert)
        
        // 解码ExerciseType (由于它是enum，需要特殊处理)
        let exerciseTypeRawValue = try container.decode(Int.self, forKey: .exerciseType)
        if let type = ExerciseType(rawValue: exerciseTypeRawValue) {
            exerciseType = type
        } else {
            exerciseType = .walking // 默认值
        }
        
        completionDate = try container.decode(Date.self, forKey: .completionDate)
        duration = try container.decode(Double.self, forKey: .duration)
        caloriesBurned = try container.decode(Double.self, forKey: .caloriesBurned)
        
        exerciseImageURL = try container.decodeIfPresent(String.self, forKey: .exerciseImageURL)
        dessertImageURL = try container.decodeIfPresent(String.self, forKey: .dessertImageURL)
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
        
        try container.encodeIfPresent(exerciseImageURL, forKey: .exerciseImageURL)
        try container.encodeIfPresent(dessertImageURL, forKey: .dessertImageURL)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
}

/// 样例数据生成器
class WorkoutRecordData {
    /// 获取样例运动记录数据
    static func getSampleRecords() -> [WorkoutRecord] {
        let desserts = DessertData.getSampleDesserts()
        
        // 创建一些样例记录
        return [
            WorkoutRecord(
                dessert: desserts[0],
                exerciseType: .running,
                completionDate: Date().addingTimeInterval(-86400),  // 昨天
                duration: 30,
                caloriesBurned: 250
            ),
            WorkoutRecord(
                dessert: desserts[1],
                exerciseType: .walking,
                completionDate: Date().addingTimeInterval(-172800),  // 前天
                duration: 45,
                caloriesBurned: 180
            ),
            WorkoutRecord(
                dessert: desserts[2],
                exerciseType: .homeWorkout,  // 将cycling更改为实际存在的运动类型
                completionDate: Date().addingTimeInterval(-259200),  // 3天前
                duration: 60,
                caloriesBurned: 350
            )
        ]
    }
} 