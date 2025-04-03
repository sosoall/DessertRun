//
//  DessertToExerciseTransition.swift
//  DessertRun
//
//  Created by Claude on 2025/4/10.
//

import SwiftUI

// 注意: 使用 Extensions/View/CornerRadiusExtension.swift 中的共享扩展实现圆角
// 文件底部的扩展已被删除以避免冲突

/// 甜品到运动类型的过渡动画视图
struct DessertToExerciseTransition: View {
    /// 动画状态
    @ObservedObject var animationState: TransitionAnimationState
    
    /// 屏幕尺寸
    let screenSize: CGSize
    
    /// 计算目标框架位置（面板顶部）
    private var targetFrame: CGRect {
        CGRect(
            x: screenSize.width / 2 - 40, 
            y: screenSize.height * 0.08,
            width: 80, 
            height: 80
        )
    }
    
    /// 计算当前动画位置
    private var currentPosition: CGRect {
        let progress = animationState.animationProgress
        
        // 起始位置
        let startX = animationState.bubbleOriginFrame.midX
        let startY = animationState.bubbleOriginFrame.midY
        let startSize = animationState.bubbleOriginalSize
        
        // 目标位置
        let endX = targetFrame.midX
        let endY = targetFrame.midY
        let endSize = CGFloat(80) // 目标大小
        
        // 根据进度插值计算当前位置和大小
        let currentX = startX + (endX - startX) * progress
        let currentY = startY + (endY - startY) * progress
        let currentSize = startSize + (endSize - startSize) * progress
        
        return CGRect(
            x: currentX - currentSize/2,
            y: currentY - currentSize/2,
            width: currentSize,
            height: currentSize
        )
    }
    
    /// 背景不透明度
    private var backgroundOpacity: Double {
        let progress = animationState.animationProgress
        return min(1.0, progress * 1.5) // 让背景更快地变暗
    }
    
    /// 面板偏移
    private var panelOffset: CGFloat {
        let phase = animationState.animationPhase
        
        if phase == .panelRevealing || phase == .panelVisible {
            return 0 // 完全显示
        } else if phase == .bubbleAnimating {
            return screenSize.height * 0.3 // 开始动画时的偏移
        } else if phase == .panelDismissing {
            return screenSize.height // 消失时的偏移
        } else {
            return screenSize.height // 默认隐藏
        }
    }
    
    var body: some View {
        ZStack {
            // 背景遮罩
            Color.black.opacity(backgroundOpacity * 0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    animationState.dismissPanel()
                }
            
            // 甜品动画气泡
            if let dessert = animationState.selectedDessert, 
               animationState.animationPhase != .initial {
                // 修改这部分代码，使用实际甜品图片
                ZStack {
                    Circle()
                        .fill(dessert.backgroundColor ?? Color.white)
                        .frame(width: currentPosition.width, height: currentPosition.height)
                        .position(x: currentPosition.midX, y: currentPosition.midY)
                    
                    // 使用实际甜品图片替代图标
                    if UIImage(named: dessert.imageName) != nil {
                        Image(dessert.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: currentPosition.width * 0.8, height: currentPosition.height * 0.8)
                            .position(x: currentPosition.midX, y: currentPosition.midY)
                    } else {
                        // 仅在找不到图片时使用默认图标
                        Image(systemName: "cup.and.saucer.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white)
                            .padding(currentPosition.width * 0.2)
                            .frame(width: currentPosition.width, height: currentPosition.height)
                            .position(x: currentPosition.midX, y: currentPosition.midY)
                    }
                }
                .shadow(color: Color.black.opacity(0.2), radius: 10)
                .zIndex(1) // 确保甜品图片始终在最上层
            }
            
            // 运动类型选择面板
            VStack {
                Spacer()
                
                ExerciseTypeSelectionPanel(
                    dessert: animationState.selectedDessert,
                    onDismiss: {
                        animationState.dismissPanel()
                    }
                )
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(hex: "faf0dd"))
                        .shadow(color: Color.black.opacity(0.2), radius: 20)
                )
                .offset(y: panelOffset)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: panelOffset)
            }
            .edgesIgnoringSafeArea(.bottom)
            .zIndex(0) // 确保面板在甜品图片下层
        }
    }
}

/// 运动类型选择面板
struct ExerciseTypeSelectionPanel: View {
    /// 选中的甜品
    let dessert: DessertItem?
    
    /// 取消回调
    var onDismiss: () -> Void
    
    /// 是否导航到运动界面
    @State private var navigateToWorkout = false
    
    /// 环境中的应用状态
    @EnvironmentObject var appState: AppState
    
    /// 运动类型列表
    private let exerciseTypes = ExerciseTypeData.getSampleExerciseTypes()
    
    /// 卡路里值
    private var calories: Double {
        guard let selectedDessert = dessert else { return 0 }
        if let calValue = Double(selectedDessert.calories.replacingOccurrences(of: "kcal", with: "")) {
            return calValue
        }
        return 0
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 顶部拖动条
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 60, height: 5)
                .padding(.top, 12)
            
            // 标题
            Text("请选择运动方式")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "61462C"))
                .padding(.top, 5)
            
            // 甜品信息卡片
            if let dessert = dessert {
                HStack {
                    Text("目标甜品 • \(dessert.name)")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(dessert.calories)")
                        .font(.headline)
                        .foregroundColor(Color(hex: "FE2D55"))
                }
                .padding(.horizontal, 20)
            }
            
            // 运动类型列表
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(exerciseTypes) { exerciseType in
                        ExerciseTypeCard(
                            exerciseType: exerciseType,
                            calories: calories,
                            onSelect: {
                                // 选择运动类型并导航到运动界面
                                appState.selectedExerciseType = exerciseType
                                navigateToWorkout = true
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .padding(.horizontal)
        .frame(height: UIScreen.main.bounds.height * 0.75)
        .background(Color(hex: "faf0dd"))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.height > 100 {
                        onDismiss()
                    }
                }
        )
        .navigationDestination(isPresented: $navigateToWorkout) {
            WorkoutView()
                .onAppear {
                    appState.isInWorkoutMode = true
                }
        }
    }
} 