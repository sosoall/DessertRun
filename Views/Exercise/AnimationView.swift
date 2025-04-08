//
//  AnimationView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI
import DotLottie  // 使用DotLottie库导入

/// 运动动画页面
struct AnimationView: View {
    /// 运动会话
    @ObservedObject var workoutSession: WorkoutSession
    
    /// 屏幕尺寸
    let screenSize: CGSize
    
    /// 动画状态
    @State private var isAnimating = false
    @State private var isPulsing = false
    @State private var countdown = 3
    @State private var showCountdown = false
    
    /// 主色调
    private let primaryColor = Color(hex: "FE2D55")
    private let secondaryColor = Color(hex: "FF9901")
    
    var body: some View {
        ZStack {
            // 背景
            Color.white.edgesIgnoringSafeArea(.all)
            
            // 主要内容
            VStack(spacing: 0) {
                // 倒计时动画（仅在需要时显示）
                if showCountdown {
                    Text("\(countdown)")
                        .font(.system(size: 120, weight: .bold, design: .rounded))
                        .foregroundColor(primaryColor)
                        .shadow(color: primaryColor.opacity(0.3), radius: 5)
                        .scaleEffect(isPulsing ? 1.2 : 0.8)
                        .opacity(isPulsing ? 1.0 : 0.5)
                        .animation(.easeInOut(duration: 0.8), value: isPulsing)
                        .onAppear {
                            startCountdown()
                        }
                } else if workoutSession.state == .paused {
                    // 暂停状态 - 显示奶茶叉腰图片和对话框
                    VStack(spacing: 20) {
                        // 奶茶叉腰形象
                        Image("BubbleTeaAkimbo") // 使用奶茶叉腰图片资源
                            .resizable()
                            .scaledToFit()
                            .frame(width: min(screenSize.width, screenSize.height) * 0.6)
                        
                        // 对话框
                        ZStack {
                            // 对话气泡
                            Image(systemName: "bubble.left.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Color.white)
                                .frame(width: 200, height: 80)
                                .shadow(color: Color.black.opacity(0.1), radius: 5)
                            
                            Text("快来一起运动呀")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(primaryColor)
                                .offset(y: -5)
                        }
                        .offset(x: 30, y: -20)
                        .scaleEffect(isAnimating ? 1.05 : 0.95)
                        .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                } else {
                    // 动画和百分比分离布局
                    VStack(spacing: 10) {
                        // DotLottie动画
                        DotLottieAnimation(fileName: "BubbleTea", 
                                          config: AnimationConfig(autoplay: true, loop: true))
                            .view()
                            .frame(width: min(screenSize.width, screenSize.height) * 0.75)  // 稍微缩小动画尺寸
                        
                        // 进度数字 - 放到动画下方
                        HStack(spacing: 0) {
                            // 大号百分比
                            Text("\(Int(workoutSession.completionPercentage))")
                                .font(.system(size: 90, weight: .bold, design: .rounded))
                                .foregroundColor(primaryColor)
                                .shadow(color: primaryColor.opacity(0.3), radius: 5)
                            
                            // 百分号 - 调整位置与数字在同一行
                            Text("%")
                                .font(.system(size: 45, weight: .bold))
                                .foregroundColor(primaryColor)
                                .baselineOffset(10)
                                .padding(.leading, 2)
                        }
                        .scaleEffect(isAnimating ? 1.05 : 0.98)
                        .animation(
                            Animation.easeInOut(duration: 2.5)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                }
                
                // 底部安全区域，为暂停按钮留出空间
                Spacer()
                    .frame(height: 100)
            }
            .padding(.horizontal)
            .padding(.top, 0) // 移除顶部内边距
            .onAppear {
                // 开始动画
                withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
    }
    
    /// 开始倒计时动画
    private func startCountdown() {
        // 开始脉冲动画
        withAnimation {
            isPulsing = true
        }
        
        // 定时器减少倒计时数值
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            withAnimation {
                isPulsing = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    countdown -= 1
                    isPulsing = true
                }
                
                if countdown <= 0 {
                    timer.invalidate()
                    withAnimation {
                        showCountdown = false
                    }
                }
            }
        }
    }
}

#Preview {
    AnimationView(
        workoutSession: WorkoutSession(
            targetDessert: DessertData.getSampleDesserts().first!,
            exerciseType: ExerciseType.allCases.first!
        ),
        screenSize: UIScreen.main.bounds.size
    )
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