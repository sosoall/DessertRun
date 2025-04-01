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
    
    /// 背景样式
    var backgroundStyle: BubbleBackgroundStyle = .circle
    
    /// 内容边距
    var contentPadding: CGFloat = 8
    
    /// 图片风格
    var imageStyle: FoodImageStyle = .regular
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // 美食图片
                ZStack {
                    // 获取对应风格的图片名称
                    let imageName = item.getImageName(for: imageStyle)
                    
                    if UIImage(named: imageName) != nil {
                        // 如果可以加载到图片，则显示真实图片
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .padding(bubbleSize * 0.15)
                    } else {
                        // 如果无法加载图片，显示占位图标和分类图标
                        Image(systemName: item.category.icon)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(item.backgroundColor != nil && item.backgroundColor!.brightness > 0.5 ? .black : .white)
                            .padding(bubbleSize * 0.25)
                            .overlay(
                                Text(item.category.rawValue)
                                    .font(.system(size: min(10, bubbleSize * 0.1)))
                                    .foregroundColor(item.backgroundColor != nil && item.backgroundColor!.brightness > 0.5 ? .black : .white)
                                    .padding(4)
                                    .background(
                                        Capsule()
                                            .fill(Color.black.opacity(0.2))
                                    )
                                    .padding(4),
                                alignment: .bottomTrailing
                            )
                    }
                }
                .clipShape(Circle())
                
                // 名称标签
                if showName {
                    VStack(spacing: 0) {
                        Text(item.name)
                            .font(.system(size: min(14, bubbleSize * 0.15)))
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        
                        Text(item.calories + " 卡路里")
                            .font(.system(size: min(10, bubbleSize * 0.1)))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .opacity(bubbleSize > maxSize * 0.5 ? 1 : 0)
                    }
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
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                
            case .transparent:
                Circle()
                    .fill(Color.clear)
                
            case .custom(let color):
                Circle()
                    .fill(color)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            }
        }
    }
} 