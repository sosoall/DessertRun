//
//  TransitionAnimationState.swift
//  DessertRun
//
//  Created by Claude on 2025/4/10.
//

import SwiftUI

/// 过渡动画状态管理
class TransitionAnimationState: ObservableObject {
    /// 选中的甜品
    @Published var selectedDessert: DessertItem?
    
    /// 是否显示运动类型面板
    @Published var isShowingExercisePanel: Bool = false
    
    /// 动画进度（0-1）
    @Published var animationProgress: CGFloat = 0
    
    /// 气泡原始框架位置
    @Published var bubbleOriginFrame: CGRect = .zero
    
    /// 气泡原始大小
    @Published var bubbleOriginalSize: CGFloat = 0
    
    /// 动画阶段
    @Published var animationPhase: AnimationPhase = .initial
    
    /// 动画阶段枚举
    enum AnimationPhase {
        case initial          // 初始状态
        case bubbleSelected   // 气泡被选中
        case bubbleAnimating  // 气泡正在动画
        case panelRevealing   // 面板正在显示
        case panelVisible     // 面板完全可见
        case panelDismissing  // 面板正在关闭
    }
    
    /// 选择甜品并开始动画
    func selectDessert(_ dessert: DessertItem, originFrame: CGRect, originalSize: CGFloat) {
        selectedDessert = dessert
        bubbleOriginFrame = originFrame
        bubbleOriginalSize = originalSize
        animationPhase = .bubbleSelected
        
        print("【调试-详细】动画状态已更新 - 甜品: \(dessert.name)")
        print("【调试-详细】原始位置: \(originFrame), 宽高: \(originFrame.width)x\(originFrame.height)")
        print("【调试-详细】原始大小: \(originalSize), 中心点: (\(originFrame.midX), \(originFrame.midY))")
        
        // 更新App状态中的选中甜品
        AppState.shared.selectedDessert = dessert
        
        // 触发动画序列
        startAnimationSequence()
    }
    
    /// 开始动画序列
    private func startAnimationSequence() {
        // 使用easeOut动画，开始快结束慢
        withAnimation(.easeOut(duration: 0.5)) {
            animationPhase = .bubbleAnimating
            animationProgress = 1.0 // 直接到达最终位置
            isShowingExercisePanel = true
            
            print("【调试】动画开始 - 直接到最终位置，使用easeOut效果")
            print("【调试】进度: \(animationProgress)")
        }
        
        // 完成后更新状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.animationPhase = .panelVisible
        }
    }
    
    /// 关闭面板并返回
    func dismissPanel() {
        // 使用easeIn动画，开始慢结束快（返回时应该相反）
        withAnimation(.easeIn(duration: 0.5)) {
            animationPhase = .panelDismissing
            animationProgress = 0.0 // 直接回到起始位置
            isShowingExercisePanel = false
            
            print("【调试-返回】开始返回 - 直接回原位，使用easeIn效果")
            print("【调试-返回】进度: \(animationProgress)")
        }
        
        // 完全恢复初始状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.animationPhase = .initial
            self.selectedDessert = nil
            
            print("【调试-返回】恢复初始状态")
        }
    }
} 