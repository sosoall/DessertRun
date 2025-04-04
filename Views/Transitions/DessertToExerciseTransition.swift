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
    
    /// 应用状态
    @EnvironmentObject var appState: AppState
    
    /// 屏幕尺寸
    let screenSize: CGSize
    
    /// 全局坐标空间名称
    let globalCoordinateSpaceName = "DessertTransitionCoordinateSpace"
    
    /// 导航到运动页面
    @State private var navigateToWorkout = false
    
    /// 获取当前图片位置
    private var currentPosition: CGRect {
        // 获取原始气泡框架
        let bubbleFrame = animationState.bubbleOriginFrame
        
        // 直接使用传递的图片框架作为起始位置
        // 这个框架包含了气泡中图片的实际大小和位置（会随拖动位置缩放）
        let imageFrameFromBubble = animationState.imageOriginFrame ?? bubbleFrame
        
        // 构建起始图片框架，直接使用实际测量的图片框架
        let startFrame = imageFrameFromBubble
        
        // 输出计算的起始框架
        print("【调试-计算】起始框架: \(startFrame), 中心点: \(CGPoint(x: startFrame.midX, y: startFrame.midY))")
        
        // 构建目标位置：顶部中心，使用固定的120大小
        let targetSize: CGFloat = 120  // 固定的目标图片尺寸
        let targetFrame = CGRect(
            x: screenSize.width/2 - targetSize/2,
            y: screenSize.height * 0.07, // 放置在顶部位置
            width: targetSize,
            height: targetSize
        )
        
        // 输出计算的目标框架
        print("【调试-计算】目标框架: \(targetFrame)")
        
        // 根据动画进度在起始位置和目标位置之间插值
        let progress = animationState.dessertPositionProgress
        let resultFrame = interpolateFrame(from: startFrame, to: targetFrame, progress: progress)
        
        // 输出结果框架
        print("【调试-计算】当前框架: \(resultFrame), 进度: \(progress)")
        
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
    
    /// 卡路里值
    private var calories: Double {
        guard let selectedDessert = animationState.selectedDessert else { return 0 }
        if let calValue = Double(selectedDessert.calories.replacingOccurrences(of: "kcal", with: "")) {
            return calValue
        }
        return 0
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
            dessertImageView
                .position(x: currentPosition.midX, y: currentPosition.midY)
                .zIndex(1) // 确保甜品图片在最上层
            
            // 运动类型选择面板
            panelView
                .frame(height: screenSize.height * 0.75)
                .frame(maxWidth: .infinity)
                .offset(y: panelOffset)
                .animation(.standardTransition, value: panelOffset) // 使用标准过渡动画
                .zIndex(0) // 确保面板在甜品图片下层
            
            // 右上角关闭按钮
            closeButton
                .zIndex(2) // 确保关闭按钮在最上层
        }
        .coordinateSpace(name: globalCoordinateSpaceName)
        .environmentObject(animationState) // 确保所有子视图都能访问animationState
        .navigationDestination(isPresented: $navigateToWorkout) {
            WorkoutView()
                .onAppear {
                    // 进入运动模式 - 使用AppState而不是animationState
                    appState.isInWorkoutMode = true
                }
        }
    }
    
    // MARK: - 提取的子视图
    
    /// 甜品图片视图
    private var dessertImageView: some View {
        Group {
            if let dessert = animationState.selectedDessert {
                // 如果找到甜品图片名称，使用该图片，否则使用默认图标
                if UIImage(named: dessert.imageName) != nil {
                    Image(dessert.imageName)
                        .resizable()
                        .scaledToFit() // 使用scaledToFit保持图片比例
                        .frame(width: currentPosition.width, height: currentPosition.height)
                        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                } else {
                    // 默认图标
                    Image(systemName: "cup.and.saucer.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(dessert.backgroundColor ?? .orange)
                        .frame(width: currentPosition.width, height: currentPosition.height)
                        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                }
            }
        }
    }
    
    /// 面板视图
    private var panelView: some View {
        ZStack(alignment: .top) {
            // 背景层 - 延伸到底部
            VStack {
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: -10)
            .ignoresSafeArea(.container, edges: .bottom) // 关键点：忽略底部安全区域
            
            // 内容层
            VStack(spacing: 0) {
                // 顶部拖动条
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 60, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                // 标题区域
                titleView
                
                // 请选择运动类型标题
                Text("请选择运动类型")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(hex: "757575"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                
                // 分隔线
                Divider()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                
                // 面板内容 - 运动类型列表
                exerciseListView
            }
            .padding(.bottom, 30) // 使用固定的底部填充，避免使用废弃的API
        }
    }
    
    /// 标题视图
    private var titleView: some View {
        Group {
            if let dessert = animationState.selectedDessert {
                VStack(alignment: .center, spacing: 0) {
                    Text("运动目标：\(dessert.name)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    Text("（约\(Int(calories))卡路里）")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .padding(.top, 5)
                }
                .padding(.bottom, 25)
            }
        }
    }
    
    /// 运动列表视图
    private var exerciseListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(ExerciseType.allCases, id: \.self) { exerciseType in
                    exerciseRowView(for: exerciseType)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    /// 单个运动类型行视图
    private func exerciseRowView(for exerciseType: ExerciseType) -> some View {
        Button(action: {
            // 选择运动类型并导航到运动页面 - 使用AppState而不是animationState
            appState.selectedExerciseType = exerciseType
            navigateToWorkout = true
        }) {
            HStack {
                // 左侧图标
                exerciseIconView(for: exerciseType)
                
                // 中间内容
                exerciseDetailView(for: exerciseType)
                
                Spacer()
                
                // 右侧箭头
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(hex: "F1F1F1"))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    /// 运动图标视图
    private func exerciseIconView(for exerciseType: ExerciseType) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(exerciseType.backgroundColor)
                .frame(width: 70, height: 70)
            
            Image(systemName: exerciseType.iconName)
                .resizable()
                .scaledToFit()
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
        }
    }
    
    /// 运动详情视图
    private func exerciseDetailView(for exerciseType: ExerciseType) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exerciseType.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(exerciseType.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundColor(Color(hex: "FE2D55"))
                
                Text(formatTime(exerciseType.estimatedTimeToComplete(calories: calories)))
                    .font(.caption)
                    .foregroundColor(Color(hex: "FE2D55"))
                    .fontWeight(.semibold)
            }
        }
        .padding(.leading, 8)
    }
    
    /// 关闭按钮视图
    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    animationState.dismissPanel()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                }
                .padding(.trailing, 16)
                .padding(.top, 20)
                .opacity(animationState.panelPositionProgress)
            }
            Spacer()
        }
    }
    
    /// 格式化时间
    private func formatTime(_ minutes: Double) -> String {
        if minutes < 1 {
            return "不到1分钟"
        } else if minutes < 60 {
            return "约\(Int(minutes.rounded()))分钟"
        } else {
            let hours = Int(minutes / 60)
            let mins = Int(minutes.truncatingRemainder(dividingBy: 60))
            
            if mins == 0 {
                return "约\(hours)小时"
            } else {
                return "约\(hours)小时\(mins)分钟"
            }
        }
    }
} 