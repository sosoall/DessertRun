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
    
    // 标签项配置
    private let tabItems = [
        TabItem(title: "运动", icon: "figure.run", selectedIcon: "figure.run"),
        TabItem(title: "甜品打卡", icon: "birthday.cake", selectedIcon: "birthday.cake"),
        TabItem(title: "运动记录", icon: "chart.bar", selectedIcon: "chart.bar"),
        TabItem(title: "我的", icon: "person", selectedIcon: "person")
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
                    // 运动标签
                    NavigationStack {
                        ExerciseHomeView(onDraggingChanged: { isDragging in
                            withAnimation(.easeInOut(duration: 0.3)) {
                                appState.hideTabBarForDrag = isDragging
                            }
                        })
                    }
                case 1:
                    // 美食记录标签（甜品打卡）
                    NavigationStack {
                        // 使用LazyView包装FoodCheckInView，避免切换Tab时过早加载
                        LazyView(
                            FoodCheckInView(viewModel: FoodCheckInViewModel(appState: appState))
                        )
                    }
                    .id("foodCheckInTab") // 使用固定ID，避免每次都重新创建
                case 2:
                    // 运动记录标签
                    NavigationStack {
                        // 使用LazyView包装ExerciseRecordView，避免切换Tab时过早加载 
                        LazyView(
                            ExerciseRecordView(viewModel: ExerciseRecordViewModel(appState: appState))
                        )
                    }
                    .id("exerciseRecordTab") // 使用固定ID，避免每次都重新创建
                case 3:
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
                    isPresented: $workoutCoordinator.showCompletionView,
                    showFoodCheckInView: $workoutCoordinator.shouldNavigateToFoodCheckIn
                )
                .environmentObject(appState)
                .environmentObject(workoutCoordinator)
                .transition(.opacity)
                .zIndex(100) // 确保在所有内容之上
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
        // 监听美食券页面导航请求
        .onChange(of: workoutCoordinator.shouldNavigateToFoodCheckIn) { oldValue, shouldNavigate in
            if shouldNavigate {
                // 切换到美食券标签页
                DispatchQueue.main.async {
                    appState.selectedTabIndex = 1
                    // 重置导航标志
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