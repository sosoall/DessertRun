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
    
    // 计算属性
    var maxSize: CGFloat { bubbleSize }
    var minSize: CGFloat { minBubbleSize }
    
    /// 为iPhone 16创建优化的配置（约390×844点）
    /// 中间可显示3行，每行2-3个气泡
    static func foriPhone16() -> BubbleLayoutConfiguration {
        return BubbleLayoutConfiguration(
            bubbleSize: 120,         // 气泡最大尺寸
            minBubbleSize: 60,       // 气泡最小尺寸
            gutter: 16,              // 气泡间距
            provideProps: true,      // 传递属性
            numCols: 3,              // 每行最多3个气泡
            fringeWidth: 120,        // 过渡区域宽度 (从70增大到120)
            yRadius: 180,            // 中心区域垂直半径
            xRadius: 180,            // 中心区域水平半径
            cornerRadius: 90,        // 中心区域圆角半径
            showGuides: false,       // 参考线
            compact: true,           // 紧凑布局
            gravitation: 0.4         // 引力效果
        )
    }
    
    /// 创建适配屏幕尺寸的配置
    /// - Parameter size: 屏幕尺寸
    /// - Returns: 适合的布局配置
    static func forScreenSize(_ size: CGSize) -> BubbleLayoutConfiguration {
        // 检查是否是iPhone 16尺寸（大约390×844）
        if size.width >= 385 && size.width <= 395 && size.height >= 840 && size.height <= 850 {
            return foriPhone16()
        }
        
        let smallerDimension = min(size.width, size.height)
        let multiplier = smallerDimension / 400 // 基准尺寸
        
        // 屏幕较小时
        if smallerDimension < 360 {
            return BubbleLayoutConfiguration(
                bubbleSize: 110 * multiplier,
                minBubbleSize: 50 * multiplier,
                gutter: 12 * multiplier,
                provideProps: true,
                numCols: 4,
                fringeWidth: 100 * multiplier,  // 从70增大到100
                yRadius: 130 * multiplier,
                xRadius: 130 * multiplier,
                cornerRadius: 60 * multiplier,
                showGuides: false,
                compact: true,
                gravitation: 0.3
            )
        } else {
            // 大屏幕配置
            return BubbleLayoutConfiguration(
                bubbleSize: 180 * multiplier,
                minBubbleSize: 80 * multiplier,
                gutter: 14 * multiplier,
                provideProps: true,
                numCols: 3,
                fringeWidth: 180 * multiplier,  // 从80增大到120
                yRadius: 250 * multiplier,
                xRadius: 150 * multiplier,
                cornerRadius: 70 * multiplier,
                showGuides: false,
                compact: true,
                gravitation: 0
            )
        }
    }
} 