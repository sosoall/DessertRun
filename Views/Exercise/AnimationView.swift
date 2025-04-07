//
//  AnimationView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI
import DotLottie

/// 运动动画页面
struct AnimationView: View {
    /// 运动会话
    @ObservedObject var workoutSession: WorkoutSession
    
    /// 屏幕尺寸
    let screenSize: CGSize
    
    /// 主色调
    private let primaryColor = Color(hex: "FE2D55")
    private let secondaryColor = Color(hex: "FF9901")
    
    var body: some View {
        ZStack {
            // 背景
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                // 顶部标题
                Text("运动中")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black.opacity(0.8))
                    .padding(.top, 20)
                
                // Lottie动画区域
                ZStack {
                    // 外层圆形装饰
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    dessertColor.opacity(0.1),
                                    .white
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: min(screenSize.width, screenSize.height) * 0.8)
                    
                    // 使用DotLottie加载动画
                    DotLottieAnimation(fileName: "BubbleTea", 
                                      config: AnimationConfig(autoplay: true, loop: true))
                        .view()
                        .frame(width: min(screenSize.width, screenSize.height) * 0.6)
                        .onAppear {
                            print("🔍 尝试加载动画: BubbleTea")
                        }
                }
                .padding(.vertical, 20)
                
                // 进度指示器
                VStack(spacing: 20) {
                    // 进度文本
                    HStack {
                        Text("已消耗")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("\(Int(workoutSession.burnedCalories))/\(Int(workoutSession.targetCalories)) kcal")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(primaryColor)
                    }
                    .padding(.horizontal, 5)
                    
                    // 进度条
                    ZStack(alignment: .leading) {
                        // 背景
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 24)
                        
                        // 进度
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [primaryColor, secondaryColor]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, min(screenSize.width - 40, (screenSize.width - 40) * completionPercentage)), height: 24)
                            .animation(.spring(), value: completionPercentage)
                        
                        // 百分比标记
                        if completionPercentage > 0.03 {
                            Text("\(Int(workoutSession.completionPercentage))%")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.leading, 10)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // 运动数据网格
                HStack(spacing: 0) {
                    // 时间
                    InfoCell(
                        icon: "clock.fill",
                        value: formattedTime,
                        label: "时间",
                        gradient: Gradient(colors: [primaryColor.opacity(0.9), primaryColor.opacity(0.7)])
                    )
                    
                    // 卡路里
                    InfoCell(
                        icon: "flame.fill",
                        value: "\(Int(workoutSession.burnedCalories))",
                        label: "卡路里",
                        gradient: Gradient(colors: [secondaryColor.opacity(0.9), secondaryColor.opacity(0.7)])
                    )
                    
                    // 距离/次数
                    InfoCell(
                        icon: workoutSession.exerciseType.requiresGPS ? "map.fill" : "repeat",
                        value: distanceOrCount,
                        label: distanceOrCountLabel,
                        gradient: Gradient(colors: [Color(hex: "4CD964").opacity(0.9), Color(hex: "4CD964").opacity(0.7)])
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                
                Spacer()
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

/// 信息单元格
struct InfoCell: View {
    let icon: String
    let value: String
    let label: String
    let gradient: Gradient
    
    var body: some View {
        VStack(spacing: 12) {
            // 图标背景
            ZStack {
                Circle()
                    .fill(LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black.opacity(0.8))
                .padding(.top, 2)
            
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
} 