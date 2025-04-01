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
    var gutter: CGFloat = 16             // 气泡间隔
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
                bubbleSize: 110 * multiplier,
                minBubbleSize: 50 * multiplier,
                gutter: 12 * multiplier,
                provideProps: true,
                numCols: 4,
                fringeWidth: 100 * multiplier,
                yRadius: 130 * multiplier,
                xRadius: 130 * multiplier,
                cornerRadius: 60 * multiplier,
                showGuides: false,
                compact: true,
                gravitation: 0.3,
                maxOffsetX: 200 * multiplier,
                maxOffsetY: 300 * multiplier,
                initialSpreadMultiplier: 1.0
            )
        } else {
            // 大屏幕配置（iPhone标准尺寸及以上）
            return BubbleLayoutConfiguration(
                bubbleSize: 180 * multiplier,
                minBubbleSize: 80 * multiplier,
                gutter: 14 * multiplier,
                provideProps: true,
                numCols: 4,
                fringeWidth: 180 * multiplier,  // 从80增大到120
                yRadius: 220 * multiplier,
                xRadius: 120 * multiplier,
                cornerRadius: 70 * multiplier,
                showGuides: false,
                compact: true,
                gravitation: 0,
                maxOffsetX: 200 * multiplier,
                maxOffsetY: 700 * multiplier
            )
        }
    }
} 