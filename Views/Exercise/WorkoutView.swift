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
        ZStack {
            // 背景
            Color.white.ignoresSafeArea()
            
            // 主内容
            VStack(spacing: 0) {
                // 顶部安全区域留白
                Spacer()
                    .frame(height: 60)
                    
                // 内容视图（动画/数据视图）
                if !isPaused {
                    if showDataView {
                        DataView(workoutSession: workoutSession)
                            .environmentObject(workoutSession)
                            .transition(.opacity)
                    } else {
                        AnimationView(workoutSession: workoutSession)
                            .environmentObject(workoutSession)
                            .transition(.opacity)
                    }
                }
                
                Spacer()
                
                // 底部控制区
                if !showPauseMenu {
                    VStack {
                        Spacer()
                        
                        // 底部控制区域
                        ControlBar(
                            pageIndex: $pageIndex,
                            onPause: {
                                workoutSession.pause()
                                showPauseMenu = true
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