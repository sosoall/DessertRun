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
    
    var body: some View {
        VStack(spacing: 0) {
            // 页面标题
            Text("选择你想要的甜品")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "61462C"))
                .padding(.top, 16)
                .padding(.bottom, 8)
            
            // 副标题
            Text("健康运动，零负罪感")
                .font(.subheadline)
                .foregroundColor(Color(hex: "61462C").opacity(0.8))
                .padding(.bottom, 16)
            
            // 使用已有的甜品网格视图
            DessertGridView()
        }
        .background(Color(hex: "fae8c8").ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationView {
        ExerciseHomeView()
            .environmentObject(AppState.shared)
    }
} 