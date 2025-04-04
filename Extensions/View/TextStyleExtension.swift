//
//  TextStyleExtension.swift
//  DessertRun
//
//  Created by Claude on 2025/4/3.
//

import SwiftUI

/// 文本样式扩展
extension Font {
    /// DessertRun应用字体样式
    struct DessertRun {
        /// 大标题 - 32pt，粗体
        static var largeTitle: Font {
            .system(size: 32, weight: .semibold)
        }
        
        /// 普通标题 - 20pt，粗体
        static var title: Font {
            .system(size: 20, weight: .semibold)
        }
        
        /// 正文文本 - 15pt，常规
        static var body: Font {
            .system(size: 15, weight: .regular)
        }
        
        /// 描述文本 - 14pt，常规
        static var caption: Font {
            .system(size: 14, weight: .regular)
        }
    }
}

/// 文本样式修饰符
extension View {
    /// 应用大标题样式
    func largeTitleStyle() -> some View {
        self.font(Font.DessertRun.largeTitle)
            .foregroundColor(Color("TextPrimary"))
    }
    
    /// 应用标题样式
    func titleStyle() -> some View {
        self.font(Font.DessertRun.title)
            .foregroundColor(Color("TextPrimary"))
    }
    
    /// 应用正文样式
    func bodyStyle() -> some View {
        self.font(Font.DessertRun.body)
            .foregroundColor(Color("TextSecondary"))
            .lineSpacing(2)
    }
    
    /// 应用描述文本样式
    func captionStyle() -> some View {
        self.font(Font.DessertRun.caption)
            .foregroundColor(Color("TextSecondary"))
    }
    
    /// 应用强调文本样式
    func accentTextStyle() -> some View {
        self.font(Font.DessertRun.body)
            .foregroundColor(Color("AccentColor"))
            .fontWeight(.semibold)
    }
    
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