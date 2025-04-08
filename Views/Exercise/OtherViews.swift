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
    
    /// 长按所需时间（秒）
    private let longPressDuration: Double = 1.5
    
    var body: some View {
        VStack {
            Spacer()
            
            // 底部按钮容器
            VStack(spacing: 15) {
                // 继续按钮
                Button(action: onResume) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.headline)
                        
                        Text("继续运动")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "34C759"))
                    .cornerRadius(16)
                }
                
                // 停止按钮 - 长按触发
                ZStack {
                    // 背景进度
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                HStack {
                                    Rectangle()
                                        .fill(Color(hex: "FE2D55"))
                                        .frame(width: geo.size.width * longPressProgress)
                                    
                                    Spacer(minLength: 0)
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            )
                    }
                    
                    // 按钮文字
                    HStack {
                        Image(systemName: "stop.fill")
                            .font(.headline)
                        
                        Text(isLongPressing ? "继续按住以结束运动..." : "长按结束运动")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 50)
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: longPressDuration, perform: {
                    // 长按完成
                    onStop()
                }, onPressingChanged: { isPressing in
                    isLongPressing = isPressing
                    
                    if isPressing {
                        // 开始长按，启动进度动画
                        withAnimation(.linear(duration: longPressDuration)) {
                            longPressProgress = 1.0
                        }
                    } else if longPressProgress < 1.0 {
                        // 中断长按，重置进度
                        withAnimation(.easeOut(duration: 0.3)) {
                            longPressProgress = 0.0
                        }
                    }
                })
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                    .ignoresSafeArea(edges: .bottom)
            )
        }
    }
} 