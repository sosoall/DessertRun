//
//  MainTabView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

/// 应用主标签视图
struct MainTabView: View {
    // 全局应用状态
    @EnvironmentObject var appState: AppState
    
    // 标签项配置
    private let tabItems = [
        TabItem(title: "运动", icon: "figure.run", selectedIcon: "figure.run"),
        TabItem(title: "甜品打卡", icon: "birthday.cake", selectedIcon: "birthday.cake"),
        TabItem(title: "运动记录", icon: "chart.bar", selectedIcon: "chart.bar"),
        TabItem(title: "我的", icon: "person", selectedIcon: "person")
    ]
    
    var body: some View {
        // 使用自定义TabBar容器但确保没有额外的背景设置
        CustomTabViewContainer(
            selectedTab: $appState.selectedTabIndex,
            tabItems: tabItems
        ) {
            Group<AnyView> {
                switch appState.selectedTabIndex {
                case 0:
                    // 运动标签
                    AnyView(
                        NavigationStack {
                            ExerciseHomeView(onDraggingChanged: { isDragging in
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    appState.hideTabBarForDrag = isDragging
                                }
                            })
                        }
                    )
                case 1:
                    // 甜品打卡标签
                    AnyView(
                        NavigationStack {
                            FoodCheckInView(viewModel: StatsViewModel(appState: appState))
                        }
                        .id(appState.selectedTabIndex == 1 ? UUID() : "foodCheckInTab") // 添加动态ID确保每次切换都会重新创建
                    )
                case 2:
                    // 运动记录标签
                    AnyView(
                        NavigationStack {
                            ExerciseRecordView(viewModel: StatsViewModel(appState: appState))
                        }
                        .id(appState.selectedTabIndex == 2 ? UUID() : "exerciseRecordTab") // 添加动态ID确保每次切换都会重新创建
                    )
                case 3:
                    // 个人信息标签
                    AnyView(
                        NavigationStack {
                            ProfileHomeView()
                        }
                    )
                default:
                    AnyView(EmptyView())
                }
            }
            // 确保内容没有背景色设置
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
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState.shared)
} 