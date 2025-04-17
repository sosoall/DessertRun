//
//  MotionTypes.swift
//  DessertRun
//
//  Created by Claude on 2023/5/25.
//

import Foundation
import Combine
import CoreMotion

/// 加速度数据结构
struct AccelerationData {
    let x: Double
    let y: Double
    let z: Double
}

/// 旋转速率数据结构
struct RotationRateData {
    let x: Double
    let y: Double
    let z: Double
}

/// 姿态数据结构
struct AttitudeData {
    let roll: Double
    let pitch: Double
    let yaw: Double
}

/// 运动数据结构
struct MotionData {
    let acceleration: AccelerationData
    let rotationRate: RotationRateData?
    let userAcceleration: AccelerationData?
    let attitude: AttitudeData?
    let timestamp: Date
    
    init(acceleration: AccelerationData, rotationRate: RotationRateData?, userAcceleration: AccelerationData?, 
         attitude: AttitudeData?, timestamp: Date) {
        self.acceleration = acceleration
        self.rotationRate = rotationRate
        self.userAcceleration = userAcceleration
        self.attitude = attitude
        self.timestamp = timestamp
    }
    
    init(from data: CMDeviceMotion) {
        self.acceleration = AccelerationData(
            x: data.gravity.x,
            y: data.gravity.y,
            z: data.gravity.z
        )
        self.rotationRate = RotationRateData(
            x: data.rotationRate.x,
            y: data.rotationRate.y,
            z: data.rotationRate.z
        )
        self.userAcceleration = AccelerationData(
            x: data.userAcceleration.x,
            y: data.userAcceleration.y,
            z: data.userAcceleration.z
        )
        self.attitude = AttitudeData(
            roll: data.attitude.roll,
            pitch: data.attitude.pitch,
            yaw: data.attitude.yaw
        )
        self.timestamp = Date()
    }
    
    init(from data: CMAccelerometerData) {
        self.acceleration = AccelerationData(
            x: data.acceleration.x,
            y: data.acceleration.y,
            z: data.acceleration.z
        )
        self.rotationRate = nil
        self.userAcceleration = nil
        self.attitude = nil
        self.timestamp = Date(timeIntervalSince1970: data.timestamp)
    }
}

/// 计步数据结构
struct PedometerData {
    let numberOfSteps: Int
    let distance: Double
    let currentPace: Double?
    let currentCadence: Double?
    let floorsAscended: Int?
    let floorsDescended: Int?
    let startDate: Date
    let endDate: Date
    
    init(numberOfSteps: Int, distance: Double, currentPace: Double?, currentCadence: Double?,
         floorsAscended: Int?, floorsDescended: Int?, startDate: Date, endDate: Date) {
        self.numberOfSteps = numberOfSteps
        self.distance = distance
        self.currentPace = currentPace
        self.currentCadence = currentCadence
        self.floorsAscended = floorsAscended
        self.floorsDescended = floorsDescended
        self.startDate = startDate
        self.endDate = endDate
    }
    
    init(from data: CMPedometerData) {
        self.numberOfSteps = data.numberOfSteps.intValue
        self.distance = data.distance?.doubleValue ?? 0
        self.currentPace = data.currentPace?.doubleValue
        self.currentCadence = data.currentCadence?.doubleValue
        self.floorsAscended = data.floorsAscended?.intValue
        self.floorsDescended = data.floorsDescended?.intValue
        self.startDate = data.startDate
        self.endDate = data.endDate
    }
}

/// 运动管理接口
protocol MotionManaging: AnyObject {
    /// 当前运动数据
    var currentMotion: MotionData? { get }
    
    /// 当前计步数据
    var currentPedometer: PedometerData? { get }
    
    /// 总步数
    var totalSteps: Int { get }
    
    /// 总距离（米）
    var totalDistance: Double { get }
    
    /// 总卡路里
    var totalCalories: Double { get }
    
    /// 是否正在跟踪
    var isTracking: Bool { get }
    
    /// 传感器是否可用
    var sensorsAvailable: Bool { get }
    
    /// 当前运动强度（0-1之间的值）
    var currentIntensity: Double { get }
    
    /// 计步器数据更新发布者
    var pedometerUpdatePublisher: PassthroughSubject<PedometerData, Never> { get }
    
    /// 开始追踪
    func startTracking()
    
    /// 暂停追踪
    func pauseTracking()
    
    /// 恢复追踪
    func resumeTracking()
    
    /// 停止追踪
    func stopTracking()
} 