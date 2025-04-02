//
//  CustomTabBar.swift
//  DessertRun
//
//  Created by Claude on 2025/4/4.
//

import SwiftUI

/// 标签项
struct TabItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let selectedIcon: String
}

/// 自定义标签栏
struct CustomTabBar: View {
    // 当前选中标签
    @Binding var selectedTab: Int
    
    // 标签项数组
    let tabItems: [TabItem]
    
    // 是否隐藏
    let isHidden: Bool
    
    // 主题颜色
    let accentColor: Color
    
    // 初始化
    init(
        selectedTab: Binding<Int>,
        tabItems: [TabItem],
        isHidden: Bool = false,
        accentColor: Color = Color(hex: "FE2D55")
    ) {
        self._selectedTab = selectedTab
        self.tabItems = tabItems
        self.isHidden = isHidden
        self.accentColor = accentColor
    }
    
    var body: some View {
        // 整个TabBar作为一个整体向下滑动，不再使用VStack包裹
        ZStack(alignment: .top) {
            // 背景和阴影
            VStack(spacing: 0) {
                Divider()
                    .opacity(0.2)
                
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 49)
                    .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: -5)
            }
            
            // 标签按钮
            HStack(spacing: 0) {
                ForEach(Array(tabItems.enumerated()), id: \.element.id) { index, item in
                    Button(action: {
                        if selectedTab != index {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = index
                            }
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: selectedTab == index ? item.selectedIcon : item.icon)
                                .font(.system(size: 22))
                            
                            Text(item.title)
                                .font(.system(size: 10))
                        }
                        .foregroundColor(selectedTab == index ? accentColor : Color.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.top, 1) // 为分隔线预留空间
        }
        .frame(height: 50)
        .background(Color.white) // 确保整个TabBar都是白色背景
        .offset(y: isHidden ? 100 : 0) // 整体向下移出屏幕
        .animation(.easeInOut(duration: 0.3), value: isHidden)
    }
}

/// 自定义标签视图容器
struct CustomTabViewContainer<Content: View>: View {
    // 环境中的应用状态
    @EnvironmentObject var appState: AppState
    
    // 当前选中标签
    @Binding var selectedTab: Int
    
    // 标签项数组
    let tabItems: [TabItem]
    
    // 内容构建器
    let content: () -> Content
    
    // 前景色
    let accentColor: Color
    
    // 初始化
    init(
        selectedTab: Binding<Int>,
        tabItems: [TabItem],
        accentColor: Color = Color(hex: "FE2D55"),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._selectedTab = selectedTab
        self.tabItems = tabItems
        self.content = content
        self.accentColor = accentColor
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 主内容
            content()
                .ignoresSafeArea(.keyboard)
                // 当TabBar隐藏时，将内容扩展到底部
                .padding(.bottom, appState.shouldHideTabBar ? 0 : 49)
            
            // 自定义TabBar
            CustomTabBar(
                selectedTab: $selectedTab,
                tabItems: tabItems,
                isHidden: appState.shouldHideTabBar,
                accentColor: accentColor
            )
            .ignoresSafeArea(.keyboard)
            .ignoresSafeArea(.container, edges: .bottom) // 确保TabBar延伸到底部安全区域
        }
    }
}

// MARK: - 预览
struct CustomTabBar_Previews: PreviewProvider {
    static var tabItems = [
        TabItem(title: "运动", icon: "figure.run", selectedIcon: "figure.run.circle.fill"),
        TabItem(title: "统计", icon: "chart.bar", selectedIcon: "chart.bar.fill"),
        TabItem(title: "我的", icon: "person", selectedIcon: "person.fill")
    ]
    
    static var previews: some View {
        Group {
            // 正常显示
            CustomTabBar(
                selectedTab: .constant(0),
                tabItems: tabItems,
                isHidden: false
            )
            .previewLayout(.fixed(width: 375, height: 80))
            .previewDisplayName("显示状态")
            
            // 隐藏状态
            CustomTabBar(
                selectedTab: .constant(0),
                tabItems: tabItems,
                isHidden: true
            )
            .previewLayout(.fixed(width: 375, height: 80))
            .previewDisplayName("隐藏状态")
            
            // 完整容器
            CustomTabViewContainer(
                selectedTab: .constant(0),
                tabItems: tabItems
            ) {
                Color.blue
                    .ignoresSafeArea()
            }
            .environmentObject(AppState.shared)
            .previewDisplayName("完整容器")
        }
    }
} 