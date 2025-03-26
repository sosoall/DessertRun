//
//  BubbleState.swift
//  DessertRun
//
//  Created by Claude on 2025/3/24.
//

import SwiftUI

/// 气泡所在区域枚举
enum BubbleRegion {
    case center    // 中心区域 - 最大尺寸
    case fringe    // 过渡区域 - 尺寸在最大和最小之间
    case outer     // 外部区域 - 最小尺寸
}

/// 气泡状态模型，包含位置、大小等信息
struct BubbleState {
    /// 当前尺寸
    var size: CGFloat
    
    /// 当前位置
    var position: CGPoint
    
    /// 原始网格位置（未应用任何调整）
    var originalPosition: CGPoint
    
    /// 缩放比例
    var scale: CGFloat
    
    /// 到中心的距离
    var distanceToCenter: CGFloat
    
    /// 所在区域
    var region: BubbleRegion
    
    /// 默认初始化
    init(
        size: CGFloat = 0,
        position: CGPoint = .zero,
        originalPosition: CGPoint = .zero,
        scale: CGFloat = 1.0,
        distanceToCenter: CGFloat = 0,
        region: BubbleRegion = .center
    ) {
        self.size = size
        self.position = position
        self.originalPosition = originalPosition
        self.scale = scale
        self.distanceToCenter = distanceToCenter
        self.region = region
    }
} 