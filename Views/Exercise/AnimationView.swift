//
//  AnimationView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

/// 运动动画页面
struct AnimationView: View {
    /// 运动会话
    @ObservedObject var workoutSession: WorkoutSession
    
    /// 屏幕尺寸
    let screenSize: CGSize
    
    /// 动画状态
    @State private var animationState = 0
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 甜品动画区域
            ZStack {
                // 背景圆形
                Circle()
                    .fill(dessertColor.opacity(0.2))
                    .frame(width: min(screenSize.width, screenSize.height) * 0.7)
                
                // 甜品图标
                Image(systemName: "cup.and.saucer.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(dessertColor)
                    .frame(width: min(screenSize.width, screenSize.height) * 0.3)
                    .scaleEffect(1.0 + 0.1 * sin(Double(animationState) / 10))
                    .shadow(color: dessertColor.opacity(0.5), radius: 10)
            }
            .onAppear {
                // 启动动画
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    animationState = 100
                }
            }
            
            // 进度条
            VStack(spacing: 10) {
                // 标签
                HStack {
                    Text("已消耗")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(workoutSession.burnedCalories)) / \(Int(workoutSession.targetCalories)) 千卡")
                        .font(.headline)
                        .foregroundColor(Color(hex: "FE2D55"))
                }
                
                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 16)
                        
                        // 进度
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "FE2D55"),
                                        Color(hex: "FF9901")
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, min(geometry.size.width, geometry.size.width * completionPercentage)), height: 16)
                    }
                }
                .frame(height: 16)
            }
            .padding(.horizontal)
            
            // 基础信息
            HStack(spacing: 30) {
                // 时间
                VStack {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    Text(formattedTime)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 5)
                    
                    Text("时间")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // 卡路里
                VStack {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                    
                    Text("\(Int(workoutSession.burnedCalories))")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 5)
                    
                    Text("卡路里")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // 距离/次数
                VStack {
                    Image(systemName: "figure.walk")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Text(distanceOrCount)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 5)
                    
                    Text(distanceOrCountLabel)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    /// 甜品颜色
    private var dessertColor: Color {
        return workoutSession.targetDessert.backgroundColor ?? Color(hex: "FE2D55")
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
            return "公里"
        } else {
            return "次数"
        }
    }
} 