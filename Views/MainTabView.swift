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
    
    // 是否隐藏Tab栏
    @State private var hideTabBar = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                // 运动标签
                NavigationStack {
                    ExerciseHomeView(onDraggingChanged: { isDragging in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            hideTabBar = isDragging
                        }
                    })
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
            
            // 自定义TabBar覆盖层，当拖动时遮挡原始TabBar
            if hideTabBar {
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 49) // 标准TabBar高度
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: -2)
                    .ignoresSafeArea()
            }
        }
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
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState.shared)
} 