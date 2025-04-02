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
    
    /// 创建适配屏幕尺寸的配置
    /// - Parameter size: 屏幕尺寸
    /// - Returns: 适合的布局配置
    static func forScreenSize(_ size: CGSize) -> BubbleLayoutConfiguration {
        let smallerDimension = min(size.width, size.height)
        let multiplier = smallerDimension / 400 // 基准尺寸
        
        // 屏幕较小时（如iPhone SE、iPhone mini等）
        if smallerDimension < 380 {
            return BubbleLayoutConfiguration(
                bubbleSize: 120 * multiplier,
                minBubbleSize: 60 * multiplier,
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
                maxOffsetX: 150 * multiplier,
                maxOffsetY: 200 * multiplier,
                initialSpreadMultiplier: 1.0
            )
        } else {
            // 大屏幕配置（iPhone标准尺寸及以上）
            return BubbleLayoutConfiguration(
                bubbleSize: 180 * multiplier,
                minBubbleSize: 120 * multiplier,
                rowGap: 30 * multiplier,     // 行间距
                colGap: 15 * multiplier,     // 列间距
                provideProps: true,
                numCols: 4,
                fringeWidth: 120 * multiplier,
                yRadius: 180 * multiplier,
                xRadius: 120 * multiplier,
                cornerRadius: 70 * multiplier,
                showGuides: false,
                compact: true,
                gravitation: 0.1,
                maxOffsetX: 180 * multiplier,
                maxOffsetY: 250 * multiplier,
                initialSpreadMultiplier: 1.0
            )
        }
    }
} 