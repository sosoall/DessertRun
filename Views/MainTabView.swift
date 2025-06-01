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
    
    // 挑战视图模型 - 用于"我的挑战"页面
    @StateObject private var challengeViewModel = ChallengeViewModel(appState: AppState.shared)
    
    // 添加专门的运动记录视图模型 - 确保不被重复创建
    @StateObject private var exerciseRecordViewModel = ExerciseRecordViewModel(appState: AppState.shared)
    
    // 标签项配置
    private let tabItems = [
        TabItem(title: "挑战广场", icon: "trophy", selectedIcon: "trophy.fill"),
        TabItem(title: "我的挑战", icon: "list.bullet.rectangle", selectedIcon: "list.bullet.rectangle"),
        TabItem(title: "统计", icon: "chart.bar", selectedIcon: "chart.bar"),
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
                    // 挑战标签 - 使用新的优化版界面
                    NavigationStack {
                        ChallengeGridView()
                            .environmentObject(appState)
                    }
                case 1:
                    // 我的挑战标签
                    NavigationStack {
                        EnrolledChallengeView(viewModel: challengeViewModel)
                    }
                    .id("myChallengeTab")
                case 2:
                    // 运动记录标签 - 移除LazyView包装，使用专门的视图模型
                    NavigationStack {
                        ExerciseRecordView(viewModel: exerciseRecordViewModel)
                            .environmentObject(appState)
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
        // 监听美食券页面导航请求 - 已移除美食券tab，更改为导航到个人页面
        .onChange(of: workoutCoordinator.shouldNavigateToFoodCheckIn) { oldValue, shouldNavigate in
            if shouldNavigate {
                // 切换到个人页面查看排行榜
                DispatchQueue.main.async {
                    appState.selectedTabIndex = 3 // 个人页面现在是索引3
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