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
    
    // 是否正在拖动气泡
    @State private var isDragging: Bool = false
    
    var body: some View {
        ZStack {
            // 背景
            Color(hex: "FFFFFF").ignoresSafeArea()
            
            // 甜品网格视图
            DessertGridView(onDragStateChanged: { isDragging in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.isDragging = isDragging
                }
            })
            
            // 顶部和底部覆盖层（确保在气泡上方）
            VStack {
                // 顶部标题区域（带白色背景的容器）
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("你好，soso")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "212121"))
                        Text("选择一个美食开始运动吧！")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(hex: "212121"))
                    }
                    Spacer()
                    
                    // 搜索按钮
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
                .offset(y: isDragging ? -100 : 0)
                .opacity(isDragging ? 0 : 1)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationView {
        ExerciseHomeView()
            .environmentObject(AppState.shared)
    }
} 