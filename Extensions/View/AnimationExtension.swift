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
        .spring(response: 0.5, dampingFraction: 0.8)
    }
    
    /// 标准界面动画 - 使用 easeOut，持续时间 0.3 秒
    static var standardInterface: Animation {
        .easeInOut(duration: 0.35)
    }
    
    /// 标准反向过渡动画 - 使用 easeOut，持续时间 0.5 秒
    /// 注意：与 standardTransition 相同，保持一致性
    static var standardReverseTransition: Animation {
        .spring(response: 0.4, dampingFraction: 0.7)
    }
    
    /// 快速界面动画 - 0.2秒，缓入缓出
    static var quickInterface: Animation {
        .easeInOut(duration: 0.2)
    }
    
    /// 延迟过渡动画 - 0.5秒，0.2秒延迟
    static var delayedTransition: Animation {
        .spring(response: 0.5, dampingFraction: 0.8)
            .delay(0.2)
    }
}

/// 用于动画的视图扩展
extension View {
    /// 应用标准界面动画到视图变化
    func withStandardAnimation<Value: Equatable>(value: Value) -> some View {
        self.animation(.standardInterface, value: value)
    }
    
    /// 应用标准过渡动画到视图变化
    func withTransitionAnimation<Value: Equatable>(value: Value) -> some View {
        self.animation(.standardTransition, value: value)
    }
    
    /// 应用导航栏隐藏/显示动画
    func animatedNavBarHidden(_ hidden: Bool) -> some View {
        self.navigationBarHidden(hidden)
            .animation(.standardInterface, value: hidden)
    }
    
    /// 应用动画偏移量
    func animatedOffset(x: CGFloat = 0, y: CGFloat = 0) -> some View {
        self.offset(x: x, y: y)
            .animation(.standardInterface, value: x)
            .animation(.standardInterface, value: y)
    }
} 