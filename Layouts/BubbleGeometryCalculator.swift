//
//  BubbleGeometryCalculator.swift
//  DessertRun
//
//  Created by Claude on 2025/3/24.
//

import SwiftUI

/// 气泡布局的几何计算工具类
struct BubbleGeometryCalculator {
    /// 计算两点之间的距离
    /// - Parameters:
    ///   - from: 起点
    ///   - to: 终点
    /// - Returns: 两点间的距离
    static func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        let dx = from.x - to.x
        let dy = from.y - to.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// 确定点所在的区域
    /// - Parameters:
    ///   - position: 点的位置
    ///   - config: 布局配置
    /// - Returns: 所在区域
    static func determineRegion(position: CGPoint, config: BubbleLayoutConfiguration) -> BubbleRegion {
        // 检查是否在角落区域
        let isInCornerZone = abs(position.x) > config.xRadius && abs(position.y) > config.yRadius
        
        var distanceToCenter: CGFloat
        
        if isInCornerZone {
            // 如果在角落区域，计算到内角的距离
            //有点怀疑是不是对的？？？？我看原公式非常复杂的
            let internalCornerX = config.xRadius - config.cornerRadius
            let internalCornerY = config.yRadius - config.cornerRadius
            let cornerX = position.x < 0 ? -internalCornerX : internalCornerX
            let cornerY = position.y < 0 ? -internalCornerY : internalCornerY
            
            distanceToCenter = distance(from: position, to: CGPoint(x: cornerX, y: cornerY))
            
            // 根据到内角的距离判断区域
            if distanceToCenter < config.cornerRadius {
                return .center
            } else if distanceToCenter < config.cornerRadius + config.fringeWidth {
                return .fringe
            } else {
                return .outer
            }
        } else {
            // 如果不在角落区域，使用矩形距离
            let distanceX = max(0, abs(position.x) - config.xRadius)
            let distanceY = max(0, abs(position.y) - config.yRadius)
            distanceToCenter = max(distanceX, distanceY)
            
            if distanceToCenter == 0 {
                return .center
            } else if distanceToCenter < config.fringeWidth {
                return .fringe
            } else {
                return .outer
            }
        }
    }
    
    /// 计算气泡尺寸
    /// - Parameters:
    ///   - position: 气泡位置
    ///   - region: 区域
    ///   - config: 布局配置
    /// - Returns: 计算后的尺寸
    static func calculateBubbleSize(position: CGPoint, region: BubbleRegion, config: BubbleLayoutConfiguration) -> CGFloat {
        switch region {
        case .center:
            return config.maxSize
        case .outer:
            return config.minSize
        case .fringe:
            // 计算到中心区域的距离
            var distanceToMiddleRegion: CGFloat
            
            // 检查是否在角落区域
            let isInCornerZone = abs(position.x) > config.xRadius && abs(position.y) > config.yRadius
            
            if isInCornerZone {
                // 如果在角落区域，计算到内角的距离
                let internalCornerX = config.xRadius - config.cornerRadius
                let internalCornerY = config.yRadius - config.cornerRadius
                let cornerX = position.x < 0 ? -internalCornerX : internalCornerX
                let cornerY = position.y < 0 ? -internalCornerY : internalCornerY
                
                let distanceToInternalCorner = distance(from: position, to: CGPoint(x: cornerX, y: cornerY))
                distanceToMiddleRegion = distanceToInternalCorner - config.cornerRadius
            } else {
                // 如果不在角落区域，使用矩形距离
                let distanceX = max(0, abs(position.x) - config.xRadius)
                let distanceY = max(0, abs(position.y) - config.yRadius)
                distanceToMiddleRegion = max(distanceX, distanceY)
            }
            
            // 插值计算尺寸
            let progress = distanceToMiddleRegion / config.fringeWidth
            return config.maxSize + progress * (config.minSize - config.maxSize)
        }
    }
    
    /// 计算气泡位置调整（用于紧凑布局）
    /// - Parameters:
    ///   - originalPosition: 原始位置
    ///   - region: 区域
    ///   - config: 布局配置
    /// - Returns: 调整后的位置
    static func calculateBubblePosition(
        originalPosition: CGPoint,
        region: BubbleRegion,
        config: BubbleLayoutConfiguration
    ) -> CGPoint {
        guard config.compact else {
            return originalPosition
        }
        
        var newPosition = originalPosition
        
        switch region {
        case .center:
            // 中心区域不需要调整
            return originalPosition
            
        case .fringe, .outer:
            // 计算到中心区域的距离和方向
            var distanceToMiddleRegion: CGFloat
            var direction: CGPoint
            
            // 检查是否在角落区域
            let isInCornerZone = abs(originalPosition.x) > config.xRadius && abs(originalPosition.y) > config.yRadius
            
            if isInCornerZone {
                // 如果在角落区域，计算到内角的方向
                let internalCornerX = config.xRadius - config.cornerRadius
                let internalCornerY = config.yRadius - config.cornerRadius
                let cornerX = originalPosition.x < 0 ? -internalCornerX : internalCornerX
                let cornerY = originalPosition.y < 0 ? -internalCornerY : internalCornerY
                let cornerPoint = CGPoint(x: cornerX, y: cornerY)
                
                let distanceToInternalCorner = distance(from: originalPosition, to: cornerPoint)
                distanceToMiddleRegion = distanceToInternalCorner - config.cornerRadius
                
                // 计算方向向量
                let dx = cornerPoint.x - originalPosition.x
                let dy = cornerPoint.y - originalPosition.y
                let mag = sqrt(dx * dx + dy * dy)
                direction = CGPoint(x: dx / mag, y: dy / mag)
            } else {
                // 如果不在角落区域，向中心移动
                let distanceX = max(0, abs(originalPosition.x) - config.xRadius)
                let distanceY = max(0, abs(originalPosition.y) - config.yRadius)
                distanceToMiddleRegion = max(distanceX, distanceY)
                
                // 计算方向 - 朝向坐标原点
                let dirX = originalPosition.x == 0 ? 0 : (originalPosition.x < 0 ? 1 : -1)
                let dirY = originalPosition.y == 0 ? 0 : (originalPosition.y < 0 ? 1 : -1)
                direction = CGPoint(x: dirX, y: dirY)
            }
            
            // 计算位移量
            var translationMagnitude: CGFloat
            
            if region == .outer {
                // 外部区域最大位移
                translationMagnitude = config.maxSize - config.minSize
                
                // 添加引力效果
                //疑问：引力效果最大值1，不知道是否和原版的实现效果一样？
                if config.gravitation > 0 {
                    let distanceToFringe = max(0, distanceToMiddleRegion - config.fringeWidth)
                    translationMagnitude += distanceToFringe * config.gravitation
                }
            } else {
                // 过渡区域中，位移量随进度变化
                let progress = distanceToMiddleRegion / config.fringeWidth
                translationMagnitude = progress * (config.maxSize - config.minSize)
            }
            
            // 应用位移
            newPosition.x += direction.x * translationMagnitude
            newPosition.y += direction.y * translationMagnitude
            
            return newPosition
        }
    }
} 