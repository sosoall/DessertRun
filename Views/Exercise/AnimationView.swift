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
    @State private var pauseOpacity = 0.0  // 用于暂停状态的淡入效果
    @State private var activeOffset = CGSize.zero // 用于控制运动状态移出屏幕
    
    /// 主色调
    private let primaryColor = Color(hex: "FE2D55")
    private let secondaryColor = Color(hex: "FF9901")
    
    /// 激励文本数组
    private let motivationalTexts = [
        "加油！你可以的！",
        "每一步都是进步！",
        "坚持就是胜利！",
        "感受身体的力量！",
        "为自己而战！"
    ]
    
    /// 当前显示的激励文本索引
    @State private var currentTextIndex = 0
    
    /// 应用是否在前台
    @State private var isAppActive: Bool = true
    
    var body: some View {
        ZStack {
            // 背景
            Color.white.edgesIgnoringSafeArea(.all)
            
            // 主要内容
            VStack(spacing: 0) {
                // 增加顶部安全区域边距
                Spacer(minLength: 40)
                
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
                    // 暂停状态 - 显示奶茶静态图片和对话框
                    ZStack(alignment: .center) {
                        // 奶茶叉腰静态图片 - 稍微往左偏移
                        Image("BubbleTeaAkimbo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: min(screenSize.width, screenSize.height) * 1.2)  // 增大图片尺寸
                            .offset(x: -20)  // 向左偏移
                        
                        // 对话框气泡 - 放在右上方，覆盖在静态图上
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(hex: "FBF5F5"))
                                .frame(width: 200, height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(hex: "D9D9D9"), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 3)
                            
                            Text("快来一起运动呀")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .offset(x: 60, y: -150)  // 右上方位置
                        .scaleEffect(isAnimating ? 1.03 : 0.97)
                        .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                    .opacity(pauseOpacity)  // 使用淡入效果
                    .onAppear {
                        // 淡入动画
                        withAnimation(.easeInOut(duration: 0.5)) {
                            pauseOpacity = 1.0
                        }
                    }
                    
                    // 热量消耗百分比文字
                    Text("\(Int(workoutSession.completionPercentage))%热量被消耗")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(Color(hex: "757575"))
                        .padding(.top, 10)
                        .opacity(pauseOpacity)  // 使用淡入效果
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
                    .offset(activeOffset)
                    .onChange(of: workoutSession.state) { _ in
                        if workoutSession.state == .paused {
                            // 当切换到暂停状态时，将动画向右移出屏幕
                            withAnimation(.easeInOut(duration: 0.5)) {
                                activeOffset = CGSize(width: screenSize.width, height: 0)
                            }
                        } else {
                            // 当恢复运动时，将动画移回原位
                            withAnimation(.easeInOut(duration: 0.5)) {
                                activeOffset = .zero
                            }
                        }
                    }
                }
                
                // 底部安全区域，为暂停按钮留出空间
                Spacer()
                    .frame(height: 100)
            }
            .padding(.horizontal)
            .padding(.top, 0) // 移除顶部内边距
            .onAppear {
                // 开始动画
                startAnimations()
                
                // 设置计时器，定期更换激励文本
                startMotivationalTextTimer()
                
                // 设置通知监听器
                setupNotificationObservers()
            }
            .onDisappear {
                // 移除通知监听器
                removeNotificationObservers()
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
    
    /// 开始动画
    private func startAnimations() {
        if isAppActive {
            withAnimation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
    
    /// 停止动画
    private func stopAnimations() {
        withAnimation(.easeOut(duration: 0.5)) {
            isAnimating = false
        }
    }
    
    /// 启动激励文本计时器
    private func startMotivationalTextTimer() {
        // 创建一个每5秒触发一次的计时器，用于更新激励文本
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            // 只在应用处于前台时更新文字
            if isAppActive {
                withAnimation(.easeInOut) {
                    // 随机选择下一条激励文本
                    let nextIndex = Int.random(in: 0..<motivationalTexts.count)
                    // 确保不会连续显示相同的文本
                    if nextIndex != currentTextIndex {
                        currentTextIndex = nextIndex
                    } else {
                        currentTextIndex = (currentTextIndex + 1) % motivationalTexts.count
                    }
                }
            }
        }
    }
    
    // MARK: - 通知处理
    
    /// 设置通知监听器
    private func setupNotificationObservers() {
        // 监听应用进入后台
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            isAppActive = false
            stopAnimations()
        }
        
        // 监听应用即将进入前台
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            isAppActive = true
            startAnimations()
        }
        
        // 监听停止动画通知
        NotificationCenter.default.addObserver(
            forName: Notification.Name("SuspendWorkoutAnimations"),
            object: nil,
            queue: .main
        ) { _ in
            stopAnimations()
        }
    }
    
    /// 移除通知监听器
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name("SuspendWorkoutAnimations"),
            object: nil
        )
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