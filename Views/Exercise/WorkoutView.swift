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
    
    /// 页面标题
    private var pageTitle: String {
        pageIndex == 0 ? "运动激励" : "运动数据"
    }
    
    // 初始化会话
    init() {
        // 创建并初始化StateObject
        let targetDessert = AppState.shared.selectedDessert ?? DessertData.getSampleDesserts().first!
        let exerciseType = AppState.shared.selectedExerciseType ?? ExerciseTypeData.getSampleExerciseTypes().first!
        
        _workoutSession = StateObject(wrappedValue: WorkoutSession(
            targetDessert: targetDessert,
            exerciseType: exerciseType
        ))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景色
                Color(hex: "faf0dd").ignoresSafeArea()
                
                // 主要内容
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
                
                // 暂停菜单遮罩
                if showPauseMenu {
                    PauseMenuView(
                        onResume: {
                            workoutSession.resume()
                            showPauseMenu = false
                        },
                        onStop: {
                            // 停止运动并跳转到完成页面
                            workoutSession.complete()
                            navigateToComplete = true
                        }
                    )
                    .transition(.opacity)
                }
                
                // 底部控制栏
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
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(pageTitle)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                // 上方页面指示器
                PageIndicator(currentPage: pageIndex)
            }
        }
        .onAppear {
            // 启动会话
            workoutSession.start()
            
            // 设置为当前活动的运动会话
            appState.activeWorkoutSession = workoutSession
            
            // 开始定时更新
            startTimer()
        }
        .navigationDestination(isPresented: $navigateToComplete) {
            WorkoutCompleteView(workoutSession: workoutSession)
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