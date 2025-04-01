//
//  BubblePositionProvider.swift
//  DessertRun
//
//  Created by Claude on 2023/3/24.
//

import SwiftUI

/// 气泡位置提供者，计算初始的蜂窝状网格布局
struct BubblePositionProvider {
    /// 计算所有气泡的初始位置
    /// - Parameters:
    ///   - totalItems: 气泡总数
    ///   - config: 布局配置
    /// - Returns: 蜂窝状网格排列的位置数组
    static func calculateBubblePositions(totalItems: Int, config: BubbleLayoutConfiguration) -> [CGPoint] {
        let maxCols = config.numCols
        var positions: [CGPoint] = []
        var currentRow = 0
        var currentCol = 0
        
        // 基于气泡大小计算间距
        let baseColGap = config.colGap * (config.bubbleSize / config.maxSize)
        let baseRowGap = config.rowGap * (config.bubbleSize / config.maxSize)
        
        // 计算水平和垂直间距
        let horizontalSpacing = config.bubbleSize + baseColGap
        let verticalSpacing = config.bubbleSize + baseRowGap
        
        // 根据六边形蜂窝状排列逻辑计算位置
        for _ in 0..<totalItems {
            // 是否为奇数行
            let isOddRow = currentRow % 2 != 0
            
            // 行中最大列数
            let colsInThisRow = isOddRow ? maxCols - 1 : maxCols
            
            // 计算X位置，奇数行有偏移
            let xOffset = isOddRow ? horizontalSpacing / 2 : 0
            let x = CGFloat(currentCol) * horizontalSpacing + xOffset
            
            // 计算Y位置，使用0.866作为六边形排列的垂直压缩因子
            // 0.866约等于sqrt(3)/2，是六边形蜂窝状排列的标准垂直压缩比例
            let y = CGFloat(currentRow) * verticalSpacing * 0.866
            
            positions.append(CGPoint(x: x, y: y))
            
            // 更新列计数
            currentCol += 1
            
            // 如果达到当前行的最大列数，转到下一行
            if currentCol >= colsInThisRow {
                currentRow += 1
                currentCol = 0
            }
        }
        
        // 计算中心点以便居中对齐
        if !positions.isEmpty {
            let minX = positions.map { $0.x }.min() ?? 0
            let maxX = positions.map { $0.x }.max() ?? 0
            let minY = positions.map { $0.y }.min() ?? 0
            let maxY = positions.map { $0.y }.max() ?? 0
            
            let centerX = (minX + maxX) / 2
            let centerY = (minY + maxY) / 2
            
            // 使整体居中
            positions = positions.map { CGPoint(x: $0.x - centerX, y: $0.y - centerY) }
        }
        
        // 应用初始分布乘数因子
        if config.initialSpreadMultiplier != 1.0 {
            positions = positions.map { CGPoint(
                x: $0.x * config.initialSpreadMultiplier,
                y: $0.y * config.initialSpreadMultiplier
            )}
        }
        
        return positions
    }
} 