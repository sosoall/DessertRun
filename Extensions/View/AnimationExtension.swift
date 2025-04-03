//
//  AnimationExtension.swift
//  DessertRun
//
//  Created by Claude on 2025/4/10.
//

import SwiftUI

/// Animation 扩展，提供统一的动画效果
extension Animation {
    /// 标准过渡动画 - 使用 easeOut，持续时间 0.5 秒
    static var standardTransition: Animation {
        return .easeOut(duration: 0.5)
    }
    
    /// 标准界面动画 - 使用 easeOut，持续时间 0.3 秒
    static var standardInterface: Animation {
        return .easeOut(duration: 0.3)
    }
    
    /// 标准反向过渡动画 - 使用 easeOut，持续时间 0.5 秒
    /// 注意：与 standardTransition 相同，保持一致性
    static var standardReverseTransition: Animation {
        return .easeOut(duration: 0.5)
    }
} 