//
//  DataView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI
import MapKit

/// 运动数据页面
struct DataView: View {
    /// 运动会话
    @ObservedObject var workoutSession: WorkoutSession
    
    /// 屏幕尺寸
    let screenSize: CGSize
    
    /// 主色调
    private let primaryColor = Color(hex: "FE2D55")
    private let secondaryColor = Color(hex: "FF9901")
    
    /// 动画控制
    @State private var isAnimating = false
    @State private var isBreathing = false
    @State private var pulseScale = 1.0
    @State private var pauseOpacity = 0.0  // 用于暂停状态的淡入效果
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    
    /// 应用是否在前台
    @State private var isAppActive: Bool = true
    
    /// 地图区域
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9087, longitude: 116.3975),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    /// 拖动偏移量
    @State private var dragOffset: CGFloat = 0
    
    /// 资源加载状态
    @State private var resourcesLoaded = false
    
    // 在状态变量区域添加位置相关状态
    @State private var userLocation: CLLocationCoordinate2D? = nil
    @State private var locationAccuracy: CLLocationAccuracy = 0
    @State private var lastLocationUpdate = Date()
    
    // 根据完成百分比确定要显示的粒子数量
    private var particleCount: Int {
        return Int(workoutSession.completionPercentage / 3) + 5 // 至少5个粒子
    }
    
    // 判断是否显示地图（户外运动）
    private var shouldShowMap: Bool {
        return workoutSession.exerciseType.requiresGPS
    }
    
    var body: some View {
        ZStack {
            // 背景 - 确保是纯白色
            Color.white.edgesIgnoringSafeArea(.all)
            
            if shouldShowMap {
                // 户外运动布局 - 全屏地图布局，数据卡悬浮在地图上
                ZStack {
                    // 地图填充整个屏幕
                    mapContent
                        .ignoresSafeArea()
                        .overlay(mapOverlay)
                        // 添加手势限制，仅允许地图区域的手势
                        .gesture(
                            DragGesture(minimumDistance: 5)
                                .onChanged { _ in
                                    // 仅允许地图内部的拖动，不处理外部手势
                                }
                        )
                        .allowsHitTesting(true)
                    
                    // 悬浮的数据卡片 - 4个核心数据
                    VStack {
                        Spacer()
                        
                        // 四个核心数据卡片悬浮在底部
                        HStack(spacing: 10) {
                            // 时间
                            FloatingDataCard(
                                icon: "clock.fill",
                                iconColor: primaryColor,
                                value: formattedTime,
                                label: "总时间"
                            )
                            
                            // 卡路里
                            FloatingDataCard(
                                icon: "flame.fill",
                                iconColor: secondaryColor,
                                value: "\(Int(workoutSession.burnedCalories))",
                                label: "卡路里"
                            )
                            
                            // 总里程
                            FloatingDataCard(
                                icon: "map.fill",
                                iconColor: Color(hex: "4CD964"),
                                value: String(format: "%.2f", workoutSession.distanceInMeters / 1000),
                                label: "总里程(km)"
                            )
                            
                            // 配速
                            FloatingDataCard(
                                icon: "speedometer",
                                iconColor: Color(hex: "FF3B30"),
                                value: paceString,
                                label: "配速"
                            )
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, 20)
                    }
                    
                    // 左右边缘滑动区域，用于TabView页面切换
                    HStack(spacing: 0) {
                        // 左边缘区域 - 检测右滑（返回上一页）
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 60)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 20)
                                    .onChanged { value in
                                        self.dragOffset = value.translation.width
                                    }
                                    .onEnded { value in
                                        if value.translation.width > 80 {
                                            // 向右滑动超过阈值，切换到激励页面(index 0)
                                            withAnimation {
                                                NotificationCenter.default.post(
                                                    name: NSNotification.Name("ChangePageIndex"),
                                                    object: nil,
                                                    userInfo: ["index": 0]
                                                )
                                            }
                                        }
                                        self.dragOffset = 0
                                    }
                            )
                        
                        Spacer()
                        
                        // 右边缘区域 - 为完整性添加，检测左滑
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 60)
                            .contentShape(Rectangle())
                    }
                    .frame(maxHeight: .infinity)
                    .allowsHitTesting(true)
                    
                    // 暂停状态标识 - 仅在暂停时显示
                    if workoutSession.state == .paused {
                        pauseIndicator
                    }
                }
            } else {
                // 室内运动 - 保持原来的居中大进度环和数据布局
                VStack(spacing: 15) {
                    // 增加顶部安全区域边距
                    Spacer(minLength: 40)
                    
                    // 进度环
                    progressRingView
                        .frame(height: screenSize.height * 0.3)
                        .padding(.bottom, 10)
                    
                    // 核心数据卡片
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 12) {
                        // 时间
                        CoreDataCard(
                            icon: "clock.fill",
                            iconColor: primaryColor,
                            value: formattedTime,
                            label: "总时间",
                            isAnimating: isAnimating
                        )
                        
                        // 卡路里
                        CoreDataCard(
                            icon: "flame.fill",
                            iconColor: secondaryColor,
                            value: "\(Int(workoutSession.burnedCalories))",
                            label: "卡路里消耗",
                            isAnimating: isAnimating
                        )
                        
                        // 距离/次数
                        CoreDataCard(
                            icon: "repeat",
                            iconColor: Color(hex: "4CD964"),
                            value: distanceOrCount,
                            label: distanceOrCountLabel,
                            isAnimating: isAnimating
                        )
                        
                        // 目标
                        CoreDataCard(
                            icon: "flag.fill",
                            iconColor: Color(hex: "5AC8FA"),
                            value: "\(Int(workoutSession.targetCalories))",
                            label: "目标卡路里",
                            isAnimating: isAnimating
                        )
                    }
                    .padding(.horizontal, 15)
                    
                    Spacer()
                    
                    // 为暂停按钮留出安全区域
                    Spacer()
                        .frame(height: 90)
                }
                .padding(.vertical)
            }
        }
        .onAppear {
            isAnimating = true
            isBreathing = true
            
            // 为脉冲动画设置连续变化
            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
            
            // 如果有位置数据，更新地图区域
            updateMapRegion()
            
            // 设置通知监听器
            setupNotificationObservers()
            
            // 处理资源加载问题
            setupMapResources()
            
            // 设置实时位置更新监听
            setupLocationTracking()
        }
        .onDisappear {
            // 移除通知监听器
            removeNotificationObservers()
        }
        .onChange(of: workoutSession.locationHistory) { oldValue, newValue in
            // 当位置历史更新时，更新地图区域
            if isAppActive && workoutSession.exerciseType.requiresGPS {
                updateMapRegion()
            }
        }
    }
    
    // MARK: - 进度环视图
    private var progressRingView: some View {
        ZStack {
            // 粒子效果 - 仅在活动状态显示
            if workoutSession.state == .active {
                ForEach(0..<particleCount, id: \.self) { i in
                    Circle()
                        .fill(
                            [primaryColor, secondaryColor, Color.orange, Color.yellow].randomElement()!.opacity(0.7)
                        )
                        .frame(width: CGFloat.random(in: 5...12), height: CGFloat.random(in: 5...12))
                        .offset(
                            x: CGFloat.random(in: -80...80),
                            y: CGFloat.random(in: -80...80)
                        )
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .opacity(isAnimating ? 0.8 : 0.0)
                        .animation(
                            Animation.spring(response: 0.5, dampingFraction: 0.5)
                                .repeatForever(autoreverses: true)
                                .speed(Double.random(in: 0.1...0.5))
                                .delay(Double.random(in: 0...2)),
                            value: isAnimating
                        )
                }
            }
            
            // 外围呼吸效果环 - 仅在活动状态显示和动画
            if workoutSession.state == .active {
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [primaryColor.opacity(0.2), secondaryColor.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 6
                    )
                    .scaleEffect(isBreathing ? 1.08 : 0.98)
                    .animation(
                        Animation.easeInOut(duration: 3)
                            .repeatForever(autoreverses: true),
                        value: isBreathing
                    )
            } else {
                // 暂停状态下显示固定大小的环
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [primaryColor.opacity(0.2), secondaryColor.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 6
                    )
                    .scaleEffect(0.98)
            }
            
            // 完整环形背景
            Circle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 12)
            
            // 进度环
            Circle()
                .trim(from: 0, to: CGFloat(workoutSession.completionPercentage / 100.0))
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [primaryColor, secondaryColor]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(Angle(degrees: -90))
                .animation(workoutSession.state == .active && isAppActive ? .easeInOut(duration: 1.0) : .none, value: workoutSession.completionPercentage)
            
            // 暂停状态标识 - 仅在暂停时显示
            if workoutSession.state == .paused {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "pause.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
                .opacity(pauseOpacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 0.3)) {
                        pauseOpacity = 1.0
                    }
                }
            } else {
                // 中心显示进度百分比 - 仅在非暂停状态下显示
                VStack(spacing: 2) {
                    HStack(spacing: 0) {
                        Text("\(Int(workoutSession.completionPercentage))")
                            .font(shouldShowMap ? .system(size: 24, weight: .bold) : .system(size: 44, weight: .bold))
                            .foregroundColor(primaryColor)
                            .scaleEffect(isBreathing && workoutSession.state == .active ? 1.05 : 1.0)
                            .animation(
                                workoutSession.state == .active ? 
                                Animation.easeInOut(duration: 2).repeatForever(autoreverses: true) : .none,
                                value: isBreathing
                            )
                        
                        Text("%")
                            .font(shouldShowMap ? .system(size: 14, weight: .bold) : .system(size: 18, weight: .bold))
                            .foregroundColor(primaryColor)
                            .offset(y: shouldShowMap ? -5 : -8)
                    }
                    
                    if !shouldShowMap {
                        Text("\(Int(workoutSession.burnedCalories))/\(Int(workoutSession.targetCalories)) 卡")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // 动态脉冲效果 - 仅在活动状态显示
            if workoutSession.state == .active {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(
                            primaryColor.opacity(0.3 - Double(i) * 0.1),
                            lineWidth: 2 - CGFloat(i) * 0.5
                        )
                        .scaleEffect(pulseScale + Double(i) * 0.05)
                        .opacity(isAnimating ? 0.6 - Double(i) * 0.2 : 0)
                        .animation(
                            Animation.easeInOut(duration: 1.2 + Double(i) * 0.3)
                                .repeatForever(autoreverses: false)
                                .delay(Double(i) * 0.4),
                            value: pulseScale
                        )
                }
            }
        }
    }
    
    // MARK: - 地图视图
    private var mapView: some View {
        ZStack {
            mapContent
                .overlay(mapOverlay)
                .cornerRadius(12)
                .frame(height: screenSize.width * 0.5)
                .padding(.horizontal)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            
            // 暂停状态标识 - 仅在暂停时显示
            if workoutSession.state == .paused {
                pauseIndicator
            }
        }
    }
    
    // 地图内容
    private var mapContent: some View {
        Group {
            #if swift(>=5.9) && canImport(MapKit)
            // iOS 17+ 新的Map API
            Map(initialPosition: .region(mapRegion)) {
                // 使用系统的用户位置标记 - 更准确
                UserAnnotation()
                
                // 路线轨迹
                if locationAnnotations.count > 1 {
                    MapPolyline(coordinates: locationAnnotations.map { $0.coordinate })
                        .stroke(primaryColor, lineWidth: 4)
                }
                
                // 起点标记
                if let firstLocation = locationAnnotations.first {
                    Annotation("起点", coordinate: firstLocation.coordinate) {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "flag.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .mapStyle(.standard)
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .onMapCameraChange { context in
                // 实时更新地图区域
                mapRegion = MKCoordinateRegion(
                    center: context.region.center,
                    span: context.region.span
                )
            }
            .overlay(alignment: .topTrailing) {
                // 保留GPS信号强度指示器
                GPSSignalIndicator(accuracy: locationAccuracy, lastUpdate: lastLocationUpdate)
                    .padding(.trailing, 12)
                    .padding(.top, 12)
            }
            #else
            // 旧的Map API，用于兼容iOS 16及更早版本
            Map(coordinateRegion: $mapRegion, showsUserLocation: true, annotationItems: locationAnnotations) { annotation in
                MapMarker(coordinate: annotation.coordinate, tint: primaryColor)
            }
            .overlay(alignment: .topTrailing) {
                // GPS信号强度指示器
                GPSSignalIndicator(accuracy: locationAccuracy, lastUpdate: lastLocationUpdate)
                    .padding(.trailing, 12)
                    .padding(.top, 12)
            }
            #endif
        }
    }
    
    // 地图覆盖层
    private var mapOverlay: some View {
        Group {
            if workoutSession.locationHistory.count < 2 {
                ZStack {
                    Color.white.opacity(0.8)
                    VStack(spacing: 10) {
                        Image(systemName: "location.magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundColor(primaryColor)
                            .padding(.bottom, 5)
                        
                        Text("等待位置数据...")
                            .font(.headline)
                        
                        Text("请保持移动以收集运动轨迹")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding()
                }
            }
        }
    }
    
    // 暂停指示器
    private var pauseIndicator: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: 70, height: 70)
            
            Image(systemName: "pause.fill")
                .font(.system(size: 30))
                .foregroundColor(.white)
        }
        .opacity(pauseOpacity)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                pauseOpacity = 1.0
            }
        }
    }
    
    /// 甜品颜色
    private var dessertColor: Color {
        return workoutSession.targetDessert.backgroundColor ?? primaryColor
    }
    
    /// 格式化的时间
    private var formattedTime: String {
        let totalSeconds = workoutSession.totalElapsedSeconds
        let minutes = Int(totalSeconds / 60)
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// 距离或次数显示
    private var distanceOrCount: String {
        if workoutSession.exerciseType.requiresGPS {
            // 显示距离（公里）
            return String(format: "%.2f", workoutSession.distanceInMeters / 1000)
        } else {
            // 显示次数 - 这里需要实际实现
            return "\(workoutSession.repetitionCount)"
        }
    }
    
    /// 距离或次数标签
    private var distanceOrCountLabel: String {
        if workoutSession.exerciseType.requiresGPS {
            return "总里程(km)"
        } else {
            return "完成次数"
        }
    }
    
    /// 配速字符串 (分钟/公里)
    private var paceString: String {
        guard workoutSession.distanceInMeters > 100 else { return "--" }
        
        let totalMinutes = workoutSession.totalElapsedSeconds / 60
        let pace = totalMinutes / (workoutSession.distanceInMeters / 1000)
        
        let paceMinutes = Int(pace)
        let paceSeconds = Int((pace - Double(paceMinutes)) * 60)
        
        return String(format: "%d'%02d\"", paceMinutes, paceSeconds)
    }
    
    /// 平均速度字符串 (公里/小时)
    private var avgSpeedString: String {
        guard workoutSession.totalElapsedSeconds > 0 else { return "--" }
        
        let hours = workoutSession.totalElapsedSeconds / 3600
        let speed = (workoutSession.distanceInMeters / 1000) / hours
        
        return String(format: "%.1f", speed)
    }
    
    // MARK: - 通知处理
    
    /// 设置通知监听器
    private func setupNotificationObservers() {
        // 监听应用进入后台
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            isAppActive = false
        }
        
        // 监听应用即将进入前台
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            isAppActive = true
            // 如果是GPS运动，刷新地图
            if workoutSession.exerciseType.requiresGPS {
                updateMapRegion()
            }
        }
        
        // 监听停止动画通知
        NotificationCenter.default.addObserver(
            forName: Notification.Name("SuspendWorkoutAnimations"),
            object: nil,
            queue: .main
        ) { _ in
            pauseOpacity = 0.0
        }
    }
    
    /// 移除通知监听器
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name("SuspendWorkoutAnimations"),
            object: nil
        )
    }
    
    /// 更新地图区域
    private func updateMapRegion() {
        guard !workoutSession.locationHistory.isEmpty else { return }
        
        if workoutSession.locationHistory.count > 1 {
            // 获取所有位置的经纬度
            let coordinates = workoutSession.locationHistory.map { 
                CLLocationCoordinate2D(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
            }
            
            // 计算边界
            var minLat = coordinates.map { $0.latitude }.min() ?? 0
            var maxLat = coordinates.map { $0.latitude }.max() ?? 0
            var minLon = coordinates.map { $0.longitude }.min() ?? 0
            var maxLon = coordinates.map { $0.longitude }.max() ?? 0
            
            // 添加边距
            let latPadding = (maxLat - minLat) * 0.2
            let lonPadding = (maxLon - minLon) * 0.2
            
            minLat -= latPadding
            maxLat += latPadding
            minLon -= lonPadding
            maxLon += lonPadding
            
            // 计算中心和跨度
            let center = CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2, 
                longitude: (minLon + maxLon) / 2
            )
            
            let span = MKCoordinateSpan(
                latitudeDelta: max(0.005, maxLat - minLat),
                longitudeDelta: max(0.005, maxLon - minLon)
            )
            
            // 设置地图区域
            mapRegion = MKCoordinateRegion(center: center, span: span)
        } else if let location = workoutSession.locationHistory.first {
            // 只有一个位置，以该位置为中心
            mapRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        }
    }
    
    // MARK: - 辅助计算属性
    
    /// 位置标注
    private var locationAnnotations: [LocationAnnotation] {
        return workoutSession.locationHistory.map { 
            LocationAnnotation(id: UUID(), coordinate: $0.coordinate)
        }
    }
    
    /// 格式化时间
    private var formattedDuration: String {
        let duration = Int(workoutSession.totalElapsedSeconds)
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// 格式化距离
    private var formattedDistance: String {
        let distanceInKm = workoutSession.distanceInMeters / 1000.0
        return String(format: "%.2f公里", distanceInKm)
    }
    
    /// 格式化卡路里
    private var formattedCalories: String {
        return String(format: "%.0f卡", workoutSession.burnedCalories)
    }
    
    /// 格式化配速
    private var formattedPace: String {
        if workoutSession.distanceInMeters > 100 && workoutSession.totalElapsedSeconds > 30 {
            // 计算配速（分钟/公里）
            let paceInSeconds = workoutSession.totalElapsedSeconds / (workoutSession.distanceInMeters / 1000)
            let paceMinutes = Int(paceInSeconds / 60)
            let paceSeconds = Int(paceInSeconds.truncatingRemainder(dividingBy: 60))
            return String(format: "%d'%02d\"", paceMinutes, paceSeconds)
        } else {
            return "--'--\""
        }
    }
    
    /// 运动强度
    private var workoutIntensity: String {
        // 基于卡路里消耗计算强度
        let intensity = workoutSession.burnedCalories / workoutSession.totalElapsedSeconds * 60
        
        if intensity < 5 {
            return "低"
        } else if intensity < 10 {
            return "中"
        } else {
            return "高"
        }
    }
    
    // 处理地图资源加载问题
    private func setupMapResources() {
        // 检查是否已经处理过资源问题
        if !resourcesLoaded {
            // 创建一个空的default.csv文件到应用文档目录
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let defaultCSVPath = documentsDirectory.appendingPathComponent("default.csv")
            
            // 只有在文件不存在时才创建
            if !fileManager.fileExists(atPath: defaultCSVPath.path) {
                do {
                    // 创建一个含有基本CSV结构的文件而不是空文件
                    let basicCSVContent = "id,name,latitude,longitude\n"
                    try basicCSVContent.write(to: defaultCSVPath, atomically: true, encoding: .utf8)
                    print("创建默认地图资源文件成功")
                } catch {
                    print("创建default.csv时出错: \(error.localizedDescription)")
                }
            }
            
            // 设置为已处理
            resourcesLoaded = true
        }
    }
    
    // 添加位置跟踪方法
    private func setupLocationTracking() {
        // 设置位置监听器
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("LocationUpdated"),
            object: nil,
            queue: .main
        ) { notification in
            if let locationData = notification.userInfo?["location"] as? CLLocation {
                self.userLocation = locationData.coordinate
                self.locationAccuracy = locationData.horizontalAccuracy
                self.lastLocationUpdate = Date()
            }
        }
        
        // 创建位置监听定时器，确保定位更新
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if let location = self.workoutSession.locationManager?.manager.location {
                self.userLocation = location.coordinate
                self.locationAccuracy = location.horizontalAccuracy
                self.lastLocationUpdate = Date()
                
                // 发布通知以便其他组件更新
                NotificationCenter.default.post(
                    name: NSNotification.Name("LocationUpdated"),
                    object: nil,
                    userInfo: ["location": location]
                )
            }
        }
    }
}

/// 核心数据卡片
struct CoreDataCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let isAnimating: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // 图标
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 45, height: 45)
                    .overlay(
                        Circle()
                            .stroke(iconColor.opacity(0.3), lineWidth: 2)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .opacity(isAnimating ? 0.4 : 0.0)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black.opacity(0.8))
                
                Text(label)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.gray)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

/// 位置标注
struct LocationAnnotation: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    
    init(id: UUID = UUID(), coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.coordinate = coordinate
    }
    
    init(from location: LocationPoint) {
        self.id = UUID()
        self.coordinate = location.coordinate
    }
}

// 添加悬浮数据卡片组件
struct FloatingDataCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            // 图标
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 28, height: 28)
                )
            
            // 值和标签垂直排列
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.6))
                .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
        )
    }
}

// 添加GPS信号强度指示器组件
struct GPSSignalIndicator: View {
    let accuracy: CLLocationAccuracy
    let lastUpdate: Date
    
    private var signalStrength: Int {
        if accuracy <= 5 {
            return 4 // 极佳信号
        } else if accuracy <= 10 {
            return 3 // 良好信号
        } else if accuracy <= 50 {
            return 2 // 一般信号
        } else if accuracy <= 100 {
            return 1 // 弱信号
        } else {
            return 0 // 极弱信号或无信号
        }
    }
    
    private var signalColor: Color {
        switch signalStrength {
        case 4: return .green
        case 3: return .green.opacity(0.8)
        case 2: return .yellow
        case 1: return .orange
        default: return .red
        }
    }
    
    private var timeSinceUpdate: TimeInterval {
        return Date().timeIntervalSince(lastUpdate)
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            HStack(spacing: 1) {
                ForEach(0..<5) { i in
                    Rectangle()
                        .fill(i < signalStrength ? signalColor : Color.gray.opacity(0.3))
                        .frame(width: 4, height: CGFloat(i + 1) * 3 + 2)
                        .cornerRadius(1)
                }
            }
            
            Text(String(format: "%.1fm", accuracy))
                .font(.system(size: 9))
                .foregroundColor(signalColor)
                .frame(height: 10)
        }
        .padding(6)
        .background(Color.white.opacity(0.8))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .opacity(timeSinceUpdate > 10 ? 0.5 : 1.0) // 10秒没更新则降低透明度
    }
} 