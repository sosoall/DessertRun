//
//  WorkoutSession.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import Foundation
import CoreLocation

/// 运动会话状态
enum WorkoutSessionState {
    case notStarted   // 未开始
    case active       // 进行中
    case paused       // 暂停
    case completed    // 已完成
    case abandoned    // 已放弃
}

/// 运动会话
class WorkoutSession: ObservableObject, Identifiable {
    /// 唯一标识
    let id: UUID
    
    /// 关联的甜品
    let targetDessert: DessertItem
    
    /// 运动类型
    let exerciseType: ExerciseType
    
    /// 目标卡路里
    let targetCalories: Double
    
    /// 开始时间
    let startTime: Date
    
    /// 结束时间
    @Published var endTime: Date?
    
    /// 会话状态
    @Published var state: WorkoutSessionState
    
    /// 累计运动时间（秒）
    @Published var totalElapsedSeconds: Int = 0
    
    /// 累计暂停时间（秒）
    @Published var totalPausedSeconds: Int = 0
    
    /// 燃烧的卡路里
    @Published var burnedCalories: Double = 0
    
    /// 移动距离（米）
    @Published var distanceInMeters: Double = 0
    
    /// 当前速度（米/秒）
    @Published var currentSpeed: Double = 0
    
    /// 平均速度（米/秒）
    @Published var averageSpeed: Double = 0
    
    /// 位置记录
    @Published var locationHistory: [CLLocation] = []
    
    /// 暂停时间戳记录
    private var pauseTimeStamps: [Date] = []
    
    /// 恢复时间戳记录
    private var resumeTimeStamps: [Date] = []
    
    /// 上次更新时间
    private var lastUpdateTime: Date
    
    /// 初始化
    init(targetDessert: DessertItem, exerciseType: ExerciseType) {
        self.id = UUID()
        self.targetDessert = targetDessert
        self.exerciseType = exerciseType
        self.targetCalories = Double(targetDessert.calories.replacingOccurrences(of: "kcal", with: "")) ?? 0
        self.startTime = Date()
        self.lastUpdateTime = Date()
        self.state = .notStarted
    }
    
    /// 启动运动会话
    func start() {
        state = .active
        lastUpdateTime = Date()
    }
    
    /// 暂停运动会话
    func pause() {
        guard state == .active else { return }
        
        state = .paused
        pauseTimeStamps.append(Date())
    }
    
    /// 恢复运动会话
    func resume() {
        guard state == .paused else { return }
        
        state = .active
        resumeTimeStamps.append(Date())
        lastUpdateTime = Date()
    }
    
    /// 完成运动会话
    func complete() {
        state = .completed
        endTime = Date()
        
        // 计算最终数据
        calculateFinalStats()
    }
    
    /// 放弃运动会话
    func abandon() {
        state = .abandoned
        endTime = Date()
        
        // 计算最终数据
        calculateFinalStats()
    }
    
    /// 计算完成百分比
    var completionPercentage: Double {
        guard targetCalories > 0 else { return 0 }
        return min(burnedCalories / targetCalories, 1.0) * 100
    }
    
    /// 计算总运动时间（格式化）
    var formattedTotalTime: String {
        let hours = totalElapsedSeconds / 3600
        let minutes = (totalElapsedSeconds % 3600) / 60
        let seconds = totalElapsedSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// 添加新的位置数据
    func addLocation(_ location: CLLocation) {
        locationHistory.append(location)
        
        // 如果有上一个位置，计算距离和速度
        if let lastLocation = locationHistory.dropLast().last {
            let distance = location.distance(from: lastLocation)
            distanceInMeters += distance
            
            // 计算时间差（秒）
            let timeDifference = location.timestamp.timeIntervalSince(lastLocation.timestamp)
            if timeDifference > 0 {
                currentSpeed = distance / timeDifference
                
                // 更新平均速度
                if distanceInMeters > 0 && totalElapsedSeconds > 0 {
                    averageSpeed = distanceInMeters / Double(totalElapsedSeconds)
                }
            }
        }
    }
    
    /// 更新运动时间和卡路里
    func updateTimeAndCalories() {
        guard state == .active else { return }
        
        // 计算时间差
        let now = Date()
        let timeDiff = Int(now.timeIntervalSince(lastUpdateTime))
        
        // 更新总时间
        totalElapsedSeconds += timeDiff
        
        // 更新卡路里
        let minutesElapsed = Double(timeDiff) / 60.0
        burnedCalories += minutesElapsed * exerciseType.caloriesPerMinute
        
        // 更新最后更新时间
        lastUpdateTime = now
    }
    
    /// 计算最终统计数据
    private func calculateFinalStats() {
        // 计算总暂停时间
        if pauseTimeStamps.count == resumeTimeStamps.count {
            for i in 0..<pauseTimeStamps.count {
                totalPausedSeconds += Int(resumeTimeStamps[i].timeIntervalSince(pauseTimeStamps[i]))
            }
        } else if pauseTimeStamps.count > resumeTimeStamps.count {
            // 如果最后一次暂停没有恢复，使用结束时间
            for i in 0..<resumeTimeStamps.count {
                totalPausedSeconds += Int(resumeTimeStamps[i].timeIntervalSince(pauseTimeStamps[i]))
            }
            
            if let endTime = endTime {
                totalPausedSeconds += Int(endTime.timeIntervalSince(pauseTimeStamps.last!))
            }
        }
        
        // 计算最终平均速度
        if distanceInMeters > 0 && totalElapsedSeconds > 0 {
            averageSpeed = distanceInMeters / Double(totalElapsedSeconds)
        }
    }
} 