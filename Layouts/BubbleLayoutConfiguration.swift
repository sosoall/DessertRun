//
//  BubbleLayoutConfiguration.swift
//  DessertRun
//
//  Created by Claude on 2023/3/24.
//

import SwiftUI

/// 气泡布局配置，控制布局的各种参数
struct BubbleLayoutConfiguration {
    // 布局主要参数
    var bubbleSize: CGFloat = 200        // 气泡最大尺寸
    var minBubbleSize: CGFloat = 20      // 气泡最小尺寸
    var rowGap: CGFloat = 15             // 行间距（垂直方向）
    var colGap: CGFloat = 15             // 列间距（水平方向）
    var provideProps: Bool = false       // 是否向子组件传递特殊属性
    var numCols: Int = 6                 // 排列的列数
    var fringeWidth: CGFloat = 100       // 过渡区域宽度
    var yRadius: CGFloat = 200           // 中心区域垂直半径
    var xRadius: CGFloat = 200           // 中心区域水平半径
    var cornerRadius: CGFloat = 100      // 中心区域圆角半径
    var showGuides: Bool = false         // 显示参考线
    var compact: Bool = false            // 紧凑模式
    var gravitation: CGFloat = 0         // 引力效果(0-1)
    var maxOffsetX: CGFloat = 200        // X轴最大偏移量
    var maxOffsetY: CGFloat = 300        // Y轴最大偏移量
    var initialSpreadMultiplier: CGFloat = 1.0 // 初始分布倍数（用于控制气泡初始分布的松散程度）
    
    // 计算属性
    var maxSize: CGFloat { bubbleSize }
    var minSize: CGFloat { minBubbleSize }
    
    /// 基于气泡数量计算最佳偏移量
    /// - Parameters:
    ///   - bubbleCount: 气泡数量
    ///   - screenSize: 屏幕尺寸
    /// - Returns: (maxOffsetX, maxOffsetY) 元组
    static func calculateOptimalOffsets(bubbleCount: Int, screenSize: CGSize, config: BubbleLayoutConfiguration) -> (CGFloat, CGFloat) {
        // 计算气泡布局需要的行数
        let rows = ceil(Double(bubbleCount) / Double(config.numCols))
        
        // 计算每行所需的高度 (气泡高度 + 行间距)
        let rowHeight = config.bubbleSize + config.rowGap
        
        // 计算X轴最大偏移量 - 确保边缘气泡可以移动到中心区域
        // 为简化计算，我们使用屏幕宽度的一定比例，但不小于气泡尺寸的2倍
        let minOffsetX = config.bubbleSize * 2
        let calculatedOffsetX = max(minOffsetX, screenSize.width * 0.4)
        
        // 计算Y轴最大偏移量 - 确保足够的垂直空间来容纳所有行
        // 确保所有气泡都有机会进入中心区域
        let minOffsetY = config.bubbleSize * 2
        let calculatedOffsetY = max(minOffsetY, CGFloat(rows) * rowHeight * 0.8)
        
        return (calculatedOffsetX, calculatedOffsetY)
    }
    
    /// 创建适配屏幕尺寸的配置
    /// - Parameter size: 屏幕尺寸
    /// - Returns: 适合的布局配置
    static func forScreenSize(_ size: CGSize, bubbleCount: Int = 20) -> BubbleLayoutConfiguration {
        let smallerDimension = min(size.width, size.height)
        let multiplier = smallerDimension / 400 // 基准尺寸
        
        // 创建初始配置
        var config: BubbleLayoutConfiguration
        
        // 屏幕较小时（如iPhone SE、iPhone mini等）
        if smallerDimension < 380 {
            config = BubbleLayoutConfiguration(
                bubbleSize: 110 * multiplier,
                minBubbleSize: 55 * multiplier,
                rowGap: 14 * multiplier,     // 行间距
                colGap: 10 * multiplier,     // 列间距
                provideProps: true,
                numCols: 3,
                fringeWidth: 80 * multiplier, 
                yRadius: 130 * multiplier,
                xRadius: 120 * multiplier,
                cornerRadius: 60 * multiplier,
                showGuides: false,
                compact: true,
                gravitation: 0.2,
                initialSpreadMultiplier: 1.0
            )
        } else {
            // 大屏幕配置（iPhone标准尺寸及以上）
            config = BubbleLayoutConfiguration(
                bubbleSize: 160 * multiplier,
                minBubbleSize: 100 * multiplier,
                rowGap: 35 * multiplier,     // 行间距
                colGap: 10 * multiplier,     // 列间距
                provideProps: true,
                numCols: 3,
                fringeWidth: 120 * multiplier,
                yRadius: 220 * multiplier,
                xRadius: 120 * multiplier,
                cornerRadius: 0 * multiplier,
                showGuides: false,
                compact: true,
                gravitation: 0.1,
                initialSpreadMultiplier: 1.0
            )
        }
        
        // 计算最佳偏移量并更新配置
        let (optimalOffsetX, optimalOffsetY) = calculateOptimalOffsets(bubbleCount: bubbleCount, screenSize: size, config: config)
        config.maxOffsetX = optimalOffsetX
        config.maxOffsetY = optimalOffsetY
        
        return config
    }
} 