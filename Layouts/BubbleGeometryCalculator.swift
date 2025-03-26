//
//  BubbleGeometryCalculator.swift
//  DessertRun
//
//  Created by Claude on 2025/3/24.
//

import SwiftUI

/// 气泡布局的几何计算工具类
struct BubbleGeometryCalculator {
    // 调试开关
    static var enableDebugLog = true
    static var debugItemName: String? = "红丝绒"
    
    // 调试信息收集
    private static var debugLogs: [String] = []
    
    /// 重置调试日志
    static func resetDebugLogs() {
        debugLogs = []
    }
    
    /// 打印所有收集的调试日志
    static func printCollectedLogs() {
        guard enableDebugLog && !debugLogs.isEmpty else { return }
        
        print("\n======== 气泡调试信息 ========")
        debugLogs.forEach { print($0) }
        print("======== 调试信息结束 ========\n")
        
        // 打印后清空日志
        resetDebugLogs()
    }
    
    /// 收集调试信息
    /// - Parameters:
    ///   - message: 调试信息
    ///   - itemName: 气泡名称
    static func debugLog(_ message: String, itemName: String? = nil) {
        if enableDebugLog && (itemName == nil || itemName == debugItemName) {
            // 收集信息而不是立即打印
            let logMessage = "DEBUG[\(itemName ?? "Unknown")]: \(message)"
            debugLogs.append(logMessage)
        }
    }
    
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
    ///   - itemName: 可选的气泡名称，用于调试
    /// - Returns: 所在区域
    static func determineRegion(position: CGPoint, config: BubbleLayoutConfiguration, itemName: String? = nil) -> BubbleRegion {
        debugLog("判断区域 - 位置: \(position)", itemName: itemName)
        debugLog("中心区域大小 - xRadius: \(config.xRadius), yRadius: \(config.yRadius)", itemName: itemName)
        debugLog("过渡区宽度 - fringeWidth: \(config.fringeWidth)", itemName: itemName)
        
        // 检查是否在角落区域
        let isInCornerZone = abs(position.x) > config.xRadius && abs(position.y) > config.yRadius
        debugLog("是否在角落区域: \(isInCornerZone)", itemName: itemName)
        
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
            debugLog("角落区域 - 到内角的距离: \(distanceToInternalCorner)", itemName: itemName)
            
            // 根据到内角的距离判断区域
            if distanceToInternalCorner < config.cornerRadius {
                region = .center
                debugLog("在中心区域内 (角落判定)", itemName: itemName)
            } else if distanceToInternalCorner < config.cornerRadius + config.fringeWidth {
                region = .fringe
                debugLog("在过渡区域内 (角落判定)", itemName: itemName)
            } else {
                region = .outer
                debugLog("在外部区域 (角落判定)", itemName: itemName)
            }
        } else {
            // 如果不在角落区域，使用坐标最大值计算
            let distanceToCenter = max(abs(position.x), abs(position.y))
            debugLog("非角落区域 - 到中心的距离: \(distanceToCenter)", itemName: itemName)
            
            // 判断区域
            if abs(position.x) <= config.xRadius && abs(position.y) <= config.yRadius {
                region = .center
                debugLog("在中心区域内 (非角落判定)", itemName: itemName)
            } else if distanceToCenter < (abs(position.x) > config.xRadius ? config.xRadius + config.fringeWidth : config.yRadius + config.fringeWidth) {
                region = .fringe
                debugLog("在过渡区域内 (非角落判定)", itemName: itemName)
            } else {
                region = .outer
                debugLog("在外部区域 (非角落判定)", itemName: itemName)
            }
        }
        
        debugLog("最终判定区域: \(region)", itemName: itemName)
        return region
    }
    
    /// 计算气泡尺寸
    /// - Parameters:
    ///   - position: 气泡位置
    ///   - region: 区域
    ///   - config: 布局配置
    ///   - itemName: 可选的气泡名称，用于调试
    /// - Returns: 计算后的尺寸
    static func calculateBubbleSize(position: CGPoint, region: BubbleRegion, config: BubbleLayoutConfiguration, itemName: String? = nil) -> CGFloat {
        debugLog("计算尺寸 - 位置: \(position), 区域: \(region)", itemName: itemName)
        
        switch region {
        case .center:
            debugLog("中心区域 - 使用最大尺寸: \(config.maxSize)", itemName: itemName)
            return config.maxSize
        case .outer:
            debugLog("外部区域 - 使用最小尺寸: \(config.minSize)", itemName: itemName)
            return config.minSize
        case .fringe:
            // 计算到中心区域边界的距离
            let distanceToMiddleRegion = calculateDistanceToMiddleRegion(position: position, config: config)
            debugLog("过渡区域 - 到中心边界的距离: \(distanceToMiddleRegion)", itemName: itemName)
            
            // 线性进度计算 (规范中的公式)
            let progress = min(distanceToMiddleRegion / config.fringeWidth, 1.0)
            debugLog("线性进度: \(progress)", itemName: itemName)
            
            // 计算大小 (使用线性插值)
            let size = config.maxSize + progress * (config.minSize - config.maxSize)
            debugLog("计算后的尺寸: \(size)", itemName: itemName)
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
    ///   - itemName: 可选的气泡名称，用于调试
    /// - Returns: 调整后的位置
    static func calculateBubblePosition(
        originalPosition: CGPoint,
        region: BubbleRegion,
        config: BubbleLayoutConfiguration,
        itemName: String? = nil
    ) -> CGPoint {
        debugLog("计算位置调整 - 原始位置: \(originalPosition), 区域: \(region)", itemName: itemName)
        
        guard config.compact else {
            debugLog("未启用紧凑模式，保持原位", itemName: itemName)
            return originalPosition
        }
        
        // 中心区域不需要调整
        if region == .center {
            debugLog("中心区域，保持原位", itemName: itemName)
            return originalPosition
        }
        
        // 计算到中心区域边界的参考点
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
            debugLog("角落参考点: \(referencePoint), 距离: \(distanceToMiddleRegion)", itemName: itemName)
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
                debugLog("垂直边界参考点: \(referencePoint)", itemName: itemName)
            } else if onHorizontalBoundary && !onVerticalBoundary {
                // 在水平边界上，参考点在边界上与原点同一垂直线
                referencePoint = CGPoint(
                    x: originalPosition.x,
                    y: originalPosition.y < 0 ? -config.yRadius : config.yRadius
                )
                debugLog("水平边界参考点: \(referencePoint)", itemName: itemName)
            } else {
                // 完全在中心区域内或在某个角落（应该不会到这里）
                referencePoint = CGPoint(
                    x: clampedX,
                    y: clampedY
                )
                debugLog("特殊情况参考点: \(referencePoint)", itemName: itemName)
            }
            
            // 计算到边界的距离
            distanceToMiddleRegion = distance(from: originalPosition, to: referencePoint)
            debugLog("到边界距离: \(distanceToMiddleRegion)", itemName: itemName)
        }
        
        // 计算方向向量 - 从原始位置指向参考点
        let dx = referencePoint.x - originalPosition.x
        let dy = referencePoint.y - originalPosition.y
        let mag = sqrt(dx * dx + dy * dy)
        // 确保有非零距离才计算方向
        let direction = mag > 0 
            ? CGPoint(x: dx / mag, y: dy / mag) 
            : CGPoint(x: 0, y: 0)
        
        debugLog("方向向量: \(direction)", itemName: itemName)
        
        // 紧凑模式基本位移量
        let baseDisplacement = config.maxSize - config.minSize
        
        // 计算位移量
        var translationMagnitude: CGFloat = 0
        
        if region == .fringe {
            // 过渡区域中，位移量随进度变化（线性过渡）
            let progress = distanceToMiddleRegion / config.fringeWidth
            translationMagnitude = progress * baseDisplacement
            debugLog("过渡区域 - 进度: \(progress), 位移量: \(translationMagnitude)", itemName: itemName)
        }
        else if region == .outer {
            // 计算到fringe区域的距离
            let distanceToFringe = max(0, distanceToMiddleRegion - config.fringeWidth)
            debugLog("到fringe区域的距离: \(distanceToFringe)", itemName: itemName)
            
            // 基本位移量 - 保持与fringe区域边界的连续性
            // 这是fringe区域在border处的位移量
            translationMagnitude = baseDisplacement
            
            if config.gravitation > 0 {
                // 额外引力位移量
                let gravitationalPull = distanceToFringe * config.gravitation
                debugLog("引力额外位移量: \(gravitationalPull)", itemName: itemName)
                
                // 添加引力效果到基本位移量
                translationMagnitude += gravitationalPull
                
                // 安全限制，确保不会因引力效果穿过区域边界
                let maxAllowedDisplacement = baseDisplacement + distanceToFringe
                if translationMagnitude > maxAllowedDisplacement {
                    translationMagnitude = maxAllowedDisplacement
                    debugLog("限制引力位移量: \(translationMagnitude)", itemName: itemName)
                }
            }
            
            debugLog("外部区域 - 最终位移量: \(translationMagnitude)", itemName: itemName)
        }
        
        // 计算新位置
        let newPosition = CGPoint(
            x: originalPosition.x + direction.x * translationMagnitude,
            y: originalPosition.y + direction.y * translationMagnitude
        )
        
        debugLog("最终位置调整: \(newPosition)", itemName: itemName)
        return newPosition
    }
} 