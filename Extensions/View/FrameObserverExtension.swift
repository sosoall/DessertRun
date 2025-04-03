//
//  FrameObserverExtension.swift
//  DessertRun
//
//  Created by Claude on 2025/4/3.
//

import SwiftUI

// MARK: - 框架观察器扩展

extension View {
    /// 观察视图框架的变化
    /// - Parameter onChange: 框架变化时的回调
    /// - Returns: 带有框架观察的视图
    func observeFrame(onChange: @escaping (CGRect) -> Void) -> some View {
        self.modifier(FrameObserver(onChange: onChange))
    }
}

// MARK: - 框架观察器修饰符

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