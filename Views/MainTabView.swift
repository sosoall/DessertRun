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
    
    // 当前选中的标签
    @State private var selectedTab = 0
    
    // 标签项配置
    private let tabItems = [
        TabItem(title: "运动", icon: "figure.run", selectedIcon: "figure.run.circle.fill"),
        TabItem(title: "统计", icon: "chart.bar", selectedIcon: "chart.bar.fill"),
        TabItem(title: "我的", icon: "person", selectedIcon: "person.fill")
    ]
    
    var body: some View {
        // 使用自定义TabBar容器
        CustomTabViewContainer(
            selectedTab: $selectedTab,
            tabItems: tabItems
        ) {
            Group {
                switch selectedTab {
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
                    // 统计标签
                    NavigationStack {
                        StatsHomeView()
                    }
                case 2:
                    // 个人信息标签
                    NavigationStack {
                        ProfileHomeView()
                    }
                default:
                    EmptyView()
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState.shared)
} 