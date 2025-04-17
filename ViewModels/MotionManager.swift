//
//  MotionManager.swift
//  DessertRun
//
//  Created by Claude on 2024/4/17.
//

import Foundation
import CoreMotion
import Combine

/// 真实运动数据管理器，使用CoreMotion API获取设备运动数据
class MotionManager: NSObject, ObservableObject, MotionManaging {
    // MARK: - 公开属性
    @Published private(set) var currentMotion: MotionData?
    @Published private(set) var currentPedometer: PedometerData?
    @Published private(set) var totalSteps: Int = 0
    @Published private(set) var totalDistance: Double = 0
    @Published private(set) var totalCalories: Double = 0
    @Published var isTracking: Bool = false
    
    var currentIntensity: Double {
        // 根据当前运动数据计算运动强度（0-1）
        guard let motion = currentMotion, let userAccel = motion.userAcceleration, let rotRate = motion.rotationRate else { return 0.5 }
        
        // 计算加速度矢量的大小
        let accelMagnitude = sqrt(
            pow(userAccel.x, 2) +
            pow(userAccel.y, 2) +
            pow(userAccel.z, 2)
        )
        
        // 根据旋转率计算角速度
        let rotationMagnitude = sqrt(
            pow(rotRate.x, 2) +
            pow(rotRate.y, 2) +
            pow(rotRate.z, 2)
        )
        
        // 结合加速度和旋转率计算强度
        let rawIntensity = (accelMagnitude * 5.0 + rotationMagnitude) / 2.0
        
        // 将原始强度映射到0-1范围，并限制在0.2-0.95之间
        return min(max(rawIntensity, 0.2), 0.95)
    }
    
    var sensorsAvailable: Bool {
        return CMMotionManager().isDeviceMotionAvailable && CMPedometer.isPedometerEventTrackingAvailable()
    }
    
    // MARK: - 私有属性
    private let cmMotionManager = CMMotionManager()
    private let pedometer = CMPedometer()
    private var startDate: Date?
    private var timer: Timer?
    
    let pedometerUpdatePublisher = PassthroughSubject<PedometerData, Never>()
    
    // MARK: - 初始化
    override init() {
        super.init()
        
        // 配置CoreMotion
        cmMotionManager.deviceMotionUpdateInterval = 0.1
        cmMotionManager.accelerometerUpdateInterval = 0.1
        cmMotionManager.gyroUpdateInterval = 0.1
    }
    
    // MARK: - 公开方法
    func startTracking() {
        guard !isTracking else { return }
        
        // 设置开始日期
        startDate = Date()
        
        // 重置累计数据
        totalSteps = 0
        totalDistance = 0
        totalCalories = 0
        
        // 开始设备运动更新
        startMotionUpdates()
        
        // 开始计步器更新
        startPedometerUpdates()
        
        // 设置为跟踪状态
        isTracking = true
        
        print("运动数据追踪已开始")
    }
    
    func pauseTracking() {
        guard isTracking else { return }
        
        // 保持跟踪状态，但停止更新
        stopMotionUpdates()
        
        print("运动数据追踪已暂停")
    }
    
    func resumeTracking() {
        guard isTracking else { return }
        
        // 重新开始更新，但保持累计的数据
        startMotionUpdates()
        
        print("运动数据追踪已恢复")
    }
    
    func stopTracking() {
        guard isTracking else { return }
        
        // 停止所有更新
        stopMotionUpdates()
        
        // 停止计步器更新
        pedometer.stopUpdates()
        
        // 设置为非跟踪状态
        isTracking = false
        
        print("运动数据追踪已停止")
    }
    
    // MARK: - 私有方法
    private func startMotionUpdates() {
        // 开始设备运动更新
        if cmMotionManager.isDeviceMotionAvailable {
            cmMotionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
                guard let self = self, let motion = motion, error == nil else { return }
                
                // 转换并发布运动数据
                let motionData = self.convertToMotionData(motion)
                self.currentMotion = motionData
            }
        } else if cmMotionManager.isAccelerometerAvailable {
            // 如果设备运动不可用，退回到加速度计
            cmMotionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
                guard let self = self, let data = data, error == nil else { return }
                
                // 使用加速度计数据创建简化的运动数据
                let accelData = AccelerationData(x: data.acceleration.x, y: data.acceleration.y, z: data.acceleration.z)
                let motionData = MotionData(
                    acceleration: accelData,
                    rotationRate: nil,
                    userAcceleration: nil,
                    attitude: nil,
                    timestamp: Date()
                )
                self.currentMotion = motionData
            }
        }
    }
    
    private func startPedometerUpdates() {
        guard let start = startDate, CMPedometer.isStepCountingAvailable() else {
            print("计步功能不可用")
            return
        }
        
        // 开始计步器更新
        pedometer.startUpdates(from: start) { [weak self] (data, error) in
            guard let self = self, let data = data, error == nil else {
                print("计步器错误: \(error?.localizedDescription ?? "未知错误")")
                return
            }
            
            // 在主线程更新UI相关的属性
            DispatchQueue.main.async {
                // 更新步数
                self.totalSteps = data.numberOfSteps.intValue
                
                // 更新距离
                if let distance = data.distance {
                    self.totalDistance = distance.doubleValue
                }
                
                // 更新卡路里（基于步数和距离的估算）
                // 平均1公里消耗约60卡路里
                if let distance = data.distance {
                    self.totalCalories = distance.doubleValue * 0.06
                } else {
                    // 如果没有距离数据，粗略估算
                    self.totalCalories = Double(self.totalSteps) * 0.04
                }
                
                // 创建并发布计步器数据更新
                let pedometerData = self.convertToPedometerData(data)
                self.currentPedometer = pedometerData
                self.pedometerUpdatePublisher.send(pedometerData)
            }
        }
    }
    
    private func stopMotionUpdates() {
        cmMotionManager.stopDeviceMotionUpdates()
        cmMotionManager.stopAccelerometerUpdates()
        cmMotionManager.stopGyroUpdates()
    }
    
    // MARK: - 数据转换方法
    private func convertToMotionData(_ motion: CMDeviceMotion) -> MotionData {
        return MotionData(from: motion)
    }
    
    private func convertToPedometerData(_ data: CMPedometerData) -> PedometerData {
        return PedometerData(from: data)
    }
} 