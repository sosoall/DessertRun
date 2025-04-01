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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 运动标签
            NavigationStack {
                ExerciseHomeView()
            }
            .tabItem {
                Label("运动", systemImage: "figure.run")
            }
            .tag(0)
            
            // 统计标签
            NavigationStack {
                StatsHomeView()
            }
            .tabItem {
                Label("统计", systemImage: "chart.bar.fill")
            }
            .tag(1)
            
            // 个人信息标签
            NavigationStack {
                ProfileHomeView()
            }
            .tabItem {
                Label("我的", systemImage: "person.fill")
            }
            .tag(2)
        }
        .accentColor(Color(hex: "FE2D55")) // 使用品牌主题色
        .onAppear {
            // 设置TabBar的外观
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white
            
            // 添加阴影
            appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
            
            // 应用这个外观
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState.shared)
} 