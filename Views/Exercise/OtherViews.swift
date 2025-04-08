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
                        .foregroundColor(Color(hex: "FE2D55"))
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
    @State private var timer: Timer?
    
    /// 长按所需时间（秒）
    private let longPressDuration: Double = 1.5
    
    var body: some View {
        VStack {
            Spacer()
            
            // 底部按钮容器
            VStack(spacing: 30) {
                // 按钮区域
                HStack(spacing: 50) {
                    // 继续按钮 - 圆形
                    Button(action: onResume) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "34C759")) // 使用绿色
                                .frame(width: 70, height: 70)
                                .shadow(color: Color.black.opacity(0.2), radius: 5)
                            
                            Image(systemName: "arrow.clockwise") // 更改为循环箭头图标
                                .font(.system(size: 26))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // 停止按钮 - 圆形带进度环
                    ZStack {
                        // 底层圆形
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 70, height: 70)
                        
                        // 外部进度环
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 4)
                            .frame(width: 70, height: 70)
                        
                        // 进度环
                        Circle()
                            .trim(from: 0, to: longPressProgress)
                            .stroke(Color(hex: "FE2D55"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(-90))
                        
                        // 停止图标
                        ZStack {
                            Circle()
                                .fill(Color(hex: "FE2D55"))
                                .frame(width: 60, height: 60)
                                .shadow(color: Color.black.opacity(0.1), radius: 3)
                            
                            Image(systemName: "xmark") // 使用X图标替代停止图标
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .contentShape(Circle())
                    .gesture(
                        LongPressGesture(minimumDuration: longPressDuration)
                            .onEnded { _ in
                                onStop()
                                timer?.invalidate()
                                timer = nil
                            }
                            .sequenced(before: DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    // 开始长按时设置标志并启动定时器
                                    if !isLongPressing {
                                        isLongPressing = true
                                        startProgressTimer()
                                    }
                                }
                                .onEnded { _ in
                                    // 结束长按，重置进度
                                    timer?.invalidate()
                                    timer = nil
                                    isLongPressing = false
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        longPressProgress = 0.0
                                    }
                                })
                    )
                }
                
                // 文字提示
                Text(isLongPressing ? "继续按住以停止运动..." : "长按停止按钮结束运动")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 20)
            .padding(.bottom, 30) // 增加底部安全区域的边距
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }
    
    // 启动进度定时器
    private func startProgressTimer() {
        // 重置进度
        longPressProgress = 0.0
        
        // 创建定时器，平滑更新进度
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if isLongPressing && longPressProgress < 1.0 {
                withAnimation(.linear(duration: 0.05)) {
                    longPressProgress += 0.05 / longPressDuration
                }
            } else if longPressProgress >= 1.0 {
                timer?.invalidate()
                timer = nil
                onStop() // 达到100%进度时自动触发停止回调
            }
        }
    }
} 