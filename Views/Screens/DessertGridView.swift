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
    
    /// 动画状态管理
    @ObservedObject var animationState: TransitionAnimationState
    
    /// 是否显示引导
    @State private var showGuides = false
    
    /// 环境中的应用状态
    @EnvironmentObject var appState: AppState
    
    /// 控制布局刷新
    @State private var forceLayoutUpdate = false
    
    /// 拖动状态回调
    var onDragStateChanged: ((Bool) -> Void)?
    
    // 初始化方法
    init(animationState: TransitionAnimationState, onDragStateChanged: ((Bool) -> Void)? = nil) {
        self.animationState = animationState
        self.onDragStateChanged = onDragStateChanged
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color(hex: "FFFFFF")
                .ignoresSafeArea()
                
                // 气泡布局
                BubbleLayout(
                    items: desserts,
                    config: createConfig(for: geometry.size),
                    onDragStateChanged: onDragStateChanged,
                    content: { dessert, state in
                        // 单个气泡内容
                        BubbleView(
                            item: dessert,
                            bubbleSize: state.size,
                            distanceToCenter: state.distanceToCenter,
                            maxSize: createConfig(for: geometry.size).bubbleSize,
                            minSize: createConfig(for: geometry.size).minBubbleSize,
                            onTap: { bubbleFrame in
                                // 记录选中的甜品和位置信息
                                print("【调试-详细】传递给动画状态 - 甜品: \(dessert.name)")
                                print("【调试-详细】框架: \(bubbleFrame), 中心点: (\(bubbleFrame.midX), \(bubbleFrame.midY))")
                                print("【调试-详细】大小: \(state.size), 到中心距离: \(state.distanceToCenter)")
                                animationState.selectDessert(dessert, originFrame: bubbleFrame, originalSize: state.size)
                            }
                        )
                    }
                )
                .id(forceLayoutUpdate) // 使用id强制刷新布局
                .padding(.top, 100) // 为顶部标题留出空间
                
                // 底部控制按钮
                VStack {
                    Spacer()
                    
                    // 底部控制按钮
                    HStack {
                        Button(action: { showGuides.toggle() }) {
                            Image(systemName: showGuides ? "eye.slash.fill" : "eye.fill")
                                .font(.title3)
                                .foregroundColor(Color(hex: "212121"))
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                                .shadow(color: Color(hex: "7E4A4A").opacity(0.25), radius: 10, x: 5, y: 5)
                        }
                    }
                    .padding(.bottom, 80) // 为底部导航栏留出空间
                }
            }
            .onAppear {
                // 延迟一点时间确保视图布局完成后再刷新气泡布局
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    forceLayoutUpdate.toggle()
                }
            }
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