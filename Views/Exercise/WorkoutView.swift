//
//  WorkoutView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

/// 运动界面
struct WorkoutView: View {
    /// 环境中的应用状态
    @EnvironmentObject var appState: AppState
    
    /// 页面索引（0：动画页，1：数据页）
    @State private var pageIndex = 0
    
    /// 运动会话
    @StateObject private var workoutSession: WorkoutSession
    
    /// 是否显示暂停菜单
    @State private var showPauseMenu = false
    
    /// 是否导航到完成页面
    @State private var navigateToComplete = false
    
    /// 倒计时计数
    @State private var countdownValue = 3
    
    /// 是否显示倒计时
    @State private var showingCountdown = true
    
    /// 页面标题
    private var pageTitle: String {
        pageIndex == 0 ? "运动激励" : "运动数据"
    }
    
    /// 当前运动类型
    private var exerciseType: ExerciseType {
        // 尝试从AppState获取，否则使用默认值
        AppState.shared.selectedExerciseType ?? ExerciseType.allCases.first!
    }
    
    // 初始化会话
    init() {
        // 创建并初始化StateObject
        let targetDessert = AppState.shared.selectedDessert ?? DessertData.getSampleDesserts().first!
        let exerciseType = AppState.shared.selectedExerciseType ?? ExerciseType.allCases.first!
        
        _workoutSession = StateObject(wrappedValue: WorkoutSession(
            targetDessert: targetDessert,
            exerciseType: exerciseType
        ))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景色
                Color.white.ignoresSafeArea()
                
                // 主要内容
                if showingCountdown {
                    // 倒计时视图
                    countdownView
                } else {
                    VStack(spacing: 0) {
                        // 标题和页面指示器 - 贴近顶部但留出灵动岛空间
                        VStack(spacing: 4) {
                            // 修改标题部分，使用HStack放在同一行
                            HStack(spacing: 8) {
                                Text("运动中")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Text("(\(workoutSession.exerciseType.name) · \(workoutSession.targetDessert.name))")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                            .padding(.top, 60) // 增加顶部边距，给灵动岛留空间
                            
                            // 页面指示器
                            PageIndicator(currentPage: pageIndex)
                        }
                        .padding(.top, 5) // 顶部留一点空间
                        .padding(.bottom, 5)
                        
                        // 页面内容
                        TabView(selection: $pageIndex) {
                            // 页面1：动画激励页
                            AnimationView(
                                workoutSession: workoutSession,
                                screenSize: geometry.size
                            )
                            .tag(0)
                            
                            // 页面2：数据页
                            DataView(
                                workoutSession: workoutSession,
                                screenSize: geometry.size
                            )
                            .tag(1)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        // 避免GPU后台渲染错误
                        .onDisappear {
                            // 在视图消失时释放资源
                            if pageIndex == 0 {
                                // 让主线程处理，避免后台GPU工作
                                DispatchQueue.main.async {
                                    // 空操作或简单重置
                                }
                            }
                        }
                    }
                    .edgesIgnoringSafeArea(.top)
                    
                    // 底部控制栏 - 仅在非暂停状态下显示
                    if !showPauseMenu {
                        VStack {
                            Spacer()
                            
                            // 底部控制区域
                            ControlBar(
                                pageIndex: $pageIndex,
                                onPause: {
                                    // 暂停运动会话
                                    workoutSession.pause()
                                    
                                    // 显示暂停菜单
                                    withAnimation(.easeInOut) {
                                        showPauseMenu = true
                                    }
                                }
                            )
                        }
                    } else {
                        // 暂停菜单
                        PauseMenuView(
                            onResume: {
                                // 恢复运动会话
                                workoutSession.resume()
                                
                                // 隐藏暂停菜单
                                withAnimation(.easeInOut) {
                                    showPauseMenu = false
                                }
                            },
                            onStop: {
                                // 停止运动并跳转到完成页面
                                workoutSession.complete()
                                
                                // 导航到完成页面
                                navigateToComplete = true
                            }
                        )
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // 隐藏返回按钮
        .toolbar {
            // 移除顶部工具栏中的页面指示器
            ToolbarItem(placement: .principal) {
                Text("")
            }
        }
        .onAppear {
            // 开始倒计时
            startCountdown()
            
            // 确保TabBar隐藏（运动模式）
            appState.isInWorkoutMode = true
            
            // 修复设备方向相关错误
            configureOrientation()
        }
        .navigationDestination(isPresented: $navigateToComplete) {
            WorkoutCompleteView(workoutSession: workoutSession)
        }
        .onDisappear {
            // 当用户点击返回按钮离开运动页面时恢复TabBar显示
            // WorkoutCompleteView有自己的onDisappear处理，所以这里只处理返回到ExerciseTypeSelectionView的情况
            if !navigateToComplete {
                appState.isInWorkoutMode = false
            }
        }
    }
    
    // 修复设备方向相关错误
    private func configureOrientation() {
        // 使用 UIWindowScene API 而不是直接设置 UIDevice.orientation
        // 这将防止 "BUG IN CLIENT OF UIKIT: Setting UIDevice.orientation is not supported" 错误
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            // 使用推荐的 API
            let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
            windowScene.requestGeometryUpdate(geometryPreferences) { error in
                // 直接处理错误，因为error已经是非可选类型
                print("方向更新错误: \(error.localizedDescription)")
            }
        }
    }
    
    // 倒计时视图
    private var countdownView: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "FF2D55"),
                    Color(hex: "FF9501")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 居中内容
            VStack(spacing: 0) {
                // 标题
                Text("准备开始")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 50)
                
                // 倒计时数字与环
                ZStack {
                    // 外层光晕
                    ForEach(0..<4) { i in
                        Circle()
                            .fill(Color.white.opacity(0.1 - Double(i) * 0.02))
                            .frame(width: 280 + CGFloat(i * 40), height: 280 + CGFloat(i * 40))
                            .scaleEffect(countdownValue == 3 ? 0.8 : 1.0)
                            .animation(.easeInOut(duration: 0.8), value: countdownValue)
                    }
                    
                    // 脉动光环
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0.2)]), 
                                startPoint: .top, 
                                endPoint: .bottom
                            ), 
                            lineWidth: 6
                        )
                        .frame(width: 220, height: 220)
                        .scaleEffect(countdownValue == 1 ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.8), value: countdownValue)
                    
                    // 内层圆
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)]),
                                center: .center,
                                startRadius: 5,
                                endRadius: 120
                            )
                        )
                        .frame(width: 200, height: 200)
                    
                    // 数字
                    Text("\(countdownValue)")
                        .font(.system(size: 140, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
                        .scaleEffect(countdownValue == 3 ? 1.2 : 1.0)
                        .scaleEffect(countdownValue == 1 ? 0.8 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: countdownValue)
                }
            }
        }
    }
    
    // 开始倒计时
    private func startCountdown() {
        // 创建计时器，每秒更新倒计时值
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownValue > 1 {
                countdownValue -= 1
            } else {
                // 倒计时结束
                timer.invalidate()
                
                // 开始运动
                withAnimation(.easeInOut(duration: 0.5)) {
                    showingCountdown = false
                    
                    // 启动会话
                    workoutSession.start()
                    
                    // 设置为当前活动的运动会话
                    appState.activeWorkoutSession = workoutSession
                    
                    // 开始定时更新
                    startTimer()
                }
            }
        }
    }
    
    // 启动定时器模拟数据更新
    private func startTimer() {
        // 创建1秒间隔的定时器，模拟数据更新
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if workoutSession.state == .active {
                // 更新时间和卡路里
                workoutSession.updateTimeAndCalories()
                
                // 模拟距离增加 (如果是GPS类型运动)
                if workoutSession.exerciseType.requiresGPS {
                    // 每秒增加1-3米
                    let speedMetersPerSecond = Double.random(in: 1...3)
                    workoutSession.distanceInMeters += speedMetersPerSecond
                    workoutSession.currentSpeed = speedMetersPerSecond
                }
                
                // 检查是否完成，如果卡路里达到目标，自动完成
                if workoutSession.burnedCalories >= workoutSession.targetCalories {
                    workoutSession.complete()
                    navigateToComplete = true
                    timer.invalidate()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutView()
            .environmentObject(AppState.shared)
    }
} 