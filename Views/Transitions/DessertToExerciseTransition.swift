//
//  DessertToExerciseTransition.swift
//  DessertRun
//
//  Created by Claude on 2025/4/10.
//

import SwiftUI

// 注意: 使用 Extensions/View/CornerRadiusExtension.swift 中的共享扩展实现圆角
// 文件底部的扩展已被删除以避免冲突

// 在文件开头添加全局常量
let globalCoordinateSpaceName = "dessertRunGlobalSpace"

/// 甜品到运动类型的过渡动画视图
struct DessertToExerciseTransition: View {
    /// 动画状态
    @ObservedObject var animationState: TransitionAnimationState
    
    /// 屏幕尺寸
    let screenSize: CGSize
    
    /// 全局坐标空间名称
    let globalCoordinateSpaceName = "DessertTransitionCoordinateSpace"
    
    /// 获取当前图片位置
    private var currentPosition: CGRect {
        // 获取原始气泡框架
        let bubbleFrame = animationState.bubbleOriginFrame
        
        // 计算图片在气泡中的精确位置
        // 气泡内图片区域的布局常量
        let contentPadding: CGFloat = 8  // 气泡内部填充
        let imageWidthRatio: CGFloat = 0.9  // 图片宽度占气泡宽度的比例
        let imageHeightRatio: CGFloat = 0.7  // 图片高度占气泡高度的比例
        
        // 计算图片区域的实际位置和大小
        let imageWidth = bubbleFrame.width * imageWidthRatio
        let imageHeight = bubbleFrame.height * imageHeightRatio
        
        // 计算图片中心点相对于气泡左上角的位置
        // 图片垂直居中于图片区域，而图片区域位于气泡上部
        let imageAreaTop = bubbleFrame.minY + contentPadding
        let imageCenterY = imageAreaTop + imageHeight / 2
        let imageCenterX = bubbleFrame.midX
        
        // 构建图片区域的框架
        let startFrame = CGRect(
            x: imageCenterX - imageWidth / 2,
            y: imageCenterY - imageHeight / 2,
            width: imageWidth,
            height: imageHeight
        )
        
        // 构建目标位置：顶部中心，使用固定大小
        let targetSize: CGFloat = 120
        let targetFrame = CGRect(
            x: screenSize.width/2 - targetSize/2,
            y: screenSize.height * 0.08, // 放置在顶部偏上位置
            width: targetSize,
            height: targetSize
        )
        
        // 根据动画进度在起始位置和目标位置之间插值
        let progress = animationState.dessertPositionProgress
        let resultFrame = interpolateFrame(from: startFrame, to: targetFrame, progress: progress)
        
        return resultFrame
    }
    
    /// 获取面板偏移量
    private var panelOffset: CGFloat {
        // 开始时在屏幕外，完全显示时y偏移为0
        let offscreenOffset = screenSize.height
        let onscreenOffset: CGFloat = 0
        
        // 根据面板位置进度计算当前偏移量
        return offscreenOffset - (animationState.panelPositionProgress * (offscreenOffset - onscreenOffset))
    }
    
    /// 在两个矩形框架之间插值
    private func interpolateFrame(from: CGRect, to: CGRect, progress: CGFloat) -> CGRect {
        let x = from.origin.x + (to.origin.x - from.origin.x) * progress
        let y = from.origin.y + (to.origin.y - from.origin.y) * progress
        let width = from.width + (to.width - from.width) * progress
        let height = from.height + (to.height - from.height) * progress
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    /// 背景不透明度
    private var backgroundOpacity: Double {
        let progress = animationState.animationProgress
        return min(1.0, progress * 2.0) // 加快背景变暗速度
    }
    
    var body: some View {
        ZStack {
            // 背景遮罩
            Color.black
                .opacity(animationState.backgroundDimLevel)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // 点击背景区域可关闭面板
                    animationState.dismissPanel()
                }
            
            // 甜品图片 - 从气泡移动到顶部中心
            Group {
                if let dessert = animationState.selectedDessert {
                    // 如果找到甜品图片名称，使用该图片，否则使用默认图标
                    if UIImage(named: dessert.imageName) != nil {
                        Image(dessert.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: currentPosition.width * 0.95, height: currentPosition.height * 0.95)
                            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                    } else {
                        // 默认图标
                        Image(systemName: "cup.and.saucer.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(dessert.backgroundColor ?? .orange)
                            .frame(width: currentPosition.width * 0.95, height: currentPosition.height * 0.95)
                            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                    }
                }
            }
            .position(x: currentPosition.midX, y: currentPosition.midY)
            .zIndex(1) // 确保甜品图片在最上层
            
            // 运动类型选择面板
            VStack(spacing: 0) {
                // 面板顶部 - 标题和关闭按钮
                HStack {
                    Text("选择运动类型")
                        .font(.system(size: 20, weight: .bold))
                    
                    Spacer()
                    
                    Button(action: {
                        animationState.dismissPanel()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                
                // 分隔线
                Divider()
                
                // 面板内容 - 运动类型列表
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(ExerciseType.allCases, id: \.self) { exerciseType in
                            ExerciseTypeRow(
                                exerciseType: exerciseType,
                                selectedDessert: animationState.selectedDessert
                            )
                        }
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: -10)
            .frame(height: min(screenSize.height * 0.7, 500))
            .frame(maxWidth: .infinity)
            .offset(y: panelOffset)
            .animation(.standardTransition, value: panelOffset) // 使用标准过渡动画
            .zIndex(0) // 确保面板在甜品图片下层
        }
        .coordinateSpace(name: globalCoordinateSpaceName)
        .environmentObject(animationState) // 确保所有子视图都能访问animationState
    }
} 