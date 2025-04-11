//
//  StatsHomeView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

/// 统计模块主页面 - 作为容器，包含分段控制器和两个子视图
struct StatsHomeView: View {
    // 全局应用状态
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // 页面标题
            Text("运动统计")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "61462C"))
                .padding(.top, 16)
            
            // 分段控制器
            Picker("视图选择", selection: $appState.statsSelectedSegment) {
                Text("运动日历").tag(0)
                Text("美食券").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // 根据选中的分段显示不同内容
            if appState.statsSelectedSegment == 0 {
                // 运动日历视图
                WorkoutCalendarView()
            } else {
                // 美食券管理视图
                VoucherManagementView()
            }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationView {
        StatsHomeView()
            .environmentObject(AppState.shared)
    }
} 