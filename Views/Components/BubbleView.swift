//
//  BubbleView.swift
//  DessertRun
//
//  Created by Claude on 2025/3/24.
//

import SwiftUI

/// 扩展Color添加亮度检测
extension Color {
    /// 估算颜色的亮度
    var brightness: CGFloat {
        // 将颜色转换为UIColor以便访问其组件
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // 使用相对亮度公式: 0.2126*R + 0.7152*G + 0.0722*B
        // 这是人眼对不同颜色感知亮度的标准权重
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue
    }
}

/// 气泡背景样式
enum BubbleBackgroundStyle {
    case circle               // 圆形
    case transparent          // 透明
    case custom(Color)        // 自定义颜色
}

/// 可配置的气泡视图
struct BubbleView: View {
    /// 甜品数据
    let item: DessertItem
    
    /// 气泡当前尺寸
    let bubbleSize: CGFloat
    
    /// 到中心的距离
    let distanceToCenter: CGFloat
    
    /// 最大气泡尺寸
    let maxSize: CGFloat
    
    /// 最小气泡尺寸
    let minSize: CGFloat
    
    /// 点击回调
    var onTap: () -> Void = {}
    
    /// 是否显示名称
    var showName: Bool = true
    
    /// 是否显示卡路里
    var showCalories: Bool = true
    
    /// 背景样式
    var backgroundStyle: BubbleBackgroundStyle = .circle
    
    /// 内容边距
    var contentPadding: CGFloat = 8
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                // 图片
                if let bgColor = item.backgroundColor {
                    // 使用背景色设置相应的图标颜色
                    let iconColor: Color = bgColor.brightness > 0.5 ? .black : .white
                    Image(systemName: "cup.and.saucer.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(iconColor)
                        .padding(bubbleSize * 0.25)
                } else {
                    // 使用系统图标作为占位符
                    Image(systemName: "cup.and.saucer.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.pink)
                        .padding(bubbleSize * 0.25)
                }
                
                // 名称标签
                if showName {
                    Text(item.name)
                        .font(.system(size: min(14, bubbleSize * 0.15)))
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                
                // 卡路里标签
                if showCalories {
                    Text("\(item.calories) 卡路里")
                        .font(.system(size: min(10, bubbleSize * 0.1)))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(contentPadding)
            .frame(width: bubbleSize, height: bubbleSize)
            .background(backgroundView)
            .opacity(calculateOpacity())
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Circle())
    }
    
    /// 计算不透明度，基于距离中心远近
    private func calculateOpacity() -> Double {
        let maxDistance = 1000.0 // 可调整此值以改变透明度变化范围
        let distanceRatio = min(distanceToCenter / maxDistance, 1.0)
        return 1.0 - distanceRatio * 0.3 // 最低不透明度为0.7
    }
    
    /// 背景视图，根据背景样式变化
    private var backgroundView: some View {
        Group {
            switch backgroundStyle {
            case .circle:
                Circle()
                    .fill(item.backgroundColor ?? Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                
            case .transparent:
                Circle()
                    .fill(Color.clear)
                
            case .custom(let color):
                Circle()
                    .fill(color)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            }
        }
    }
} 