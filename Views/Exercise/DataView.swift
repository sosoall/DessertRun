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
    
    var body: some View {
        ZStack {
            // 背景 - 确保是纯白色
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Spacer(minLength: 20)
                
                // 进度环动画区域
                ZStack {
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
                        .animation(.easeInOut(duration: 1.0), value: workoutSession.completionPercentage)
                    
                    // 脉冲效果
                    Circle()
                        .fill(Color.clear)
                        .frame(width: min(screenSize.width, screenSize.height) * 0.6)
                        .overlay(
                            Circle()
                                .stroke(primaryColor.opacity(0.3), lineWidth: 3)
                                .scaleEffect(isAnimating ? 1.1 : 0.9)
                                .opacity(isAnimating ? 0.2 : 0.5)
                        )
                        .animation(
                            Animation.easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    
                    // 中心显示进度百分比
                    VStack(spacing: 8) {
                        Text("\(Int(workoutSession.completionPercentage))%")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(primaryColor)
                        
                        Text("\(Int(workoutSession.burnedCalories))/\(Int(workoutSession.targetCalories)) 卡")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: screenSize.height * 0.35)
                .padding(.bottom, 20)
                .onAppear {
                    isAnimating = true
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
                    
                    // 目标
                    CoreDataCard(
                        icon: "flag.fill",
                        iconColor: Color(hex: "5AC8FA"),
                        value: "\(Int(workoutSession.targetCalories))",
                        label: "目标卡路里"
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