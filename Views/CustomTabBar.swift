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

/// 安全区域底部高度首选项键
struct SafeAreaBottomPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// 超级简化版TabBar实现
struct CustomTabViewContainer<Content: View>: View {
    @EnvironmentObject var appState: AppState
    @Binding var selectedTab: Int
    let tabItems: [TabItem]
    let content: () -> Content
    let accentColor: Color
    
    // 安全区域底部高度
    @State private var safeAreaBottom: CGFloat = 0
    @State private var isDebugMode: Bool = false
    
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
        // 创建透明的基础容器
        GeometryReader { geo in
            Color.clear
                .overlay(
                    // 主内容
                    content()
                        .padding(.bottom, appState.shouldHideTabBar ? 0 : safeAreaBottom)
                )
                
                // TabBar浮动在底部
                .overlay(
                    Group {
                        if !appState.shouldHideTabBar {
                            // 只有这个背景是白色的
                            HStack(spacing: 0) {
                                let middleIndex = tabItems.count > 1 ? 1 : 0
                                ForEach(Array(tabItems.enumerated()), id: \.element.id) { index, item in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedTab = index
                                        }
                                    }) {
                                        if index == middleIndex {
                                            // 突出显示打卡按钮
                                            ZStack {
                                                Circle()
                                                    .fill(accentColor)
                                                    .frame(width: 48, height: 48)
                                                    .shadow(color: accentColor.opacity(0.4), radius: 6, x: 0, y: 4)
                                                Image(item.icon)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: 32, height: 32)
                                                    .foregroundColor(.white)
                                            }
                                            .frame(maxWidth: .infinity)
                                        } else {
                                            let isSelected = selectedTab == index
                                            Image(isSelected ? item.selectedIcon : item.icon)
                                                .resizable()
                                                .renderingMode(.original)
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: isSelected ? 23 : 25, height: isSelected ? 23 : 25)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 4)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .frame(width: geo.size.width * 0.8)
                            .background(
                                // 明确设置白色背景，只在这里
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                            )
                            .padding(.bottom, safeAreaBottom + 12)
                            .if(isDebugMode) { $0.border(Color.purple, width: 2) }
                        }
                    },
                    alignment: .bottom
                )
                .edgesIgnoringSafeArea(.bottom)
                
                // 获取安全区域底部高度
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: SafeAreaBottomPreferenceKey.self,
                            value: geometry.safeAreaInsets.bottom
                        )
                    }
                )
                .onPreferenceChange(SafeAreaBottomPreferenceKey.self) { value in
                    safeAreaBottom = max(0, value)
                }
                // 添加调试双击手势
                .onTapGesture(count: 2) {
                    isDebugMode.toggle()
                    print("TabBar Debug Mode: \(isDebugMode ? "ON" : "OFF")")
                }
                .background(Color.clear)
        }
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
        ZStack {
            // 测试背景色，确保内容视图底部透明
            LinearGradient(
                gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                Text("内容区域")
                    .font(.title)
                Spacer()
            }
            .padding()
        }
    }
} 