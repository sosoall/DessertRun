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
    
    // 计算底部安全区域填充
    private var bottomSafeAreaPadding: CGFloat {
        return max(0, safeAreaBottom)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabItems.enumerated()), id: \.element.id) { index, item in
                Button(action: {
                    if selectedTab != index {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = index
                        }
                    }
                }) {
                    // 只显示图标，移除文本
                    Image(systemName: selectedTab == index ? item.selectedIcon : item.icon)
                        .font(.system(size: 24)) // 放大图标
                        .foregroundColor(selectedTab == index ? accentColor : Color.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, bottomSafeAreaPadding + 10) // 添加安全区域填充和底部间距
        .opacity(isHidden ? 0 : 1) // 使用透明度控制显示/隐藏
        .animation(.easeInOut(duration: 0.3), value: isHidden)
        // 获取安全区域底部高度
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SafeAreaBottomPreferenceKey.self, value: geometry.safeAreaInsets.bottom)
            }
        )
        .onPreferenceChange(SafeAreaBottomPreferenceKey.self) { value in
            safeAreaBottom = max(0, value) // 确保值不为负
        }
    }
}

// 安全区域底部高度首选项键
struct SafeAreaBottomPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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
    
    // 计算内容底部填充
    private var contentBottomPadding: CGFloat {
        if appState.shouldHideTabBar {
            return 0
        } else {
            // 为悬浮TabBar增加额外的底部间距
            return 80 + safeAreaBottom // 悬浮TabBar高度 + 安全区域
        }
    }
    
    var body: some View {
        // 使用ZStack完全覆盖，确保TabBar在底部
        ZStack(alignment: .bottom) {
            // 主内容
            content()
                // 根据TabBar是否隐藏调整底部padding
                .padding(.bottom, contentBottomPadding)
            
            // 自定义TabBar
            CustomTabBar(
                selectedTab: $selectedTab,
                tabItems: tabItems,
                isHidden: appState.shouldHideTabBar,
                accentColor: accentColor
            )
            .padding(.bottom, 15) // 距离底部安全区域的额外间隔
        }
        .background(Color.white)
        // 获取安全区域底部高度
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SafeAreaBottomPreferenceKey.self, value: geometry.safeAreaInsets.bottom)
            }
        )
        .onPreferenceChange(SafeAreaBottomPreferenceKey.self) { value in
            safeAreaBottom = max(0, value) // 确保值不为负
        }
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
        Color.white
            .ignoresSafeArea()
    }
    .environmentObject(AppState.shared)
} 