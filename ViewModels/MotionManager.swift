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
    
    // 添加后台模式支持
    /// 进入后台模式，暂停UI更新但继续收集运动数据
    func pauseUIUpdates() {
        print("【MotionManager】暂停UI更新，但继续收集运动数据")
        
        // 这里我们仍然继续收集传感器数据，但停止更新UI
        // 可以减少更新频率以节省电池
        cmMotionManager.deviceMotionUpdateInterval = 0.5  // 降低更新频率
        
        // 标记我们处于后台模式
        isInBackgroundMode = true
    }
    
    /// 恢复前台模式，恢复UI更新
    func resumeUIUpdates() {
        print("【MotionManager】恢复UI更新和正常频率的数据收集")
        
        // 恢复正常更新频率
        cmMotionManager.deviceMotionUpdateInterval = 0.1
        
        // 标记我们不再处于后台模式
        isInBackgroundMode = false
    }
    
    // 添加一个属性来跟踪当前模式
    private var isInBackgroundMode = false
    
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
        
        // 检查传感器可用性
        if !cmMotionManager.isDeviceMotionAvailable && 
           !cmMotionManager.isAccelerometerAvailable {
            print("设备不支持运动传感器，无法获取运动数据")
            return
        }
        
        if !CMPedometer.isStepCountingAvailable() {
            print("设备不支持步数计算，将无法获取步数数据")
            // 不中断执行，因为可以继续使用其他传感器
        }
        
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
                let oldCalories = self.totalCalories
                if let distance = data.distance {
                    self.totalCalories = distance.doubleValue * 0.06
                } else {
                    // 如果没有距离数据，粗略估算
                    self.totalCalories = Double(self.totalSteps) * 0.04
                }
                
                // 添加调试信息
                let newCalories = self.totalCalories - oldCalories
                print("【调试-真实数据】步数:\(data.numberOfSteps.intValue), 距离:\(String(format: "%.2f", data.distance?.doubleValue ?? 0))米, 新增卡路里:\(String(format: "%.2f", newCalories))卡, 总计:\(String(format: "%.2f", self.totalCalories))卡")
                
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