//
//  WorkoutViewModel.swift
//  DessertRun
//
//  Created by Claude on 2025/5/19.
//

import SwiftUI
import Combine
import CoreLocation
import CoreMotion

/// 可选类型的简便判空扩展
extension Optional {
    var isNil: Bool {
        return self == nil
    }
}

/// 运动状态
enum WorkoutState: String {
    case notStarted = "未开始"
    case running = "运行中"
    case paused = "已暂停"
    case finished = "已完成"
}

/// 存储位置数据点
struct StoredLocationPoint: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let speed: Double?
    
    init(from location: LocationPoint) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.timestamp = location.timestamp
        self.speed = location.speed
    }
}

/// 运动视图模型 - 负责管理运动数据流和会话状态
class WorkoutViewModel: NSObject, ObservableObject {
    // MARK: - 公开的发布属性 (UI绑定)
    
    /// 运动会话 - 包含所有运动相关数据
    @Published var workoutSession: DessertRun.WorkoutSession
    
    /// 页面索引 (0: 动画页，1: 数据页)
    @Published var pageIndex: Int = 0
    
    /// 是否显示暂停菜单
    @Published var showPauseMenu: Bool = false
    
    /// 是否导航到完成页面
    @Published var navigateToComplete: Bool = false
    
    /// 倒计时计数
    @Published var countdownValue: Int = 3
    
    /// 是否显示倒计时
    @Published var showingCountdown: Bool = true
    
    // MARK: - 传感器与位置相关属性
    
    /// 位置管理器
    private var locationManager: CLLocationManager?
    
    /// 运动管理器
    private var motionManager: CMMotionManager?
    
    /// 步数管理器
    private var pedometer: CMPedometer?
    
    // MARK: - 内部属性
    
    /// 工作定时器
    private var workoutTimer: Timer?
    
    /// 倒计时定时器
    private var countdownTimer: Timer?
    
    /// 订阅集合
    private var cancellables = Set<AnyCancellable>()
    
    /// 应用状态引用
    private var appState: AppState
    
    // MARK: - 发布的状态
    /// 当前运动状态
    @Published var workoutState: WorkoutState = .notStarted
    
    /// 当前运动类型
    @Published var exerciseType: DessertRun.ExerciseType = .running
    
    /// 当前位置
    @Published var currentLocation: LocationPoint?
    
    /// 总距离（米）
    @Published var totalDistance: Double = 0.0
    
    /// 总时间（秒）
    @Published var totalDuration: TimeInterval = 0.0
    
    /// 总卡路里
    @Published var totalCalories: Double = 0.0
    
    /// 总步数
    @Published var totalSteps: Int = 0
    
    /// 当前配速（分钟/公里）
    @Published var currentPace: Double = 0.0
    
    /// 当前速度（公里/小时）
    @Published var currentSpeed: Double = 0.0
    
    /// 平均速度（公里/小时）
    @Published var averageSpeed: Double = 0.0
    
    /// 活动强度（0-1）
    @Published var activityIntensity: Double = 0.0
    
    /// 路线坐标
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    
    /// 是否正在跟踪
    @Published var isTracking: Bool = false
    
    /// 当前会话
    @Published var currentSession: DessertRun.WorkoutSession?
    
    /// 计时器
    private var timer: Timer?
    
    /// 开始时间
    private var startTime: Date?
    
    /// 结束时间
    private var endTime: Date?
    
    /// 暂停的持续时间（秒）
    private var pausedDuration: TimeInterval = 0
    
    /// 上次暂停时间
    private var lastPauseTime: Date?
    
    // MARK: - 初始化
    
    /// 标准初始化方法
    /// - Parameters:
    ///   - appState: 全局应用状态
    init(appState: AppState) {
        self.appState = appState
        
        // 创建运动会话
        let targetDessert = appState.selectedDessert ?? DessertData.getSampleDesserts().first!
        let exerciseType = appState.selectedExerciseType ?? DessertRun.ExerciseType.allCases.first!
        
        self.workoutSession = DessertRun.WorkoutSession(
            targetDessert: targetDessert,
            exerciseType: exerciseType
        )
        
        super.init()
        
        // 设置传感器和定时器
        setupSensors()
    }
    
    // MARK: - 生命周期方法
    
    /// 视图出现时调用
    func onAppear() {
        print("WorkoutViewModel: onAppear")
        
        // 设置应用状态
        appState.isInWorkoutMode = true
        
        // 开始倒计时
        startCountdown()
    }
    
    /// 视图消失时调用
    func onDisappear() {
        print("WorkoutViewModel: onDisappear")
        
        // 停止所有计时器和传感器
        cleanupResources()
        
        // 如果不是导航到完成页面，恢复UI状态
        if !navigateToComplete {
            print("WorkoutViewModel: 手动返回，重置UI状态")
            appState.isInWorkoutMode = false
            
            // 如果运动未完成，清理状态
            if !workoutSession.isCompleted {
                print("WorkoutViewModel: 运动已结束，执行状态清理")
                appState.finishWorkout()
            }
        }
    }
    
    // MARK: - 公开方法
    
    /// 暂停运动
    func pauseWorkout() {
        workoutSession.endTime = Date()
        
        // 暂停位置追踪
        pauseLocationUpdates()
        
        // 显示暂停菜单
        withAnimation(.easeInOut) {
            showPauseMenu = true
        }
    }
    
    /// 恢复运动
    func resumeWorkout() {
        workoutSession.endTime = nil
        
        // 恢复位置追踪
        resumeLocationUpdates()
        
        // 隐藏暂停菜单
        withAnimation(.easeInOut) {
            showPauseMenu = false
        }
    }
    
    /// 完成运动
    func completeWorkout() {
        workoutSession.endTime = Date()
        
        // 停止所有传感器
        cleanupResources()
        
        // 导航到完成页面
        navigateToComplete = true
    }
    
    // MARK: - 私有辅助方法
    
    /// 请求所有需要的传感器权限
    private func requestSensorPermissions() {
        // 请求位置权限
        if workoutSession.exerciseType.requiresGPS {
            locationManager?.requestWhenInUseAuthorization()
        }
        
        // 请求运动和健身权限 (CoreMotion不需要明确的授权对话框，但会反映在隐私设置中)
        // 使用系统API时会自动请求必要权限
        
        print("已请求所有必要的运动传感器权限")
    }
    
    /// 设置传感器和定时器
    private func setupSensors() {
        // 如果需要GPS，创建并配置位置管理器
        if workoutSession.exerciseType.requiresGPS {
            setupLocationManager()
        }
        
        // 设置运动传感器
        setupMotionManager()
        
        // 设置步数计
        setupPedometer()
    }
    
    /// 设置位置管理器
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.activityType = .fitness
        locationManager?.pausesLocationUpdatesAutomatically = false
        locationManager?.allowsBackgroundLocationUpdates = true
        
        // 请求权限
        locationManager?.requestWhenInUseAuthorization()
    }
    
    /// 设置运动管理器
    private func setupMotionManager() {
        motionManager = CMMotionManager()
        
        // 仅当设备支持时启动加速度计
        if let motionManager = motionManager, motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.5
            motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
                if let data = data {
                    // 处理加速度数据
                    self?.processAccelerometerData(data)
                }
            }
        }
    }
    
    /// 设置步数计
    private func setupPedometer() {
        pedometer = CMPedometer()
        
        // 检查步数计是否可用
        if !CMPedometer.isStepCountingAvailable() {
            print("步数计不可用")
            return
        }
    }
    
    /// 开始位置更新
    private func startLocationUpdates() {
        locationManager?.startUpdatingLocation()
    }
    
    /// 暂停位置更新
    private func pauseLocationUpdates() {
        // 不完全停止，只是暂停，保持后台会话
        locationManager?.allowsBackgroundLocationUpdates = false
    }
    
    /// 恢复位置更新
    private func resumeLocationUpdates() {
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.startUpdatingLocation()
    }
    
    /// 处理加速度计数据
    private func processAccelerometerData(_ data: CMAccelerometerData) {
        // 这里可以添加活动识别、步频计算等逻辑
        // 现阶段仅输出调试信息
        if workoutSession.endTime.isNil {
            print("加速度: x=\(data.acceleration.x), y=\(data.acceleration.y), z=\(data.acceleration.z)")
        }
    }
    
    /// 开始倒计时
    private func startCountdown() {
        // 请求所有必要的传感器权限
        requestSensorPermissions()
        
        // 确保先停止任何可能存在的定时器
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        // 创建计时器，每秒更新倒计时值
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { 
                timer.invalidate()
                return
            }
            
            if self.countdownValue > 1 {
                self.countdownValue -= 1
            } else {
                // 倒计时结束
                timer.invalidate()
                self.countdownTimer = nil
                
                // 开始运动
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.showingCountdown = false
                    
                    // 启动会话
                    self.workoutSession.endTime = Date()
                    
                    // 设置为当前活动的运动会话
                    self.appState.activeWorkoutSession = self.workoutSession
                    
                    // 开始实时数据收集
                    self.startDataCollection()
                }
            }
        }
    }
    
    /// 开始实时数据收集
    private func startDataCollection() {
        // 开始位置更新
        if workoutSession.exerciseType.requiresGPS {
            startLocationUpdates()
        }
        
        // 开始步数统计
        startPedometerUpdates()
        
        // 创建工作定时器模拟数据更新 - 稍后会替换为真实数据源
        startWorkTimer()
    }
    
    /// 开始步数统计
    private func startPedometerUpdates() {
        guard let pedometer = pedometer, CMPedometer.isStepCountingAvailable() else { return }
        
        let now = Date()
        pedometer.startUpdates(from: now) { [weak self] (data, error) in
            guard let self = self, 
                  self.workoutSession.endTime.isNil,
                  let data = data else { return }
            
            // 更新UI必须在主线程
            DispatchQueue.main.async {
                print("步数: \(data.numberOfSteps.intValue)")
                // TODO: 将步数数据整合到运动会话中
            }
        }
    }
    
    /// 开始工作定时器 - 临时模拟数据更新，后期会替换为真实数据
    private func startWorkTimer() {
        print("WorkoutViewModel: 开始数据更新定时器")
        
        // 确保先停止任何可能存在的定时器
        workoutTimer?.invalidate()
        workoutTimer = nil
        
        // 创建1秒间隔的定时器，临时模拟数据更新
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            if self.workoutSession.endTime.isNil {
                // 更新时间和卡路里
                self.workoutSession.updateWorkoutData()
                
                // 未配置GPS情况下模拟距离增加 (如果是GPS类型运动)
                if self.workoutSession.exerciseType.requiresGPS && self.locationManager == nil {
                    // 每秒增加1-3米
                    let speedMetersPerSecond = Double.random(in: 1...3)
                    self.workoutSession.totalDistance += speedMetersPerSecond
                    self.workoutSession.currentSpeed = speedMetersPerSecond
                }
                
                // 检查是否完成，如果卡路里达到目标，自动完成
                if self.workoutSession.totalCalories >= self.workoutSession.targetCalories {
                    print("WorkoutViewModel: 已达到目标卡路里，自动完成运动")
                    print("卡路里: \(self.workoutSession.totalCalories)/\(self.workoutSession.targetCalories)")
                    
                    self.workoutSession.endTime = Date()
                    
                    // 使用主线程导航到完成页面
                    DispatchQueue.main.async {
                        self.navigateToComplete = true
                    }
                    
                    timer.invalidate()
                    self.workoutTimer = nil
                }
            }
        }
    }
    
    /// 清理资源
    private func cleanupResources() {
        // 停止定时器
        workoutTimer?.invalidate()
        workoutTimer = nil
        
        countdownTimer?.invalidate()
        countdownTimer = nil
        
        // 停止位置更新
        locationManager?.stopUpdatingLocation()
        
        // 停止动作更新
        motionManager?.stopAccelerometerUpdates()
        
        // 停止步数统计
        pedometer?.stopUpdates()
        
        print("WorkoutViewModel: 资源已清理")
    }
}

// MARK: - CLLocationManagerDelegate
extension WorkoutViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard workoutSession.endTime.isNil,
              let location = locations.last else { return }
        
        // 更新位置数据
        let newSpeed = location.speed > 0 ? location.speed : 0
        workoutSession.currentSpeed = newSpeed
        
        // 更新距离 - 简单累计，后期可改进为路径计算
        if newSpeed > 0 {
            workoutSession.totalDistance += newSpeed
        }
        
        print("位置更新: 速度=\(newSpeed)m/s, 距离=\(workoutSession.totalDistance)m")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置更新错误: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        default:
            print("位置权限未授权")
        }
    }
} 