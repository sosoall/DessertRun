//
//  OtherViews.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

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
    /// 继续回调
    var onResume: () -> Void
    
    /// 停止回调
    var onStop: () -> Void
    
    /// 长按状态控制
    @State private var longPressProgress: CGFloat = 0.0
    @State private var isLongPressing = false
    @State private var showLongPressHint = false
    @State private var buttonScale = 0.5  // 初始按钮缩放
    @State private var buttonOpacity = 0.0  // 初始按钮透明度
    
    /// 长按所需时间（秒）
    private let longPressDuration: Double = 1.5
    
    /// 主色调
    private let primaryColor = Color(hex: "FE2D55")
    
    var body: some View {
        VStack {
            Spacer()
            
            // 底部按钮容器
            HStack(spacing: 27) {
                // 继续按钮
                Button(action: onResume) {
                    ZStack {
                        Circle()
                            .fill(primaryColor)  // 整个圆圈使用主题色
                            .frame(width: 60, height: 60)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                        
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .foregroundColor(.white)  // 图标改为白色以便与背景对比
                    }
                }
                .scaleEffect(buttonScale)
                .opacity(buttonOpacity)
                
                // 停止按钮 - 长按触发
                ZStack {
                    // 背景和进度环
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                        .overlay(
                            Circle()
                                .trim(from: 0, to: longPressProgress)
                                .stroke(primaryColor, lineWidth: 3)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: longPressDuration), value: longPressProgress)
                        )
                    
                    // 停止图标
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundColor(Color.gray)
                }
                .scaleEffect(buttonScale)
                .opacity(buttonOpacity)
                .overlay(
                    // 长按提示
                    VStack {
                        if showLongPressHint {
                            Text("请长按停止运动")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.black.opacity(0.7))
                                )
                        }
                    }
                    .offset(y: -40), 
                    alignment: .top
                )
                .contentShape(Circle())
                .gesture(
                    LongPressGesture(minimumDuration: longPressDuration)
                        .onEnded { _ in
                            // 长按完成
                            onStop()
                        }
                        .sequenced(before: DragGesture(minimumDistance: 0)
                            .onChanged({ _ in
                                if !isLongPressing {
                                    isLongPressing = true
                                    // 开始长按，启动进度动画
                                    longPressProgress = 0.0  // 重置进度
                                    withAnimation(.linear(duration: longPressDuration)) {
                                        longPressProgress = 1.0
                                    }
                                }
                            })
                            .onEnded({ _ in
                                if longPressProgress < 1.0 {
                                    // 中断长按，重置进度并显示提示
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        longPressProgress = 0.0
                                    }
                                    // 显示长按提示
                                    showLongPressHint = true
                                    // 2秒后隐藏提示
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation {
                                            showLongPressHint = false
                                        }
                                    }
                                }
                                isLongPressing = false
                            })
                        )
                )
            }
            .padding(.bottom, 30)
            .onAppear {
                // 按钮出现动画
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    buttonScale = 1.0
                    buttonOpacity = 1.0
                }
            }
        }
    }
} 