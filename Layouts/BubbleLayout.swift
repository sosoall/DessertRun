//
//  BubbleLayout.swift
//  DessertRun
//
//  Created by Claude on 2025/3/24.
//

import SwiftUI

/// 气泡布局
struct BubbleLayout<Item: Identifiable, Content: View>: View {
    // MARK: - 属性
    
    /// 数据项
    private let items: [Item]
    
    /// 布局配置
    private let config: BubbleLayoutConfiguration
    
    /// 气泡内容构建器
    private let content: (Item, BubbleState) -> Content
    
    /// 气泡初始位置
    @State private var initialPositions: [CGPoint] = []
    
    /// 内容偏移量
    @State private var contentOffset: CGPoint = .zero
    
    /// 上一次拖动位置
    @State private var lastDragPosition: CGPoint? = nil
    
    /// 气泡状态
    @State private var bubbleStates: [ID: BubbleState] = [:]
    
    /// 是否正在拖动
    @State private var isDragging: Bool = false
    
    /// 屏幕大小
    @State private var screenSize: CGSize = .zero
    
    /// 是否已完成初始化
    @State private var isInitialized: Bool = false
    
    /// 缩放比例
    @State private var scaleAmount: CGFloat = 1.0
    
    /// 最小缩放比例
    private let minScale: CGFloat = 0.6
    
    /// 原始缩放比例
    private let originalScale: CGFloat = 1.0
    
    /// 最大缩放比例
    private let maxScale: CGFloat = 1.5
    
    /// 拖动状态回调
    var onDragStateChanged: ((Bool) -> Void)? = nil
    
    /// 环境中的应用状态
    @EnvironmentObject var appState: AppState
    
    /// 是否锁定到原始大小
    @State private var isLockedToOriginalSize: Bool = false
    
    /// 上一次缩放比例
    @State private var lastScale: CGFloat = 1.0
    
    // MARK: - 初始化器
    
    /// 初始化气泡布局
    /// - Parameters:
    ///   - items: 数据项数组
    ///   - config: 布局配置
    ///   - content: 气泡内容构建器
    init(
        items: [Item],
        config: BubbleLayoutConfiguration = BubbleLayoutConfiguration(),
        @ViewBuilder content: @escaping (Item, BubbleState) -> Content
    ) {
        self.items = items
        self.config = config
        self.content = content
    }
    
    /// 带拖动回调的初始化
    init(
        items: [Item],
        config: BubbleLayoutConfiguration = BubbleLayoutConfiguration(),
        onDragStateChanged: ((Bool) -> Void)? = nil,
        @ViewBuilder content: @escaping (Item, BubbleState) -> Content
    ) {
        self.items = items
        self.config = config
        self.content = content
        self.onDragStateChanged = onDragStateChanged
    }
    
    // MARK: - 视图构建
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景指南（仅调试模式显示）
                if config.showGuides {
                    guides
                }
                
                // 气泡内容
                ForEach(items) { item in
                    let state = bubbleState(for: item, in: geometry)
                    content(item, state)
                        .position(x: geometry.size.width/2 + state.position.x, y: geometry.size.height/2 + state.position.y)
                        .animation(isInitialized && !isDragging ? .interpolatingSpring(stiffness: 300, damping: 15) : nil, value: state.position)
                        .animation(isInitialized && !isDragging ? .easeInOut : nil, value: state.size)
                }
            }
            .scaleEffect(scaleAmount)
            .contentShape(Rectangle())
            // 添加缩放手势
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        // 添加调试信息
                        print("【缩放调试】当前手势值: \(value), 当前缩放: \(scaleAmount)")
                        
                        // 降低缩放灵敏度：应用缩放系数0.5，使手势的效果减弱
                        let dampedValue = 1.0 + (value - 1.0) * 0.5
                        
                        // 计算新的缩放值，使用降低灵敏度后的值
                        let newScale = dampedValue * lastScale
                        
                        print("【缩放调试】原始手势值: \(value), 降低灵敏度后: \(dampedValue), 计算出的新缩放比例: \(newScale)")
                        
                        // 检查是否在缩放过程中经过1.0点
                        if (lastScale < 1.0 && newScale > 1.0) || 
                           (lastScale > 1.0 && newScale < 1.0) {
                            print("【缩放调试】经过100%，锁定为原始大小")
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                scaleAmount = 1.0
                                isLockedToOriginalSize = true
                                lastScale = 1.0 // 重要：更新lastScale
                            }
                            return
                        }
                        
                        // 如果不是经过1.0点，继续正常缩放
                        let limitedScale = min(maxScale, max(minScale, newScale))
                        
                        // 添加缓动效果：通过微小增量变化而不是直接设置
                        let smoothedScale = scaleAmount + (limitedScale - scaleAmount) * 0.3
                        
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            scaleAmount = smoothedScale
                            isLockedToOriginalSize = false
                        }
                    }
                    .onEnded { _ in
                        print("【缩放调试】缩放结束，最终缩放: \(scaleAmount)")
                        
                        // 更新最后的缩放值
                        lastScale = scaleAmount
                        
                        // 如果接近原始大小，吸附到1.0
                        if abs(scaleAmount - 1.0) < 0.15 {
                            print("【缩放调试】接近100%，吸附到原始大小")
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                scaleAmount = 1.0
                                isLockedToOriginalSize = true
                                lastScale = 1.0 // 重要：更新lastScale
                            }
                        }
                    }
            )
            // 拖动手势
            .simultaneousGesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .local)
                    .onChanged { value in
                        // 首次拖动时通知状态变更
                        if !isDragging {
                            isDragging = true
                            onDragStateChanged?(true)
                        }
                        
                        // 获取当前拖动位置
                        let currentPosition = value.location
                        
                        // 如果是第一次拖动，初始化lastDragPosition
                        if lastDragPosition == nil {
                            lastDragPosition = currentPosition
                            return
                        }
                        
                        // 计算拖动距离
                        let deltaX = currentPosition.x - lastDragPosition!.x
                        let deltaY = currentPosition.y - lastDragPosition!.y
                        
                        // 保存旧的偏移量用于边界检查
                        let oldOffset = contentOffset
                        
                        // 更新偏移量（直接更新，不使用动画）
                        var newOffset = CGPoint(
                            x: contentOffset.x - deltaX,
                            y: contentOffset.y - deltaY
                        )
                        
                        // 限制在最大范围内
                        newOffset.x = min(max(newOffset.x, -config.maxOffsetX), config.maxOffsetX)
                        newOffset.y = min(max(newOffset.y, -config.maxOffsetY), config.maxOffsetY)
                        
                        // 检查是否存在可见气泡
                        let wouldHaveVisibleBubbles = checkVisibleBubblesAfterOffset(
                            newOffset: newOffset,
                            size: geometry.size
                        )
                        
                        // 如果没有可见气泡，则添加弹性效果
                        if !wouldHaveVisibleBubbles {
                            // 添加弹性效果
                            let elasticFactor: CGFloat = 0.2
                            
                            // 应用弹性，偏移量会有一定的移动，但幅度减小
                            newOffset = CGPoint(
                                x: oldOffset.x - deltaX * elasticFactor,
                                y: oldOffset.y - deltaY * elasticFactor
                            )
                            
                            // 再次限制在最大范围内
                            newOffset.x = min(max(newOffset.x, -config.maxOffsetX), config.maxOffsetX)
                            newOffset.y = min(max(newOffset.y, -config.maxOffsetY), config.maxOffsetY)
                        }
                        
                        // 更新偏移量并重新计算气泡状态
                        contentOffset = newOffset
                        recalculateBubbleStates(for: geometry.size)
                        
                        // 更新上一次拖动位置
                        lastDragPosition = currentPosition
                        
                        // 保存到应用状态
                        appState.dessertGridOffset = contentOffset
                    }
                    .onEnded { _ in
                        // 标记结束拖动
                        isDragging = false
                        onDragStateChanged?(false)
                        
                        // 重置拖动状态
                        lastDragPosition = nil
                        
                        // 结束拖动时，检查是否存在可见气泡
                        let hasVisibleBubbles = checkVisibleBubblesAfterOffset(
                            newOffset: contentOffset,
                            size: geometry.size
                        )
                        
                        // 如果没有可见气泡，添加回弹动画
                        if !hasVisibleBubbles {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                // 找到最接近中心的气泡位置
                                if let closestPosition = findClosestBubblePosition() {
                                    // 设置偏移量使该气泡回到中心
                                    contentOffset = closestPosition
                                } else {
                                    // 如果找不到最近的气泡，重置为原始位置
                                    contentOffset = .zero
                                }
                                recalculateBubbleStates(for: geometry.size)
                            }
                        } else {
                            // 即使没有回弹，也限制在最大范围内并重新计算最终状态
                            contentOffset.x = min(max(contentOffset.x, -config.maxOffsetX), config.maxOffsetX)
                            contentOffset.y = min(max(contentOffset.y, -config.maxOffsetY), config.maxOffsetY)
                            recalculateBubbleStates(for: geometry.size)
                        }
                    }
            )
            .onAppear {
                // 尝试从应用状态恢复偏移量
                if appState.dessertGridOffset != .zero {
                    contentOffset = appState.dessertGridOffset
                }
                
                // 生成初始位置
                initialPositions = BubblePositionProvider.calculateBubblePositions(
                    totalItems: items.count,
                    config: config
                )
                // 初始计算气泡状态 - 直接显示，不要动画
                recalculateBubbleStates(for: geometry.size)
                
                // 延迟设置isInitialized以允许后续互动时的动画
                // 但是初始渲染不使用动画
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isInitialized = true
                }
            }
            .onChange(of: geometry.size) { oldSize, newSize in
                // 当尺寸变化时重新计算
                recalculateBubbleStates(for: newSize)
            }
        }
    }
    
    /// 计算特定项的气泡状态
    /// - Parameters:
    ///   - item: 数据项
    ///   - geometry: 几何信息
    /// - Returns: 气泡状态
    private func bubbleState(for item: Item, in geometry: GeometryProxy) -> BubbleState {
        if let state = bubbleStates[item.id] {
            return state
        }
        
        // 如果状态不存在，创建默认状态
        return BubbleState(
            size: config.bubbleSize,
            position: .zero,
            originalPosition: .zero,
            scale: 1.0,
            distanceToCenter: 0,
            region: .center
        )
    }
    
    /// 重新计算所有气泡状态
    /// - Parameter size: 容器尺寸
    private func recalculateBubbleStates(for size: CGSize) {
        var newStates: [ID: BubbleState] = [:]
        
        for (index, item) in items.enumerated() {
            guard index < initialPositions.count else { continue }
            
            // 获取初始位置并应用偏移
            let initialPosition = initialPositions[index]
            let offsetPosition = CGPoint(
                x: initialPosition.x - contentOffset.x,
                y: initialPosition.y - contentOffset.y
            )
            
            // 确定区域
            let region = BubbleGeometryCalculator.determineRegion(
                position: offsetPosition,
                config: config
            )
            
            // 计算尺寸
            let bubbleSize = BubbleGeometryCalculator.calculateBubbleSize(
                position: offsetPosition,
                region: region,
                config: config
            )
            
            // 计算位置（紧凑布局）
            let adjustedPosition = BubbleGeometryCalculator.calculateBubblePosition(
                originalPosition: offsetPosition,
                region: region,
                config: config
            )
            
            // 计算到中心的距离
            let distanceToCenter = BubbleGeometryCalculator.distance(
                from: offsetPosition,
                to: .zero
            )
            
            // 更新状态 - 直接使用item.id作为键
            newStates[item.id] = BubbleState(
                size: bubbleSize,
                position: adjustedPosition,
                originalPosition: offsetPosition,
                scale: bubbleSize / config.bubbleSize,
                distanceToCenter: distanceToCenter,
                region: region
            )
        }
        
        bubbleStates = newStates
    }
    
    /// 检查给定偏移量后是否有可见气泡
    /// - Parameters:
    ///   - newOffset: 新的偏移量
    ///   - size: 屏幕尺寸
    /// - Returns: 是否存在可见气泡
    private func checkVisibleBubblesAfterOffset(newOffset: CGPoint, size: CGSize) -> Bool {
        // 定义可见区域 - 向外扩展一点，让边缘有部分露出也算可见
        let visibleRect = CGRect(
            x: -size.width/2 - config.bubbleSize/2,
            y: -size.height/2 - config.bubbleSize/2,
            width: size.width + config.bubbleSize,
            height: size.height + config.bubbleSize
        )
        
        // 检查是否至少有一个气泡在可见区域内
        for position in initialPositions {
            // 计算位置加上偏移量后的位置
            let offsetPosition = CGPoint(
                x: position.x - newOffset.x,
                y: position.y - newOffset.y
            )
            
            // 如果至少有一个气泡在可见区域内，返回true
            if visibleRect.contains(offsetPosition) {
                return true
            }
        }
        
        return false
    }
    
    /// 找到最接近中心的气泡位置
    /// - Returns: 气泡原始位置
    private func findClosestBubblePosition() -> CGPoint? {
        guard !initialPositions.isEmpty else { return nil }
        
        // 找到距离最近的气泡
        var closestPosition: CGPoint = initialPositions[0]
        var minDistance: CGFloat = CGFloat.greatestFiniteMagnitude
        
        for position in initialPositions {
            let distance = sqrt(position.x * position.x + position.y * position.y)
            if distance < minDistance {
                minDistance = distance
                closestPosition = position
            }
        }
        
        return closestPosition
    }
    
    // MARK: - 辅助视图
    
    /// 引导线视图
    private var guides: some View {
        BubbleGuideView(config: config)
            .allowsHitTesting(false)
    }
}

// 类型擦除辅助
private typealias ID = AnyHashable 