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
    static func determineRegion(position: CGPoint, config: BubbleLayoutConfiguration, itemName: String? = nil) -> BubbleRegion {
        // 检查是否在角落区域
        let isInCornerZone = abs(position.x) > config.xRadius && abs(position.y) > config.yRadius
        
        var region: BubbleRegion
        
        if isInCornerZone {
            // 如果在角落区域，使用勾股定理计算到内角的距离
            let internalCornerX = config.xRadius - config.cornerRadius
            let internalCornerY = config.yRadius - config.cornerRadius
            
            // 注意使用abs取绝对值，然后计算到第一象限内角的距离
            let dx = abs(position.x) - internalCornerX
            let dy = abs(position.y) - internalCornerY
            
            // 使用勾股定理计算距离
            let distanceToInternalCorner = sqrt(dx * dx + dy * dy)
            
            // 根据到内角的距离判断区域
            if distanceToInternalCorner < config.cornerRadius {
                region = .center
            } else if distanceToInternalCorner < config.cornerRadius + config.fringeWidth {
                region = .fringe
            } else {
                region = .outer
            }
        } else {
            // 如果不在角落区域，使用坐标最大值计算
            let distanceToCenter = max(abs(position.x), abs(position.y))
            
            // 判断区域
            if abs(position.x) <= config.xRadius && abs(position.y) <= config.yRadius {
                region = .center
            } else if distanceToCenter < (abs(position.x) > config.xRadius ? config.xRadius + config.fringeWidth : config.yRadius + config.fringeWidth) {
                region = .fringe
            } else {
                region = .outer
            }
        }
        
        return region
    }
    
    /// 计算气泡尺寸
    /// - Parameters:
    ///   - position: 气泡位置
    ///   - region: 区域
    ///   - config: 布局配置
    /// - Returns: 计算后的尺寸
    static func calculateBubbleSize(position: CGPoint, region: BubbleRegion, config: BubbleLayoutConfiguration, itemName: String? = nil) -> CGFloat {
        switch region {
        case .center:
            return config.maxSize
        case .outer:
            return config.minSize
        case .fringe:
            // 计算到中心区域边界的距离
            let distanceToMiddleRegion = calculateDistanceToMiddleRegion(position: position, config: config)
            
            // 线性进度计算 (规范中的公式)
            let progress = min(distanceToMiddleRegion / config.fringeWidth, 1.0)
            
            // 计算大小 (使用线性插值)
            let size = config.maxSize + progress * (config.minSize - config.maxSize)
            return size
        }
    }
    
    /// 计算到中心区域边界的距离
    /// - Parameters:
    ///   - position: 气泡位置
    ///   - config: 布局配置
    /// - Returns: 到中心区域边界的距离
    private static func calculateDistanceToMiddleRegion(position: CGPoint, config: BubbleLayoutConfiguration) -> CGFloat {
        // 检查是否在角落区域
        let isInCornerZone = abs(position.x) > config.xRadius && abs(position.y) > config.yRadius
        
        if isInCornerZone {
            // 如果在角落区域，计算到内角的距离后减去cornerRadius
            let internalCornerX = config.xRadius - config.cornerRadius
            let internalCornerY = config.yRadius - config.cornerRadius
            
            let dx = abs(position.x) - internalCornerX
            let dy = abs(position.y) - internalCornerY
            
            let distanceToInternalCorner = sqrt(dx * dx + dy * dy)
            return max(0, distanceToInternalCorner - config.cornerRadius)
        } else {
            // 如果不在角落区域，计算到最近边的距离
            let distanceX = max(0, abs(position.x) - config.xRadius)
            let distanceY = max(0, abs(position.y) - config.yRadius)
            return max(distanceX, distanceY)
        }
    }
    
    /// 缓入缓出三次方缓动函数
    /// - Parameter t: 输入进度 (0-1)
    /// - Returns: 缓动后的进度 (0-1)
    private static func easeInOutCubic(_ t: CGFloat) -> CGFloat {
        // 在前半段使用缓入函数，在后半段使用缓出函数
        if t < 0.5 {
            // 前半段: 0-0.5 → 缓入
            return 4 * t * t * t
        } else {
            // 后半段: 0.5-1 → 缓出
            let f = t - 1.0
            return 1.0 + 4 * f * f * f
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
        config: BubbleLayoutConfiguration,
        itemName: String? = nil
    ) -> CGPoint {
        guard config.compact else {
            return originalPosition
        }
        
        // 中心区域不需要调整
        if region == .center {
            return originalPosition
        }
        
        // 获取当前气泡的实际大小
        let currentSize = calculateBubbleSize(
            position: originalPosition, 
            region: region, 
            config: config
        )
        
        // 计算大小变化量
        let sizeChange = config.maxSize - currentSize
        
        // 紧凑度系数 - 控制位移与大小变化的比例关系
        let compactnessFactor: CGFloat = 0.5
        
        // 计算到中心区域边界的参考点和距离
        var referencePoint: CGPoint = .zero
        var distanceToMiddleRegion: CGFloat = 0
        
        // 检查是否在角落区域
        let isInCornerZone = abs(originalPosition.x) > config.xRadius && abs(originalPosition.y) > config.yRadius
        
        if isInCornerZone {
            // 如果在角落区域，计算到内角的参考点
            let internalCornerX = config.xRadius - config.cornerRadius
            let internalCornerY = config.yRadius - config.cornerRadius
            let cornerX = originalPosition.x < 0 ? -internalCornerX : internalCornerX
            let cornerY = originalPosition.y < 0 ? -internalCornerY : internalCornerY
            referencePoint = CGPoint(x: cornerX, y: cornerY)
            
            distanceToMiddleRegion = distance(from: originalPosition, to: referencePoint) - config.cornerRadius
        } else {
            // 如果不在角落区域，计算到中心区域边界的最近点
            let clampedX = min(max(originalPosition.x, -config.xRadius), config.xRadius)
            let clampedY = min(max(originalPosition.y, -config.yRadius), config.yRadius)
            
            // 找出是哪个边界最近
            let onVerticalBoundary = abs(originalPosition.x) > config.xRadius
            let onHorizontalBoundary = abs(originalPosition.y) > config.yRadius
            
            if onVerticalBoundary && !onHorizontalBoundary {
                // 在垂直边界上，参考点在边界上与原点同一水平线
                referencePoint = CGPoint(
                    x: originalPosition.x < 0 ? -config.xRadius : config.xRadius,
                    y: originalPosition.y
                )
            } else if onHorizontalBoundary && !onVerticalBoundary {
                // 在水平边界上，参考点在边界上与原点同一垂直线
                referencePoint = CGPoint(
                    x: originalPosition.x,
                    y: originalPosition.y < 0 ? -config.yRadius : config.yRadius
                )
            } else {
                // 完全在中心区域内或在某个角落（应该不会到这里）
                referencePoint = CGPoint(
                    x: clampedX,
                    y: clampedY
                )
            }
            
            // 计算到边界的距离
            distanceToMiddleRegion = distance(from: originalPosition, to: referencePoint)
        }
        
        // 计算方向向量 - 针对不同区域优化
        var direction = CGPoint(x: 0, y: 0)
        
        if isInCornerZone {
            // 角落区域：指向内角的方向
            let dx = referencePoint.x - originalPosition.x
            let dy = referencePoint.y - originalPosition.y
            let mag = sqrt(dx * dx + dy * dy)
            // 确保有非零距离才计算方向
            if mag > 0 {
                direction = CGPoint(x: dx / mag, y: dy / mag)
            }
        } else {
            // 非角落区域：只在相应边界方向上移动
            let onVerticalBoundary = abs(originalPosition.x) > config.xRadius
            let onHorizontalBoundary = abs(originalPosition.y) > config.yRadius
            
            if onVerticalBoundary && !onHorizontalBoundary {
                // 在垂直边界外：只修改X方向
                direction = CGPoint(
                    x: originalPosition.x < 0 ? 1 : -1,  // 向中心方向
                    y: 0
                )
            } else if onHorizontalBoundary && !onVerticalBoundary {
                // 在水平边界外：只修改Y方向
                direction = CGPoint(
                    x: 0,
                    y: originalPosition.y < 0 ? 1 : -1  // 向中心方向
                )
            } else {
                // 其他情况：应该不会到这里
                let dx = referencePoint.x - originalPosition.x
                let dy = referencePoint.y - originalPosition.y
                let mag = sqrt(dx * dx + dy * dy)
                if mag > 0 {
                    direction = CGPoint(x: dx / mag, y: dy / mag)
                }
            }
        }
        
        // 计算位移量
        var translationMagnitude: CGFloat = 0
        
        if region == .fringe {
            // 过渡区域：位移量与大小变化和距离成比例
            let progress = distanceToMiddleRegion / config.fringeWidth
            translationMagnitude = sizeChange * compactnessFactor * progress
        }
        else if region == .outer {
            // 外部区域：基础位移量与大小变化成比例
            translationMagnitude = sizeChange * compactnessFactor
            
            // 计算到fringe区域的距离
            let distanceToFringe = max(0, distanceToMiddleRegion - config.fringeWidth)
            
            if config.gravitation > 0 {
                // 额外引力位移量
                let gravitationalPull = distanceToFringe * config.gravitation
                
                // 添加引力效果到基本位移量
                translationMagnitude += gravitationalPull
                
                // 安全限制，确保不会因引力效果穿过区域边界
                let maxAllowedDisplacement = sizeChange * compactnessFactor + distanceToFringe
                if translationMagnitude > maxAllowedDisplacement {
                    translationMagnitude = maxAllowedDisplacement
                }
            }
        }
        
        // 计算新位置
        let newPosition = CGPoint(
            x: originalPosition.x + direction.x * translationMagnitude,
            y: originalPosition.y + direction.y * translationMagnitude
        )
        
        return newPosition
    }
} 