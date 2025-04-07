//
//  DataView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

/// 运动数据页面
struct DataView: View {
    /// 运动会话
    @ObservedObject var workoutSession: WorkoutSession
    
    /// 屏幕尺寸
    let screenSize: CGSize
    
    /// 主色调
    private let primaryColor = Color(hex: "FE2D55")
    private let secondaryColor = Color(hex: "FF9901")
    
    /// 呼吸动画控制
    @State private var breathIn = false
    
    /// 跳动动画控制
    @State private var heartbeat = false
    
    var body: some View {
        ZStack {
            // 背景
            Color.white.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 25) {
                    // 顶部标题
                    Text("运动数据")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black.opacity(0.8))
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 15)
                    
                    // 呼吸式动画区域
                    ZStack {
                        // 外层光环
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        dessertColor.opacity(0.4),
                                        dessertColor.opacity(0.1),
                                        .white
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: min(screenSize.width, screenSize.height) * 0.4
                                )
                            )
                            .frame(width: min(screenSize.width, screenSize.height) * 0.8)
                            .scaleEffect(breathIn ? 1.05 : 0.95)
                            .animation(
                                Animation.easeInOut(duration: 4)
                                .repeatForever(autoreverses: true),
                                value: breathIn
                            )
                        
                        // 中层光环
                        Circle()
                            .fill(dessertColor.opacity(0.15))
                            .frame(width: min(screenSize.width, screenSize.height) * 0.6)
                            .scaleEffect(breathIn ? 1.1 : 0.9)
                            .animation(
                                Animation.easeInOut(duration: 4)
                                .repeatForever(autoreverses: true),
                                value: breathIn
                            )
                        
                        // 内层圆形
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        primaryColor.opacity(0.9),
                                        secondaryColor.opacity(0.9)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: min(screenSize.width, screenSize.height) * 0.4)
                            .shadow(color: primaryColor.opacity(0.4), radius: 20, x: 0, y: 0)
                            .scaleEffect(heartbeat ? 1.05 : 1.0)
                            .animation(
                                Animation.spring(dampingFraction: 0.5)
                                .repeatForever(autoreverses: true)
                                .speed(1.5),
                                value: heartbeat
                            )
                        
                        // 甜品信息
                        VStack(spacing: 8) {
                            // 甜品名称
                            Text(workoutSession.targetDessert.name)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            // 状态标签
                            StatusBadge(state: workoutSession.state)
                        }
                    }
                    .padding(.vertical, 20)
                    .onAppear {
                        breathIn = true
                        heartbeat = true
                    }
                    
                    // 进度指示器
                    VStack(spacing: 10) {
                        // 进度文本
                        HStack {
                            Text("目标进度")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("\(Int(workoutSession.burnedCalories))/\(Int(workoutSession.targetCalories)) kcal")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(primaryColor)
                        }
                        
                        // 进度条
                        ZStack(alignment: .leading) {
                            // 背景
                            Capsule()
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 8)
                            
                            // 进度
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [primaryColor, secondaryColor]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, min(screenSize.width - 60, (screenSize.width - 60) * completionPercentage)), height: 8)
                        }
                    }
                    .padding(.horizontal, 25)
                    
                    // 核心数据网格
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 15) {
                        // 时间
                        CoreDataCard(
                            icon: "clock.fill",
                            iconColor: primaryColor,
                            value: formattedTime,
                            label: "总时间"
                        )
                        
                        // 卡路里
                        CoreDataCard(
                            icon: "flame.fill",
                            iconColor: secondaryColor,
                            value: "\(Int(workoutSession.burnedCalories))",
                            label: "卡路里消耗"
                        )
                        
                        // 距离/次数
                        CoreDataCard(
                            icon: workoutSession.exerciseType.requiresGPS ? "map.fill" : "repeat",
                            iconColor: Color(hex: "4CD964"),
                            value: distanceOrCount,
                            label: distanceOrCountLabel
                        )
                        
                        // 完成度
                        CoreDataCard(
                            icon: "chart.pie.fill",
                            iconColor: Color(hex: "5AC8FA"),
                            value: "\(Int(workoutSession.completionPercentage))%",
                            label: "完成度"
                        )
                    }
                    .padding(.horizontal, 15)
                    .padding(.top, 10)
                    
                    Spacer(minLength: 50)
                }
                .padding(.bottom, 30)
            }
        }
    }
    
    /// 甜品颜色
    private var dessertColor: Color {
        return workoutSession.targetDessert.backgroundColor ?? primaryColor
    }
    
    /// 格式化的时间
    private var formattedTime: String {
        let totalSeconds = workoutSession.totalElapsedSeconds
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// 完成百分比
    private var completionPercentage: CGFloat {
        return CGFloat(workoutSession.completionPercentage / 100.0)
    }
    
    /// 距离或次数显示
    private var distanceOrCount: String {
        if workoutSession.exerciseType.requiresGPS {
            // 显示距离（公里）
            return String(format: "%.2f", workoutSession.distanceInMeters / 1000)
        } else {
            // 显示次数 - 这里需要实际实现
            return "0"
        }
    }
    
    /// 距离或次数标签
    private var distanceOrCountLabel: String {
        if workoutSession.exerciseType.requiresGPS {
            return "总里程(km)"
        } else {
            return "完成次数"
        }
    }
}

/// 状态标签
struct StatusBadge: View {
    let state: WorkoutState
    
    private var stateText: String {
        switch state {
        case .notStarted: return "未开始"
        case .active: return "进行中"
        case .paused: return "已暂停"
        case .completed: return "已完成"
        case .abandoned: return "已放弃"
        }
    }
    
    private var stateColor: Color {
        switch state {
        case .notStarted: return .gray
        case .active: return Color(hex: "34C759")
        case .paused: return Color(hex: "FFCC00")
        case .completed: return Color(hex: "5AC8FA")
        case .abandoned: return Color(hex: "FF3B30")
        }
    }
    
    var body: some View {
        Text(stateText)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(stateColor.opacity(0.3))
            .cornerRadius(12)
    }
}

/// 核心数据卡片
struct CoreDataCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 15) {
            // 图标
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(spacing: 5) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black.opacity(0.8))
                
                Text(label)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
    }
} 