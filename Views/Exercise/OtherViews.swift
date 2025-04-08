//
//  OtherViews.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

// 添加自定义环境键定义
private struct DemoModeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

// 扩展EnvironmentValues添加自定义键
extension EnvironmentValues {
    var demoMode: Bool {
        get { self[DemoModeKey.self] }
        set { self[DemoModeKey.self] = newValue }
    }
}

/// 控制栏
struct ControlBar: View {
    /// 页面索引绑定
    @Binding var pageIndex: Int
    
    /// 暂停回调
    var onPause: () -> Void
    
    /// 主色调
    private let primaryColor = Color(hex: "FE2D55")
    
    var body: some View {
        HStack {
            Spacer()
            
            // 暂停按钮
            Button(action: onPause) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                    
                    Image(systemName: "pause.fill")
                        .font(.title2)
                        .foregroundColor(primaryColor)
                }
            }
            
            Spacer()
        }
        .padding(.bottom, 30)
    }
}

/// 页面指示器
struct PageIndicator: View {
    let currentPage: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(currentPage == 0 ? Color(hex: "FE2D55") : Color.gray.opacity(0.5))
                .frame(width: 8, height: 8)
            
            Circle()
                .fill(currentPage == 1 ? Color(hex: "FE2D55") : Color.gray.opacity(0.5))
                .frame(width: 8, height: 8)
        }
    }
}

/// 暂停菜单
struct PauseMenuView: View {
    /// 环境中的应用状态
    @EnvironmentObject var appState: AppState
    
    /// 环境中的演示模式
    @Environment(\.demoMode) var demoMode
    
    /// 运动会话
    @ObservedObject var workoutSession: WorkoutSession
    
    /// 是否显示暂停菜单
    @Binding var showPauseMenu: Bool
    
    /// 完成运动回调
    var onComplete: (() -> Void)?
    
    /// 显示确认对话框
    @State private var showConfirmation = false
    
    /// 恢复按钮缩放
    @State private var resumeButtonScale: CGFloat = 1.0
    
    /// 停止按钮缩放
    @State private var stopButtonScale: CGFloat = 1.0
    
    /// 标记是否长按停止按钮
    @State private var isLongPressing = false
    
    /// 长按进度 (0.0 - 1.0)
    @State private var longPressProgress: CGFloat = 0.0
    
    /// 长按所需时间（秒）
    private let longPressDuration: Double = 1.5
    
    /// 按钮通用大小
    private let buttonSize: CGFloat = 70
    
    /// 进度条宽度
    private let progressWidth: CGFloat = 4
    
    /// 长按定时器
    @State private var longPressTimer: Timer? = nil
    
    /// 按钮缩放状态
    @State private var isButtonPressed = false
    
    /// 确认对话框标题
    let confirmationTitle = "确认结束运动"
    
    /// 确认对话框消息
    let confirmationMessage = "你确定要结束当前运动吗？"
    
    var body: some View {
        ZStack {
            // 半透明背景 - 减轻遮罩深度
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // 点击空白处恢复运动
                    withAnimation {
                        workoutSession.resumeWorkout()
                        showPauseMenu = false
                    }
                }
            
            // 底部按钮区域 - 移到屏幕底部
            VStack {
                Spacer()
                
                HStack(spacing: 80) {
                    // 继续按钮
                    Button {
                        withAnimation(.spring()) {
                            resumeButtonScale = 0.9
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring()) {
                                resumeButtonScale = 1.0
                                // 恢复运动会话
                                workoutSession.resumeWorkout()
                                showPauseMenu = false
                            }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: buttonSize, height: buttonSize)
                                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                            
                            Image(systemName: "play.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                                .offset(x: 3) // 调整使其视觉居中
                        }
                        .scaleEffect(resumeButtonScale)
                    }
                    
                    // 停止按钮 - 带长按手势
                    VStack(spacing: 8) {
                        // 长按提示文本
                        Text("长按停止")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(4)
                            .opacity(isButtonPressed ? 0 : 1) // 开始长按时隐藏提示
                        
                        ZStack {
                            // 进度环
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                                .frame(width: buttonSize, height: buttonSize)
                            
                            // 进度填充环
                            Circle()
                                .trim(from: 0, to: longPressProgress)
                                .stroke(Color(hex: "FF9500"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: buttonSize, height: buttonSize)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 0.1), value: longPressProgress)
                            
                            // 实际按钮 - 改为深紫色
                            Circle()
                                .fill(Color(hex: "5856D6")) // 改为紫色而不是红色
                                .frame(width: buttonSize, height: buttonSize)
                                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                                .scaleEffect(stopButtonScale)
                            
                            Image(systemName: "stop.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.white)
                        }
                        .gesture(
                            LongPressGesture(minimumDuration: longPressDuration)
                                .onEnded { _ in
                                    // 长按完成后复位并触发确认对话框
                                    self.longPressTimer?.invalidate()
                                    self.longPressTimer = nil
                                    self.longPressProgress = 0
                                    self.isButtonPressed = false
                                    stopButtonScale = 1.0
                                    
                                    // 根据演示模式决定是显示确认框还是直接完成
                                    if demoMode {
                                        workoutSession.completeWorkout()
                                        
                                        // 退出运动模式并调用完成回调
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            showPauseMenu = false
                                            appState.isInWorkoutMode = false
                                            onComplete?()
                                        }
                                    } else {
                                        self.showConfirmation = true
                                    }
                                }
                                .simultaneously(with: 
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            // 开始长按
                                            if !isButtonPressed {
                                                isButtonPressed = true
                                                stopButtonScale = 0.9
                                                
                                                // 创建定时器更新进度
                                                self.longPressTimer?.invalidate()
                                                self.longPressProgress = 0
                                                
                                                self.longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { timer in
                                                    withAnimation(.linear(duration: 0.02)) {
                                                        if self.longPressProgress < 1.0 {
                                                            self.longPressProgress += 0.02 / longPressDuration  // 1.5秒填满进度
                                                        } else {
                                                            timer.invalidate()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        .onEnded { _ in
                                            // 结束长按但未完成
                                            self.longPressTimer?.invalidate()
                                            self.longPressTimer = nil
                                            
                                            withAnimation(.spring()) {
                                                self.longPressProgress = 0
                                                self.isButtonPressed = false
                                                stopButtonScale = 1.0
                                            }
                                        }
                                )
                        )
                    }
                }
                .padding(.bottom, 80) // 设置底部间距，靠近原暂停按钮位置
            }
        }
        .alert(isPresented: $showConfirmation) {
            Alert(
                title: Text(confirmationTitle),
                message: Text(confirmationMessage),
                primaryButton: .destructive(Text("确认")) {
                    // 确认停止运动，完成运动会话并回调
                    workoutSession.completeWorkout()
                    showPauseMenu = false
                    
                    // 使用回调通知WorkoutView跳转到完成页面
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        onComplete?()
                    }
                },
                secondaryButton: .cancel(Text("取消")) {
                    // 取消停止，继续运动
                    withAnimation {
                        workoutSession.resumeWorkout()
                        showPauseMenu = false
                    }
                }
            )
        }
    }
} 