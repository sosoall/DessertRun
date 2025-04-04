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
    
    /// 图片原始框架位置
    @Published var imageOriginFrame: CGRect? = nil
    
    /// 气泡原始大小
    @Published var bubbleOriginalSize: CGFloat = 0
    
    /// 动画阶段
    @Published var animationPhase: AnimationPhase = .initial
    
    /// 当前正在动画的甜品ID，用于在原始气泡中隐藏图片
    @Published var animatingDessertID: Int? = nil
    
    /// 背景暗化程度 (0-1)
    @Published var backgroundDimLevel: CGFloat = 0
    
    /// 甜品图片位置进度 (0-1)，0表示在原位置，1表示在顶部中心
    @Published var dessertPositionProgress: CGFloat = 0
    
    /// 面板位置进度 (0-1)，0表示在屏幕外，1表示完全显示
    @Published var panelPositionProgress: CGFloat = 0
    
    /// 动画阶段枚举
    enum AnimationPhase {
        case initial            // 初始状态
        case backgroundDimming  // 背景正在变暗
        case dessertMoving      // 甜品图片正在移动
        case panelRevealing     // 面板正在显示
        case panelVisible       // 面板完全可见
        case panelDismissing    // 面板正在关闭
        case dessertReturning   // 甜品图片正在返回
        case backgroundRestoring // 背景正在恢复
    }
    
    /// 选择甜品并开始动画
    func selectDessert(_ dessert: DessertItem, originFrame: CGRect, originalSize: CGFloat, imageFrame: CGRect? = nil) {
        selectedDessert = dessert
        bubbleOriginFrame = originFrame
        bubbleOriginalSize = originalSize
        imageOriginFrame = imageFrame // 存储图片框架
        animationPhase = .backgroundDimming
        animatingDessertID = dessert.id // 设置正在动画的甜品ID
        
        print("【调试-详细】动画状态已更新 - 甜品: \(dessert.name)")
        print("【调试-详细】原始位置: \(originFrame), 宽高: \(originFrame.width)x\(originFrame.height)")
        print("【调试-详细】原始大小: \(originalSize), 中心点: (\(originFrame.midX), \(originFrame.midY))")
        if let imgFrame = imageFrame {
            print("【调试-详细】图片框架: \(imgFrame), 宽高: \(imgFrame.width)x\(imgFrame.height)")
        }
        
        // 更新App状态中的选中甜品
        AppState.shared.selectedDessert = dessert
        
        // 触发动画序列
        startAnimationSequence()
    }
    
    /// 开始动画序列
    private func startAnimationSequence() {
        // 第一步：背景变暗 + title隐藏 + 原气泡中图片隐藏 + 可移动甜品图片出现
        withAnimation(.standardTransition) {
            animationPhase = .backgroundDimming
            backgroundDimLevel = 0.5
        }
        
        // 第二步：甜品图片移动到顶部居中
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.standardTransition) {
                self.animationPhase = .dessertMoving
                self.dessertPositionProgress = 1.0
                self.animationProgress = 1.0 // 保持兼容性
            }
        }
        
        // 第三步：面板升起
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.standardTransition) {
                self.animationPhase = .panelRevealing
                self.panelPositionProgress = 1.0
                self.isShowingExercisePanel = true
            }
            
            // 完成后更新状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.animationPhase = .panelVisible
                print("【调试】动画完成 - 面板完全显示")
            }
        }
    }
    
    /// 关闭面板并返回
    func dismissPanel() {
        // 第一步：面板落下
        withAnimation(.standardReverseTransition) {
            animationPhase = .panelDismissing
            panelPositionProgress = 0.0
        }
        
        // 第二步：甜品图片移动回原位
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.standardReverseTransition) {
                self.animationPhase = .dessertReturning
                self.dessertPositionProgress = 0.0
                self.animationProgress = 0.0 // 保持兼容性
            }
        }
        
        // 第三步：背景恢复 + 其他元素恢复
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.standardReverseTransition) {
                self.animationPhase = .backgroundRestoring
                self.backgroundDimLevel = 0.0
                self.isShowingExercisePanel = false
            }
            
            // 完全恢复初始状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.animationPhase = .initial
                self.selectedDessert = nil
                self.animatingDessertID = nil // 清除正在动画的甜品ID
                
                print("【调试-返回】恢复初始状态")
            }
        }
    }
} 