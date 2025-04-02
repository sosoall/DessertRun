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
    
    // 安全区域底部高度
    @State private var safeAreaBottom: CGFloat = 0
    
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
        VStack(spacing: 0) {
            // 分隔线
            Divider()
                .opacity(0.2)
            
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
            .frame(height: 49)
            .padding(.bottom, safeAreaBottom > 0 ? 16 : 0) // 添加底部安全距离，仅在有Home指示条的设备上
            .background(Color.white)
            
            // 安全区域填充
            Rectangle()
                .fill(Color.white)
                .frame(height: safeAreaBottom)
                .edgesIgnoringSafeArea(.bottom)
        }
        .background(Color.white)
        .offset(y: isHidden ? (49 + safeAreaBottom + (safeAreaBottom > 0 ? 16 : 0) + 30) : 0) // 向下移出屏幕，增加额外30点确保完全隐藏
        .animation(.easeInOut(duration: 0.3), value: isHidden)
        // 获取安全区域底部高度
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        safeAreaBottom = geometry.safeAreaInsets.bottom
                    }
            }
        )
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
    
    // 安全区域底部高度 (用于计算内容底部padding)
    @State private var safeAreaBottom: CGFloat = 0
    
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
        // 使用ZStack完全覆盖，确保TabBar在底部
        ZStack(alignment: .bottom) {
            // 主内容
            content()
                // 根据TabBar是否隐藏调整底部padding
                // 当TabBar显示时，内容底部需要留出TabBar的高度 + 安全区域高度 + 安全距离
                .padding(.bottom, appState.shouldHideTabBar ? 0 : (49 + safeAreaBottom + (safeAreaBottom > 0 ? 16 : 0)))
            
            // 自定义TabBar
            CustomTabBar(
                selectedTab: $selectedTab,
                tabItems: tabItems,
                isHidden: appState.shouldHideTabBar,
                accentColor: accentColor
            )
        }
        // 获取安全区域底部高度
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        safeAreaBottom = geometry.safeAreaInsets.bottom
                    }
            }
        )
        // 忽略底部安全区域，以便TabBar可以扩展到底部
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    let tabItems = [
        TabItem(title: "运动", icon: "figure.run", selectedIcon: "figure.run.circle.fill"),
        TabItem(title: "统计", icon: "chart.bar", selectedIcon: "chart.bar.fill"),
        TabItem(title: "我的", icon: "person", selectedIcon: "person.fill")
    ]
    
    return CustomTabViewContainer(
        selectedTab: .constant(0),
        tabItems: tabItems
    ) {
        Color.blue
            .ignoresSafeArea()
    }
    .environmentObject(AppState.shared)
} 