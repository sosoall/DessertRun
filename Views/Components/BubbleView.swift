//
//  BubbleView.swift
//  DessertRun
//
//  Created by Claude on 2025/3/24.
//

import SwiftUI

// 用于跟踪视图框架的PreferenceKey
struct ViewFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

/// 气泡背景样式
enum BubbleBackgroundStyle {
    case squircle            // 圆角正方形
    case transparent         // 透明
    case custom(Color)       // 自定义颜色
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
    
    /// 点击回调，传入气泡位置
    var onTap: (CGRect) -> Void = { _ in }
    
    /// 是否显示名称
    var showName: Bool = true
    
    /// 背景样式
    var backgroundStyle: BubbleBackgroundStyle = .squircle
    
    /// 内容边距
    var contentPadding: CGFloat = 8
    
    /// 图片风格
    var imageStyle: FoodImageStyle = .regular
    
    // 用于跟踪视图框架
    @State private var viewFrame: CGRect = .zero
    
    /// 背景视图，根据背景样式变化
    @ViewBuilder
    private var backgroundView: some View {
        switch backgroundStyle {
        case .squircle:
            RoundedRectangle(cornerRadius: bubbleSize * 0.25, style: .continuous)
                .fill(Color.white.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: bubbleSize * 0.25, style: .continuous)
                        .stroke(Color.white.opacity(0.9), lineWidth: 0.5)
                )
                .shadow(color: Color(hex: "7E4A4A").opacity(0.15), radius: 8, x: 5, y: 5)
                .shadow(color: Color(hex: "7E4A4A").opacity(0.2), radius: 4, x: 3, y: 3)
            
        case .transparent:
            RoundedRectangle(cornerRadius: bubbleSize * 0.25, style: .continuous)
                .fill(Color.clear)
            
        case .custom(let color):
            RoundedRectangle(cornerRadius: bubbleSize * 0.25, style: .continuous)
                .fill(color)
                .overlay(
                    RoundedRectangle(cornerRadius: bubbleSize * 0.25, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: Color(hex: "7E4A4A").opacity(0.15), radius: 7, x: 5, y: 5)
        }
    }
    
    var body: some View {
        // 放弃Button，改用VStack和独立的点击手势
        GeometryReader { geometry in
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
                            .padding(bubbleSize * 0.02) // 减少内边距，让图片更大（之前是0.03）
                            .shadow(color: Color(hex: "7E4A4A").opacity(0.15), radius: 5, x: 2, y: 2)
                            .background(
                                GeometryReader { imageGeo in
                                    Color.clear
                                        .onAppear {
                                            // 记录图片区域的相对位置
                                            let imageFrame = imageGeo.frame(in: .named("bubbleCoordinateSpace"))
                                            print("【调试-位置】图片区域位置: \(imageFrame)")
                                        }
                                }
                            )
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
                .clipShape(RoundedRectangle(cornerRadius: bubbleSize * 0.25, style: .continuous))
                .frame(width: bubbleSize * 0.9, height: bubbleSize * 0.7) // 明确给图片区域设置大小
                
                // 名称标签
                if showName {
                    VStack(spacing: 0) {
                        Text(item.name)
                            .font(.system(size: min(14, bubbleSize * 0.15)))
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.5))
                    )
                    // 只在中心区域显示名称，距离中心越远越透明
                    .opacity(calculateNameOpacity())
                }
            }
            .padding(contentPadding)
            .frame(width: bubbleSize, height: bubbleSize)
            .background(backgroundView)
            .opacity(calculateOpacity())
            .blur(radius: calculateBlurRadius()) // 将模糊应用于整个气泡
            .contentShape(RoundedRectangle(cornerRadius: bubbleSize * 0.25, style: .continuous))
            // 使用简单的点击手势，优先级较低
            .onTapGesture {
                // 获取气泡在全局坐标系中的位置
                let bubbleFrame = geometry.frame(in: .global)
                
                // 计算图片区域的精确位置
                // 图片区域在气泡中的大致位置：顶部，高度约占70%，扣除padding
                let imageFrameHeight = bubbleSize * 0.7
                let imageY = bubbleFrame.minY + contentPadding + imageFrameHeight / 2
                
                // 创建图片区域的框架，保持原始气泡的宽度
                let imageFrame = CGRect(
                    x: bubbleFrame.minX,
                    y: imageY - imageFrameHeight / 2,
                    width: bubbleFrame.width,
                    height: imageFrameHeight
                )
                
                print("【调试】气泡[\(item.name)]被点击")
                print("【调试】气泡框架: \(bubbleFrame)")
                print("【调试】图片框架: \(imageFrame)")
                print("【调试】图片中心: (\(imageFrame.midX), \(imageFrame.midY))")
                
                // 传递在全局坐标空间中的位置，使坐标更一致
                onTap(imageFrame) // 传递图片区域的框架而非整个气泡
            }
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
            .coordinateSpace(name: "bubbleCoordinateSpace")
        }
        .frame(width: bubbleSize, height: bubbleSize)
        .coordinateSpace(name: globalCoordinateSpaceName) // 使用全局共享的坐标空间
    }
    
    /// 计算名称标签的透明度，基于到中心的距离
    private func calculateNameOpacity() -> Double {
        // 定义中心区域的半径 (占最大半径的比例)
        let centerZoneRatio: CGFloat = 0.3
        
        // 将距离归一化为0-1的比例 (distanceToCenter / 最大可能距离)
        // 假设最大距离是屏幕对角线的一半
        let normalizedDistance = distanceToCenter / (maxSize * 2)
        
        // 如果在中心区域内，完全显示
        if normalizedDistance < centerZoneRatio {
            return 1.0
        }
        // 如果超出中心区域但在过渡区域内，逐渐降低透明度
        else if normalizedDistance < centerZoneRatio * 2 {
            // 计算从1到0的线性过渡
            return Double(1.0 - (normalizedDistance - centerZoneRatio) / centerZoneRatio)
        }
        // 如果远离中心，完全隐藏
        else {
            return 0.0
        }
    }
    
    /// 计算不透明度，基于距离中心远近和区域
    private func calculateOpacity() -> Double {
        // 只有白色方形气泡才应用透明度变化
        guard case .squircle = backgroundStyle else { return 1.0 }
        
        // 根据尺寸比例计算不透明度
        // 中心区域保持完全不透明，外围区域逐渐变淡
        let sizeRatio = bubbleSize / maxSize
        
        // 当气泡尺寸超过90%，保持完全不透明
        if sizeRatio > 0.9 {
            return 1.0
        }
        // 当气泡尺寸在60%-90%之间，逐渐降低不透明度到0.7
        else if sizeRatio > 0.6 {
            let t = (sizeRatio - 0.6) / 0.3 // 映射0.6-0.9到0-1
            return 0.7 + (t * 0.3) // 映射0-1到0.7-1.0
        } 
        // 当气泡尺寸小于60%，进一步降低不透明度到0.4
        else {
            let t = min(max(sizeRatio / 0.6, 0), 1) // 映射0-0.6到0-1
            return 0.4 + (t * 0.3) // 映射0-1到0.4-0.7
        }
    }
    
    /// 计算气泡模糊程度，基于尺寸比例
    private func calculateBlurRadius() -> CGFloat {
        // 只有白色方形气泡才应用模糊效果
        guard case .squircle = backgroundStyle else { return 0 }
        
        // 最大模糊半径
        let maxBlur: CGFloat = 3.0
        
        // 根据尺寸比例计算模糊度
        let sizeRatio = bubbleSize / maxSize
        
        // 当气泡尺寸超过90%，没有模糊
        if sizeRatio > 0.9 {
            return 0
        }
        // 当气泡尺寸在70%-90%之间，轻微模糊
        else if sizeRatio > 0.7 {
            let t = 1.0 - ((sizeRatio - 0.7) / 0.2) // 映射0.7-0.9到1-0
            return maxBlur * 0.3 * t
        } 
        // 当气泡尺寸在50%-70%之间，中等模糊
        else if sizeRatio > 0.5 {
            let t = (sizeRatio - 0.5) / 0.2 // 映射0.5-0.7到0-1
            return maxBlur * (0.3 + (1.0 - t) * 0.4) // 从0.7倍模糊到0.3倍模糊
        } 
        // 当气泡尺寸小于50%，最大模糊
        else {
            let t = max(sizeRatio / 0.5, 0) // 映射0-0.5到0-1
            return maxBlur * (1.0 - t * 0.3) // 从最大模糊到0.7倍模糊
        }
    }
} 