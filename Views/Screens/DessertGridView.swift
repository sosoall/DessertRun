//
//  DessertGridView.swift
//  DessertRun
//
//  Created by Claude on 2025/3/24.
//

import SwiftUI

/// 甜品网格视图
struct DessertGridView: View {
    /// 甜品数据
    private let desserts = DessertData.getSampleDesserts()
    
    /// 选中的甜品
    @State private var selectedDessert: DessertItem?
    
    /// 是否显示引导
    @State private var showGuides = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color(hex: "fae8c8").ignoresSafeArea()
                
                // 气泡布局
                BubbleLayout(
                    items: desserts,
                    config: createConfig(for: geometry.size)
                ) { dessert, state in
                    // 单个气泡内容
                    BubbleView(
                        item: dessert,
                        bubbleSize: state.size,
                        distanceToCenter: state.distanceToCenter,
                        maxSize: createConfig(for: geometry.size).bubbleSize,
                        minSize: createConfig(for: geometry.size).minBubbleSize,
                        onTap: {
                            selectedDessert = dessert
                        }
                    )
                }
                
                // 顶部标题
                VStack {
                    Text("甜品菜单")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "61462C"))
                        .padding(.top, 30)
                    
                    Spacer()
                    
                    // 底部控制按钮
                    HStack {
                        Button(action: { showGuides.toggle() }) {
                            Image(systemName: showGuides ? "eye.slash.fill" : "eye.fill")
                                .font(.title3)
                                .foregroundColor(Color(hex: "61462C"))
                                .padding()
                                .background(Color.white.opacity(0.7))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .sheet(item: $selectedDessert) { dessert in
            // 详情页
            DessertDetailView(
                dessert: dessert,
                onClose: {
                    selectedDessert = nil
                }
            )
        }
    }
    
    /// 创建适合屏幕尺寸的配置
    /// - Parameter size: 屏幕尺寸
    /// - Returns: 布局配置
    private func createConfig(for size: CGSize) -> BubbleLayoutConfiguration {
        var config = BubbleLayoutConfiguration.forScreenSize(size)
        config.showGuides = showGuides
        return config
    }
} 