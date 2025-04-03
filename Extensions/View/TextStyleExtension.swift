//
//  TextStyleExtension.swift
//  DessertRun
//
//  Created by Claude on 2025/4/3.
//

import SwiftUI

// MARK: - 文本样式扩展

extension Text {
    /// 应用标题样式
    func titleStyle() -> some View {
        self
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(.primary)
    }
    
    /// 应用副标题样式
    func subtitleStyle() -> some View {
        self
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
    }
    
    /// 应用正文样式
    func bodyStyle() -> some View {
        self
            .font(.body)
            .foregroundColor(.primary)
    }
    
    /// 应用说明文本样式
    func captionStyle() -> some View {
        self
            .font(.caption)
            .foregroundColor(.secondary)
    }
}

extension View {
    /// 应用可点击文本样式
    func asButton() -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    /// 应用卡片样式
    func cardStyle(cornerRadius: CGFloat = 10) -> some View {
        self
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    /// 应用突出显示效果
    func highlighted(isHighlighted: Bool = true) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHighlighted ? Color.blue : Color.clear, lineWidth: 2)
            )
    }
} 