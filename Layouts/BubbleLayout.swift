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
    @State private var lastDragPosition: CGPoint?
    
    /// 气泡状态
    @State private var bubbleStates: [ID: BubbleState] = [:]
    
    /// 屏幕大小
    @State private var screenSize: CGSize = .zero
    
    // MARK: - 初始化器
    
    /// 初始化气泡布局
    /// - Parameters:
    ///   - items: 数据项数组
    ///   - config: 布局配置
    ///   - content: 气泡内容构建器
    init(items: [Item], config: BubbleLayoutConfiguration, @ViewBuilder content: @escaping (Item, BubbleState) -> Content) {
        self.items = items
        self.config = config
        self.content = content
    }
    
    // MARK: - 视图构建
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景（确保整个区域可接收手势）
                Color.clear
                    .contentShape(Rectangle())
                
                // 显示引导线（如果启用）
                if config.showGuides {
                    BubbleGuideView(config: config)
                        .allowsHitTesting(false)
                }
                
                // 内容层
                ForEach(items) { item in
                    let state = bubbleState(for: item, in: geometry)
                    
                    // 渲染项目内容
                    content(item, state)
                        .position(
                            x: geometry.size.width / 2 + state.position.x,
                            y: geometry.size.height / 2 + state.position.y
                        )
                }
            }
            // 使用高优先级手势，确保拖动优先于气泡点击
            .highPriorityGesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .local)
                    .onChanged { value in
                        let currentPosition = value.location
                        
                        if let lastPosition = lastDragPosition {
                            // 计算与上次位置的差值
                            let deltaX = currentPosition.x - lastPosition.x
                            let deltaY = currentPosition.y - lastPosition.y
                            
                            // 保存旧的偏移量用于边界检查
                            let oldOffset = contentOffset
                            
                            // 计算新的偏移量
                            var newOffset = CGPoint(
                                x: oldOffset.x - deltaX,
                                y: oldOffset.y - deltaY
                            )
                            
                            // 限制偏移量不超过最大值
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
                        }
                        
                        // 更新上一次拖动位置
                        lastDragPosition = currentPosition
                    }
                    .onEnded { _ in
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
                // 生成初始位置
                initialPositions = BubblePositionProvider.calculateBubblePositions(
                    totalItems: items.count,
                    config: config
                )
                // 初始计算气泡状态
                recalculateBubbleStates(for: geometry.size)
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
        if let id = item.id as? AnyHashable, let state = bubbleStates[id] {
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
            
            // 更新状态
            if let id = item.id as? AnyHashable {
                newStates[id] = BubbleState(
                    size: bubbleSize,
                    position: adjustedPosition,
                    originalPosition: offsetPosition,
                    scale: bubbleSize / config.bubbleSize,
                    distanceToCenter: distanceToCenter,
                    region: region
                )
            }
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
}

// 类型擦除辅助
private typealias ID = AnyHashable 