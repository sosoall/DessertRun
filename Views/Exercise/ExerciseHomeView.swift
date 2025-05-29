//
//  ExerciseHomeView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

/// 运动模块主页面
struct ExerciseHomeView: View {
    // 全局应用状态
    @EnvironmentObject var appState: AppState
    
    // 动画状态
    @StateObject private var animationState = TransitionAnimationState()
    
    // 是否正在拖动气泡
    @State private var isDragging: Bool = false
    
    // 拖动状态回调
    let onDraggingChanged: ((Bool) -> Void)?
    
    // 退出回调
    let onExit: (() -> Void)?
    
    // 初始化函数
    init(onDraggingChanged: ((Bool) -> Void)? = nil, onExit: (() -> Void)? = nil) {
        self.onDraggingChanged = onDraggingChanged
        self.onExit = onExit
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color(hex: "FFFFFF").ignoresSafeArea()
                
                // 甜品网格视图
                DessertGridView(
                    animationState: animationState,
                    onDragStateChanged: { isDragging in
                        withAnimation(.standardInterface) {
                            self.isDragging = isDragging
                            // 调用外部回调
                            onDraggingChanged?(isDragging)
                        }
                    }
                )
                
                // 顶部和底部覆盖层（确保在气泡上方）
                VStack {
                    // 顶部标题区域（带白色背景的容器）
                    HStack {
                        // 退出按钮（仅在独立模式下显示）
                        if onExit != nil {
                            Button(action: {
                                onExit?()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "212121"))
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Color.gray.opacity(0.1)))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            // 统一提示语
                            Text("选择喜欢的美食&运动完成打卡，解锁美食券吧！")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "212121"))

                            // 当前任务卡信息
                            if appState.selectedTaskVoucher != nil {
                                Text("已选择任务卡，完成一次运动即可解锁美食券")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(hex: "757575"))
                            } else {
                                Text("请先在任务卡页面选择任务")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(hex: "E53935"))
                            }
                        }
                        Spacer()
                        // 搜索按钮保持
                        Button(action: {}) {
                            Image(systemName: "magnifyingglass")
                                .font(.title2)
                                .foregroundColor(Color(hex: "212121"))
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 15)
                    .padding(.top, 10)
                    // 标题的显示/隐藏动画
                    .offset(y: isDragging || animationState.selectedDessert != nil ? -100 : 0)
                    .opacity(isDragging || animationState.selectedDessert != nil ? 0 : 1)
                    
                    Spacer()
                }
                
                // 甜品到运动类型的过渡动画视图
                if animationState.selectedDessert != nil {
                    DessertToExerciseTransition(
                        animationState: animationState,
                        screenSize: geometry.size
                    )
                    .transition(.opacity)
                }
            }
            .navigationBarHidden(true)
            .environmentObject(animationState)
        }
    }
}

#Preview {
    NavigationView {
        ExerciseHomeView()
            .environmentObject(AppState.shared)
    }
}

// MARK: - 独立的运动打卡会话视图
struct WorkoutSessionView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // 运动打卡视图
            ExerciseHomeView(onExit: {
                // 退出运动打卡会话
                appState.showWorkoutView = false
                appState.selectedTaskVoucher = nil
            })
            .environmentObject(appState)
        }
    }
} 