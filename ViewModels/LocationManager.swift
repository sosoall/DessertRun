//
//  LocationManager.swift
//  DessertRun
//
//  Created by Claude on 2025/5/19.
//

import Foundation
import CoreLocation
import Combine

/// 位置数据结构
struct LocationPoint {
    /// 坐标位置
    let coordinate: CLLocationCoordinate2D
    
    /// 速度 (米/秒)
    let speed: Double
    
    /// 方向 (度)
    let course: Double
    
    /// 海拔高度 (米)
    let altitude: Double
    
    /// 位置精度 (米)
    let horizontalAccuracy: Double
    
    /// 高度精度 (米)
    let verticalAccuracy: Double
    
    /// 时间戳
    let timestamp: Date
    
    /// 创建位置数据
    /// - Parameter location: Core Location位置对象
    init(from location: CLLocation) {
        self.coordinate = location.coordinate
        self.speed = max(0, location.speed) // 确保速度不为负
        self.course = location.course
        self.altitude = location.altitude
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy
        self.timestamp = location.timestamp
    }
}

/// 位置管理器公共接口
protocol LocationManaging: ObservableObject {
    /// 当前位置
    var currentLocation: LocationPoint? { get }
    
    /// 位置历史记录
    var locationHistory: [LocationPoint] { get }
    
    /// 总距离（米）
    var totalDistance: Double { get }
    
    /// 是否正在追踪
    var isTracking: Bool { get }
    
    /// 授权状态
    var authorizationStatus: CLAuthorizationStatus { get }
    
    /// 请求授权
    func requestAuthorization()
    
    /// 开始追踪
    func startTracking()
    
    /// 暂停追踪
    func pauseTracking()
    
    /// 恢复追踪
    func resumeTracking()
    
    /// 停止追踪
    func stopTracking()
}

/// 位置管理器 - 负责GPS位置数据采集
class LocationManager: NSObject, ObservableObject, LocationManaging {
    /// 位置管理器
    private let manager = CLLocationManager()
    
    /// 当前位置发布者
    @Published var currentLocation: LocationPoint?
    
    /// 位置更新时的回调发布者
    let locationUpdatePublisher = PassthroughSubject<LocationPoint, Never>()
    
    /// 总距离（米）
    @Published var totalDistance: Double = 0
    
    /// 位置记录
    @Published private(set) var locationHistory: [LocationPoint] = []
    
    /// 是否正在追踪
    @Published private(set) var isTracking: Bool = false
    
    /// 上一次有效位置
    private var lastValidLocation: CLLocation?
    
    /// 是否初始化完成
    private(set) var isInitialized: Bool = false
    
    /// 初始化位置管理器
    override init() {
        super.init()
        setupLocationManager()
        isInitialized = true
    }
    
    /// 设置位置管理器
    private func setupLocationManager() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5 // 只在移动5米以上时更新位置
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = false
        
        // 只有在Info.plist中配置了后台模式才启用此项
        if Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") != nil {
            let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String]
            if backgroundModes?.contains("location") == true {
                manager.allowsBackgroundLocationUpdates = true
            }
        }
    }
    
    /// 请求位置权限
    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    /// 开始位置更新
    func startTracking() {
        // 重置数据
        locationHistory.removeAll()
        totalDistance = 0
        lastValidLocation = nil
        
        // 启动位置更新
        manager.startUpdatingLocation()
        isTracking = true
        
        print("位置跟踪已启动")
    }
    
    /// 暂停位置更新
    func pauseTracking() {
        isTracking = false
        print("位置跟踪已暂停")
    }
    
    /// 恢复位置更新
    func resumeTracking() {
        manager.startUpdatingLocation()
        isTracking = true
        print("位置跟踪已恢复")
    }
    
    /// 停止位置更新
    func stopTracking() {
        manager.stopUpdatingLocation()
        isTracking = false
        print("位置跟踪已停止")
    }
    
    /// 处理新位置
    private func handleNewLocation(_ location: CLLocation) {
        // 创建位置数据
        let locationData = LocationPoint(from: location)
        
        // 更新当前位置
        currentLocation = locationData
        
        // 添加到历史记录
        locationHistory.append(locationData)
        
        // 如果有上一个有效位置，计算新增距离
        if let lastLocation = lastValidLocation {
            let newDistance = location.distance(from: lastLocation)
            
            // 过滤不合理的距离增量（例如瞬间跳跃或GPS漂移）
            if newDistance < 100 { // 限制单次距离增量不超过100米
                totalDistance += newDistance
            } else {
                print("过滤异常距离增量: \(newDistance)米")
            }
        }
        
        // 更新上一个有效位置
        lastValidLocation = location
        
        // 发布位置更新事件
        locationUpdatePublisher.send(locationData)
    }
    
    /// 获取位置权限状态
    var authorizationStatus: CLAuthorizationStatus {
        return manager.authorizationStatus
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking, let location = locations.last, location.horizontalAccuracy >= 0 else { return }
        
        // 过滤掉精度太低的位置（比如精度>50米可能是不准确的）
        if location.horizontalAccuracy <= 50 {
            handleNewLocation(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置更新错误: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("位置权限已授权")
        case .denied, .restricted:
            print("位置权限被拒绝或受限")
        case .notDetermined:
            print("位置权限未确定")
        @unknown default:
            print("位置权限状态未知")
        }
    }
} 