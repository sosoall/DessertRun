//
//  MockMotionManager.swift
//  DessertRun
//
//  Created by Claude on 2023/5/25.
//

import Foundation
import Combine
import CoreMotion
import SwiftUI

/// 模拟运动管理器，用于不支持运动传感器的设备
class MockMotionManager: ObservableObject, MotionManaging {
    // MARK: - 公开属性
    @Published private(set) var currentMotion: MotionData?
    @Published private(set) var currentPedometer: PedometerData?
    @Published private(set) var totalSteps: Int = 0
    @Published private(set) var totalDistance: Double = 0
    @Published private(set) var totalCalories: Double = 0
    @Published var isTracking: Bool = false
    
    // 返回固定值，表示传感器总是"可用"（实际上是模拟的）
    var sensorsAvailable: Bool { return true }
    
    // 当前运动强度（0-1之间的值）
    var currentIntensity: Double {
        return intensityValue
    }
    
    // MARK: - 私有属性
    private var timer: Timer?
    private var startDate: Date?
    private var lastUpdate: Date?
    private var intensityValue: Double = 0.5
    private var activityLevel: ActivityLevel = .moderate
    private var stepsPerSecond: Double = 1.5 // 默认每秒1.5步的速度
    private var distancePerStep: Double = 0.7 // 默认每步0.7米
    private var caloriesPerMinute: Double = 5.0 // 默认每分钟5卡路里
    
    /// 计步器数据更新发布者
    let pedometerUpdatePublisher = PassthroughSubject<PedometerData, Never>()
    
    // 运动活动等级
    enum ActivityLevel {
        case light
        case moderate
        case intense
        
        var stepsPerSecond: Double {
            switch self {
            case .light: return 1.0 // 每秒1步，慢走
            case .moderate: return 1.5 // 每秒1.5步，快走
            case .intense: return 2.5 // 每秒2.5步，慢跑
            }
        }
        
        var distancePerStep: Double {
            switch self {
            case .light: return 0.6 // 每步0.6米
            case .moderate: return 0.7 // 每步0.7米
            case .intense: return 0.8 // 每步0.8米
            }
        }
        
        var caloriesPerMinute: Double {
            switch self {
            case .light: return 3.0 // 每分钟3卡路里
            case .moderate: return 5.0 // 每分钟5卡路里
            case .intense: return 10.0 // 每分钟10卡路里
            }
        }
        
        var intensity: Double {
            switch self {
            case .light: return 0.3
            case .moderate: return 0.6
            case .intense: return 0.9
            }
        }
    }
    
    // MARK: - 初始化
    init() {
        print("已初始化模拟运动管理器")
    }
    
    // MARK: - 公开方法
    func startTracking() {
        guard !isTracking else { return }
        
        // 设置初始值
        startDate = Date()
        lastUpdate = Date()
        totalSteps = 0
        totalDistance = 0
        totalCalories = 0
        
        // 随机选择一个活动级别
        activityLevel = [.light, .moderate, .intense].randomElement() ?? .moderate
        stepsPerSecond = activityLevel.stepsPerSecond
        distancePerStep = activityLevel.distancePerStep
        caloriesPerMinute = activityLevel.caloriesPerMinute
        intensityValue = activityLevel.intensity
        
        // 创建并发布初始运动数据
        updateMockMotionData()
        updateMockPedometerData()
        
        // 设置定时器进行数据更新
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSimulatedData()
        }
        
        isTracking = true
        print("模拟运动追踪已开始 - 活动级别: \(activityLevel)")
    }
    
    func pauseTracking() {
        // 停止定时器
        timer?.invalidate()
        timer = nil
        
        print("模拟运动追踪已暂停")
    }
    
    func resumeTracking() {
        guard isTracking else { return }
        
        // 更新最后更新时间
        lastUpdate = Date()
        
        // 重新启动定时器
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSimulatedData()
        }
        
        print("模拟运动追踪已恢复")
    }
    
    func stopTracking() {
        // 停止定时器
        timer?.invalidate()
        timer = nil
        
        // 重置状态
        isTracking = false
        
        print("模拟运动追踪已停止")
    }
    
    // MARK: - 私有方法
    private func updateSimulatedData() {
        guard let lastUpdate = lastUpdate else { return }
        
        // 计算上次更新到现在的时间
        let now = Date()
        let elapsedTime = now.timeIntervalSince(lastUpdate)
        
        // 根据活动级别计算新的步数
        let newSteps = Int(stepsPerSecond * elapsedTime)
        totalSteps += newSteps
        
        // 计算新的距离
        let newDistance = Double(newSteps) * distancePerStep
        totalDistance += newDistance
        
        // 计算新的卡路里
        let newCalories = (caloriesPerMinute / 60) * elapsedTime
        totalCalories += newCalories
        
        // 添加调试信息
        print("【调试-模拟数据】活动级别:\(activityLevel), 步数:\(newSteps), 距离:\(String(format: "%.2f", newDistance))米, 卡路里:\(String(format: "%.2f", newCalories))卡, 总计:\(String(format: "%.2f", totalCalories))卡")
        
        // 更新最后更新时间
        self.lastUpdate = now
        
        // 更新并发布模拟数据
        updateMockMotionData()
        updateMockPedometerData()
    }
    
    private func updateMockMotionData() {
        // 为模拟运动添加一些随机波动
        let randomVariation = Double.random(in: -0.1...0.1)
        
        // 创建模拟的加速度数据
        let acceleration = AccelerationData(
            x: Double.random(in: -0.1...0.1),
            y: Double.random(in: 0.9...1.1),
            z: Double.random(in: -0.1...0.1)
        )
        
        // 创建模拟的旋转率数据
        let rotationRate = RotationRateData(
            x: Double.random(in: -0.5...0.5) * intensityValue,
            y: Double.random(in: -0.5...0.5) * intensityValue,
            z: Double.random(in: -0.5...0.5) * intensityValue
        )
        
        // 创建模拟的用户加速度数据
        let userAcceleration = AccelerationData(
            x: Double.random(in: -0.2...0.2) * intensityValue,
            y: Double.random(in: -0.3...0.3) * intensityValue,
            z: Double.random(in: -0.2...0.2) * intensityValue
        )
        
        // 创建模拟的姿态数据
        let attitude = AttitudeData(
            roll: Double.random(in: -0.1...0.1),
            pitch: Double.random(in: -0.1...0.1),
            yaw: Double.random(in: -0.1...0.1)
        )
        
        // 创建模拟的运动数据
        let mockMotionData = MotionData(
            acceleration: acceleration,
            rotationRate: rotationRate,
            userAcceleration: userAcceleration,
            attitude: attitude,
            timestamp: Date()
        )
        
        // 更新当前运动数据
        currentMotion = mockMotionData
        
        // 稍微改变强度以模拟真实场景
        intensityValue += randomVariation
        intensityValue = min(max(intensityValue, 0.2), 0.95)
    }
    
    private func updateMockPedometerData() {
        guard let start = startDate else { return }
        
        // 创建模拟的计步器数据
        let mockPedometerData = PedometerData(
            numberOfSteps: totalSteps,
            distance: totalDistance,
            currentPace: isTracking ? 60.0 / stepsPerSecond : 0.0,
            currentCadence: isTracking ? stepsPerSecond / 2.0 : 0.0,
            floorsAscended: Int.random(in: 0...2),
            floorsDescended: Int.random(in: 0...2),
            startDate: start,
            endDate: Date()
        )
        
        // 更新当前计步器数据
        currentPedometer = mockPedometerData
        
        // 发布计步器数据更新
        pedometerUpdatePublisher.send(mockPedometerData)
    }
    
    // 添加后台模式支持
    /// 进入后台模式，暂停UI更新但继续收集运动数据
    func pauseUIUpdates() {
        print("【MockMotionManager】暂停UI更新，但继续模拟数据")
        
        // 降低模拟数据更新频率以节省电池
        // 暂停任何现有的定时器
        timer?.invalidate()
        
        // 创建更低频率的定时器（每3秒）
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.updateSimulatedData()
        }
        
        // 标记我们处于后台模式
        isInBackgroundMode = true
    }
    
    /// 恢复前台模式，恢复UI更新
    func resumeUIUpdates() {
        print("【MockMotionManager】恢复UI更新和正常频率的模拟数据")
        
        // 恢复正常更新频率
        // 暂停低频率的定时器
        timer?.invalidate()
        
        // 重新创建正常频率的定时器（每秒）
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSimulatedData()
        }
        
        // 标记我们不再处于后台模式
        isInBackgroundMode = false
    }
    
    // 添加一个属性来跟踪当前模式
    private var isInBackgroundMode = false
} 