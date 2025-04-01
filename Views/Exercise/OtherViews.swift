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
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            // 菜单内容
            VStack(spacing: 30) {
                Text("运动已暂停")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 20) {
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
                        .frame(width: 200)
                        .background(Color(hex: "34C759"))
                        .cornerRadius(10)
                    }
                    
                    // 停止按钮
                    Button(action: onStop) {
                        HStack {
                            Image(systemName: "stop.fill")
                                .font(.headline)
                            
                            Text("结束运动")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 200)
                        .background(Color(hex: "FE2D55"))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
} 