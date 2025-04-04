//
//  ViewUtilityExtensions.swift
//  DessertRun
//
//  Created by Claude on 2025/4/21.
//

import SwiftUI
import UIKit

// MARK: - 视图实用工具扩展

// MARK: - 圆角扩展
extension View {
    /// 为视图添加特定角落的圆角
    func cornerRadiusExt(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerExt(radius: radius, corners: corners))
    }
}

/// 自定义形状：支持特定角落的圆角
struct RoundedCornerExt: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - 视图样式扩展
extension View {
    /// 添加卡片样式阴影
    func cardShadow(radius: CGFloat = 8, yOffset: CGFloat = 4) -> some View {
        self.shadow(color: Color.DessertRun.shadow, radius: radius, x: 0, y: yOffset)
    }
    
    /// 添加标准边框
    func standardBorder(color: Color = Color.DessertRun.border, width: CGFloat = 1) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color, lineWidth: width)
        )
    }
    
    /// 添加标准内边距
    func standardPadding() -> some View {
        self.padding(.horizontal, 20)
            .padding(.vertical, 16)
    }
    
    /// 添加标准背景
    func standardBackground() -> some View {
        self.background(Color.DessertRun.background)
            .cornerRadius(10)
            .cardShadow()
    }
}

// MARK: - 框架观察器扩展
extension View {
    /// 观察视图框架的变化
    /// - Parameter onChange: 框架变化时的回调
    /// - Returns: 带有框架观察的视图
    func observeFrame(onChange: @escaping (CGRect) -> Void) -> some View {
        self.modifier(FrameObserver(onChange: onChange))
    }
}

/// 框架观察器修饰符，用于监测视图框架变化
struct FrameObserver: ViewModifier {
    let onChange: (CGRect) -> Void
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: FramePreferenceKey.self, value: geometry.frame(in: .global))
                        .onPreferenceChange(FramePreferenceKey.self) { frame in
                            onChange(frame)
                        }
                }
            )
    }
}

/// 框架偏好键，用于传递框架信息
struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - 条件修饰符扩展
extension View {
    /// 基于条件应用修饰符
    /// - Parameters:
    ///   - condition: 应用修饰符的条件
    ///   - transform: 条件为真时应用的修饰符
    /// - Returns: 修改后的视图
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// 基于条件应用两种不同的修饰符
    /// - Parameters:
    ///   - condition: 判断条件
    ///   - ifTransform: 条件为真时应用的修饰符
    ///   - elseTransform: 条件为假时应用的修饰符
    /// - Returns: 修改后的视图
    @ViewBuilder func ifElse<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        ifTransform: (Self) -> TrueContent,
        elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
    
    /// 基于可选值应用修饰符
    /// - Parameters:
    ///   - value: 可选值
    ///   - transform: 可选值不为nil时应用的修饰符
    /// - Returns: 修改后的视图
    @ViewBuilder func ifLet<Value, Content: View>(
        _ value: Value?,
        transform: (Self, Value) -> Content
    ) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
} 