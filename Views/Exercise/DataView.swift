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
    
    /// 动画控制
    @State private var isAnimating = false
    @State private var isBreathing = false
    @State private var pulseScale = 1.0
    
    // 根据完成百分比确定要显示的粒子数量
    private var particleCount: Int {
        return Int(workoutSession.completionPercentage / 3) + 5 // 至少5个粒子
    }
    
    var body: some View {
        ZStack {
            // 背景 - 确保是纯白色
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // 进度环动画区域
                ZStack {
                    // 粒子效果
                    ForEach(0..<particleCount, id: \.self) { i in
                        Circle()
                            .fill(
                                [primaryColor, secondaryColor, Color.orange, Color.yellow].randomElement()!.opacity(0.7)
                            )
                            .frame(width: CGFloat.random(in: 8...20), height: CGFloat.random(in: 8...20))
                            .offset(
                                x: CGFloat.random(in: -120...120),
                                y: CGFloat.random(in: -120...120)
                            )
                            .scaleEffect(isAnimating ? 1.0 : 0.5)
                            .opacity(isAnimating ? 0.8 : 0.0)
                            .animation(
                                Animation.spring(response: 0.5, dampingFraction: 0.5)
                                    .repeatForever(autoreverses: true)
                                    .speed(Double.random(in: 0.1...0.5))
                                    .delay(Double.random(in: 0...2)),
                                value: isAnimating
                            )
                    }
                    
                    // 外围呼吸效果环
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [primaryColor.opacity(0.2), secondaryColor.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 8
                        )
                        .frame(width: min(screenSize.width, screenSize.height) * 0.65)
                        .scaleEffect(isBreathing && workoutSession.state == .active ? 1.08 : 0.98)
                        .animation(
                            Animation.easeInOut(duration: 3)
                                .repeatForever(autoreverses: true),
                            value: isBreathing && workoutSession.state == .active
                        )
                    
                    // 完整环形背景
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 15)
                        .frame(width: min(screenSize.width, screenSize.height) * 0.6)
                    
                    // 进度环
                    Circle()
                        .trim(from: 0, to: CGFloat(workoutSession.completionPercentage / 100.0))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [primaryColor, secondaryColor]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 15, lineCap: .round)
                        )
                        .frame(width: min(screenSize.width, screenSize.height) * 0.6)
                        .rotationEffect(Angle(degrees: -90))
                        .animation(workoutSession.state == .active ? .easeInOut(duration: 1.0) : .none, value: workoutSession.completionPercentage)
                    
                    // 暂停状态标识 - 仅在暂停时显示
                    if workoutSession.state == .paused {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.3))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "pause.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // 动态脉冲效果
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(
                                primaryColor.opacity(0.3 - Double(i) * 0.1),
                                lineWidth: 3 - CGFloat(i)
                            )
                            .scaleEffect(pulseScale + Double(i) * 0.05)
                            .opacity(isAnimating && workoutSession.state == .active ? 0.6 - Double(i) * 0.2 : 0)
                            .animation(
                                Animation.easeInOut(duration: 1.2 + Double(i) * 0.3)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(i) * 0.4),
                                value: pulseScale
                            )
                    }
                    .frame(width: min(screenSize.width, screenSize.height) * 0.6)
                    
                    // 中心显示进度百分比 - 更大更明显
                    VStack(spacing: 4) {
                        Text("\(Int(workoutSession.completionPercentage))")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(primaryColor)
                            .scaleEffect(isBreathing ? 1.05 : 1.0)
                            .animation(
                                Animation.easeInOut(duration: 2)
                                    .repeatForever(autoreverses: true),
                                value: isBreathing
                            )
                        
                        Text("%")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(primaryColor)
                            .offset(x: 5, y: -10)
                        
                        Text("\(Int(workoutSession.burnedCalories))/\(Int(workoutSession.targetCalories)) 卡")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.top, 5)
                    }
                }
                .frame(height: screenSize.height * 0.35)
                .padding(.bottom, 20)
                .onAppear {
                    isAnimating = true
                    isBreathing = true
                    
                    // 为脉冲动画设置连续变化
                    withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        pulseScale = 1.15
                    }
                }
                
                // 核心数据卡片
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 15) {
                    // 时间
                    CoreDataCard(
                        icon: "clock.fill",
                        iconColor: primaryColor,
                        value: formattedTime,
                        label: "总时间",
                        isAnimating: isAnimating
                    )
                    
                    // 卡路里
                    CoreDataCard(
                        icon: "flame.fill",
                        iconColor: secondaryColor,
                        value: "\(Int(workoutSession.burnedCalories))",
                        label: "卡路里消耗",
                        isAnimating: isAnimating
                    )
                    
                    // 距离/次数
                    CoreDataCard(
                        icon: workoutSession.exerciseType.requiresGPS ? "map.fill" : "repeat",
                        iconColor: Color(hex: "4CD964"),
                        value: distanceOrCount,
                        label: distanceOrCountLabel,
                        isAnimating: isAnimating
                    )
                    
                    // 目标
                    CoreDataCard(
                        icon: "flag.fill",
                        iconColor: Color(hex: "5AC8FA"),
                        value: "\(Int(workoutSession.targetCalories))",
                        label: "目标卡路里",
                        isAnimating: isAnimating
                    )
                }
                .padding(.horizontal, 15)
                
                Spacer()
                
                // 为暂停按钮留出安全区域
                Spacer()
                    .frame(height: 100)
            }
            .padding()
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

/// 核心数据卡片
struct CoreDataCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let isAnimating: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            // 图标
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(iconColor.opacity(0.3), lineWidth: 2)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .opacity(isAnimating ? 0.4 : 0.0)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(iconColor)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
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