//
//  MainTabView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

/// 延迟加载的视图包装器
struct LazyView<Content: View>: View {
    let content: () -> Content
    
    init(_ content: @autoclosure @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
    }
}

/// 应用主标签视图
struct MainTabView: View {
    // 全局应用状态
    @EnvironmentObject var appState: AppState
    
    // 运动流程协调器
    @StateObject private var workoutCoordinator = WorkoutFlowCoordinator.shared
    
    // 运动统计视图模型 - 供首页内部复用
    @StateObject private var exerciseRecordViewModel = ExerciseRecordViewModel(appState: AppState.shared)
    
    // 标签项配置（新版：首页、打卡、我的）。打卡为主按钮，视觉高亮由CustomTabViewContainer处理。
    private let tabItems = [
        TabItem(title: "首页", icon: "house", selectedIcon: "house.fill"),
        TabItem(title: "打卡", icon: "figure.walk", selectedIcon: "figure.walk.circle.fill"),
        TabItem(title: "我的", icon: "person", selectedIcon: "person.fill")
    ]
    
    var body: some View {
        ZStack {
            // 使用自定义TabBar容器但确保没有额外的背景设置
            CustomTabViewContainer(
                selectedTab: $appState.selectedTabIndex,
                tabItems: tabItems
            ) {
                switch appState.selectedTabIndex {
                case 0:
                    // 首页：问候 + 美食券 + 统计
                    NavigationStack {
                        HomeView(viewModel: exerciseRecordViewModel)
                            .environmentObject(appState)
                    }
                    .id("homeTab")
                case 1:
                    // 打卡标签 - 自动进入运动打卡会话
                    Color.clear
                        .onAppear {
                            // 若尚未显示打卡视图，则显示
                            if !appState.showWorkoutView {
                                appState.showWorkoutView = true
                            }
                        }
                        .id("workoutTab")
                case 2:
                    // 个人信息标签
                    NavigationStack {
                        ProfileHomeView()
                    }
                default:
                    EmptyView()
                }
            }
            
            // 打卡完成视图覆盖层
            if workoutCoordinator.showCompletionView, let record = workoutCoordinator.latestWorkoutRecord {
                WorkoutCompleteView(
                    record: record,
                    challengeProgress: workoutCoordinator.latestChallengeProgress, // 使用coordinator中的挑战进度
                    isPresented: $workoutCoordinator.showCompletionView
                )
                .environmentObject(appState)
                .environmentObject(workoutCoordinator)
                .transition(.opacity)
                .zIndex(100) // 确保在所有内容之上
            }
            
            // 独立的运动打卡视图覆盖层
            if appState.showWorkoutView {
                WorkoutSessionView()
                    .environmentObject(appState)
                    .transition(.opacity)
                    .zIndex(200) // 确保在打卡完成视图之上
            }
        }
        .onChange(of: appState.shouldResetNavigation) { oldValue, shouldReset in
            if shouldReset {
                print("【调试】MainTabView检测到导航重置请求")
                print("【调试】当前TabIndex: \(appState.selectedTabIndex)")
                
                // 不需要额外的状态重置逻辑，finishWorkout已经处理了所有状态重置
                // 这里只需监听重置标志，用于触发视图刷新
                print("【调试】MainTabView已刷新导航状态")
            }
        }
        // 监听美食券页面导航请求 - 新版切换到首页（索引0）
        .onChange(of: workoutCoordinator.shouldNavigateToFoodCheckIn) { oldValue, shouldNavigate in
            if shouldNavigate {
                DispatchQueue.main.async {
                    appState.selectedTabIndex = 0 //到首页索引
                    workoutCoordinator.shouldNavigateToFoodCheckIn = false
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState.shared)
} 