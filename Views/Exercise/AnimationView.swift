//
//  AnimationView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI
import DotLottie  // 使用CocoaPods安装的dotLottie库

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
            
            VStack(spacing: 20) {
                Spacer(minLength: 20)
                
                // Lottie动画区域 - 增大尺寸，至少占页面50%
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
                        .frame(width: min(screenSize.width, screenSize.height) * 0.9)
                    
                    // 使用DotLottie加载动画 - 增大至页面的70%
                    DotLottieAnimation(fileName: "BubbleTea", 
                                      config: AnimationConfig(autoplay: true, loop: true))
                        .view()
                        .frame(width: min(screenSize.width, screenSize.height) * 0.7)
                        .onAppear {
                            print("🔍 尝试加载动画: BubbleTea")
                        }
                        .onDisappear {
                            // 动画视图消失时的操作，确保暂停动画
                        }
                }
                .frame(height: screenSize.height * 0.6) // 确保动画高度占总高度的60%
                
                // 简单的卡路里信息展示
                Text("\(Int(workoutSession.burnedCalories))/\(Int(workoutSession.targetCalories)) kcal")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(primaryColor)
                    .padding(.top, 10)
                
                // 完成百分比
                Text("\(Int(workoutSession.completionPercentage))%")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.gray)
                
                Spacer()
                
                // 底部安全区域，为暂停按钮留出空间
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