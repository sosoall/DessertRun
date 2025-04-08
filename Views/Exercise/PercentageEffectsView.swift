//
//  PercentageEffectsView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI
import DotLottie  // 添加DotLottie库导入

/// 百分比效果展示器
struct PercentageEffectsView: View {
    // 工作会话
    @ObservedObject var workoutSession: WorkoutSession
    
    // 屏幕尺寸
    let screenSize: CGSize
    
    // 当前选中的效果
    @State private var selectedEffect = 0
    
    // 主色调
    private let primaryColor = Color(hex: "FE2D55")
    private let secondaryColor = Color(hex: "FF9901")
    
    // 动画控制
    @State private var isAnimating = false
    
    var body: some View {
        TabView(selection: $selectedEffect) {
            // 效果1: 环形进度条
            ProgressRingEffect(
                workoutSession: workoutSession,
                screenSize: screenSize,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                isAnimating: $isAnimating
            )
            .tag(0)
            
            // 效果2: 水位效果
            WaterLevelEffect(
                workoutSession: workoutSession,
                screenSize: screenSize,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                isAnimating: $isAnimating
            )
            .tag(1)
            
            // 效果3: 粒子系统效果
            ParticleEffect(
                workoutSession: workoutSession,
                screenSize: screenSize,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                isAnimating: $isAnimating
            )
            .tag(2)
            
            // 效果4: 高科技投影效果
            HolographicEffect(
                workoutSession: workoutSession,
                screenSize: screenSize,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                isAnimating: $isAnimating
            )
            .tag(3)
            
            // 效果5: 表情变化效果
            EmotionEffect(
                workoutSession: workoutSession,
                screenSize: screenSize,
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                isAnimating: $isAnimating
            )
            .tag(4)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - 效果1: 环形进度条
struct ProgressRingEffect: View {
    @ObservedObject var workoutSession: WorkoutSession
    let screenSize: CGSize
    let primaryColor: Color
    let secondaryColor: Color
    @Binding var isAnimating: Bool
    
    var body: some View {
        ZStack {
            // 底层圆形装饰
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
            
            // 环形进度条
            ZStack {
                // 完整环形背景
                Circle()
                    .stroke(Color.gray.opacity(0.1), lineWidth: 15)
                    .frame(width: min(screenSize.width, screenSize.height) * 0.7)
                
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
                    .frame(width: min(screenSize.width, screenSize.height) * 0.7)
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.easeInOut(duration: 1.0), value: workoutSession.completionPercentage)
                
                // DotLottie动画
                DotLottieAnimation(fileName: "BubbleTea", 
                                  config: AnimationConfig(autoplay: true, loop: true))
                    .view()
                    .frame(width: min(screenSize.width, screenSize.height) * 0.5)
                
                // 环上的闪亮标记
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: primaryColor, radius: 3)
                    .offset(y: -min(screenSize.width, screenSize.height) * 0.35)
                    .rotationEffect(Angle(degrees: workoutSession.completionPercentage * 3.6 - 90))
            }
            
            // 中心显示进度百分比
            VStack(spacing: 0) {
                Text("\(Int(workoutSession.completionPercentage))")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(primaryColor)
                
                Text("%")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(primaryColor)
                    .offset(x: 5, y: -10)
            }
            .offset(y: min(screenSize.width, screenSize.height) * 0.25)
            
            // 效果名称
            Text("环形进度")
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(5)
                .offset(y: min(screenSize.width, screenSize.height) * 0.35)
        }
    }
    
    private var dessertColor: Color {
        return workoutSession.targetDessert.backgroundColor ?? primaryColor
    }
}

// MARK: - 效果2: 水位效果
struct WaterLevelEffect: View {
    @ObservedObject var workoutSession: WorkoutSession
    let screenSize: CGSize
    let primaryColor: Color
    let secondaryColor: Color
    @Binding var isAnimating: Bool
    @State private var waveOffset = 0.0
    
    var body: some View {
        ZStack {
            // 底层圆形装饰
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
            
            // 水位容器
            ZStack {
                // 动画容器
                DotLottieAnimation(fileName: "BubbleTea", 
                                  config: AnimationConfig(autoplay: true, loop: true))
                    .view()
                    .frame(width: min(screenSize.width, screenSize.height) * 0.5)
                    .clipShape(Circle())
                
                // 水波效果 - 使用两层波浪模拟动态效果
                GeometryReader { geo in
                    ZStack {
                        // 第一层波浪
                        WaveShape(waveHeight: 10, phase: waveOffset)
                            .fill(Color.blue.opacity(0.3))
                            .mask(
                                Rectangle()
                                    .frame(
                                        height: geo.size.height * (1 - workoutSession.completionPercentage / 100)
                                    )
                                    .offset(y: geo.size.height * workoutSession.completionPercentage / 100)
                            )
                        
                        // 第二层波浪
                        WaveShape(waveHeight: 15, phase: waveOffset + .pi)
                            .fill(primaryColor.opacity(0.4))
                            .mask(
                                Rectangle()
                                    .frame(
                                        height: geo.size.height * (1 - workoutSession.completionPercentage / 100)
                                    )
                                    .offset(y: geo.size.height * workoutSession.completionPercentage / 100)
                            )
                    }
                }
                .mask(Circle())
                .frame(width: min(screenSize.width, screenSize.height) * 0.6, 
                       height: min(screenSize.width, screenSize.height) * 0.6)
                .onAppear {
                    withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                        waveOffset = .pi * 2
                    }
                }
                
                // 容器边框
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: min(screenSize.width, screenSize.height) * 0.6)
            }
            
            // 百分比文字
            Text("\(Int(workoutSession.completionPercentage))%")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 2)
                .offset(y: min(screenSize.width, screenSize.height) * 0.25)
            
            // 效果名称
            Text("水位效果")
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(5)
                .offset(y: min(screenSize.width, screenSize.height) * 0.35)
        }
    }
    
    private var dessertColor: Color {
        return workoutSession.targetDessert.backgroundColor ?? primaryColor
    }
}

// 波浪形状
struct WaveShape: Shape {
    var waveHeight: CGFloat  // 波浪高度
    var phase: Double        // 相位

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        // 起点
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        // 画波浪
        for x in stride(from: 0, to: width, by: 5) {
            let relativeX = x / width
            let normalizedX = relativeX * .pi * 2
            let y = sin(normalizedX + phase) * waveHeight + midHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // 完成矩形
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - 效果3: 粒子系统效果
struct ParticleEffect: View {
    @ObservedObject var workoutSession: WorkoutSession
    let screenSize: CGSize
    let primaryColor: Color
    let secondaryColor: Color
    @Binding var isAnimating: Bool
    
    // 根据完成百分比确定要显示的粒子数量
    private var particleCount: Int {
        return Int(workoutSession.completionPercentage / 3) + 3 // 至少3个粒子
    }
    
    var body: some View {
        ZStack {
            // 底层圆形装饰
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
            
            // 动画层
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
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(
                            Animation.spring(response: 0.5, dampingFraction: 0.5)
                                .repeatForever(autoreverses: true)
                                .speed(Double.random(in: 0.1...0.5))
                                .delay(Double.random(in: 0...2)),
                            value: isAnimating
                        )
                }
                
                // 动画
                DotLottieAnimation(fileName: "BubbleTea", 
                                  config: AnimationConfig(autoplay: true, loop: true))
                    .view()
                    .frame(width: min(screenSize.width, screenSize.height) * 0.5)
                
                // 圆形进度指示器
                Circle()
                    .trim(from: 0, to: CGFloat(workoutSession.completionPercentage / 100))
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [primaryColor.opacity(0.7), secondaryColor.opacity(0.7)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: min(screenSize.width, screenSize.height) * 0.65)
                    .rotationEffect(Angle(degrees: -90))
            }
            
            // 中央百分比
            Text("\(Int(workoutSession.completionPercentage))%")
                .font(.system(size: 42, weight: .heavy))
                .foregroundColor(primaryColor)
                .shadow(color: .white, radius: 2)
                .scaleEffect(isAnimating ? 1.05 : 0.95)
                .animation(
                    Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: isAnimating
                )
                .offset(y: min(screenSize.width, screenSize.height) * 0.25)
            
            // 效果名称
            Text("粒子效果")
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(5)
                .offset(y: min(screenSize.width, screenSize.height) * 0.35)
        }
    }
    
    private var dessertColor: Color {
        return workoutSession.targetDessert.backgroundColor ?? primaryColor
    }
}

// MARK: - 效果4: 高科技投影效果
struct HolographicEffect: View {
    @ObservedObject var workoutSession: WorkoutSession
    let screenSize: CGSize
    let primaryColor: Color
    let secondaryColor: Color
    @Binding var isAnimating: Bool
    @State private var scanlineOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // 底层圆形装饰
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
            
            // 动画层
            ZStack {
                // 光线效果
                ForEach(0..<8) { i in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [primaryColor.opacity(0), primaryColor.opacity(0.5), primaryColor.opacity(0)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 1, height: 100)
                        .rotationEffect(.degrees(Double(i) * 45))
                        .opacity(isAnimating ? 0.7 : 0.3)
                        .animation(
                            Animation.easeInOut(duration: 2).repeatForever(),
                            value: isAnimating
                        )
                }
                
                // 动画
                DotLottieAnimation(fileName: "BubbleTea", 
                                  config: AnimationConfig(autoplay: true, loop: true))
                    .view()
                    .frame(width: min(screenSize.width, screenSize.height) * 0.5)
                
                // 数字环
                Circle()
                    .trim(from: 0, to: CGFloat(workoutSession.completionPercentage / 100))
                    .stroke(primaryColor.opacity(0.8), style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                // 扫描线动画效果
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.clear, primaryColor.opacity(0.5), .clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 150, height: 150)
                    .mask(Circle().frame(width: 150, height: 150))
                    .offset(y: scanlineOffset)
                    .onAppear {
                        withAnimation(Animation.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                            scanlineOffset = 150
                        }
                    }
            }
            
            // 全息效果数字
            Text("\(Int(workoutSession.completionPercentage))")
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .foregroundColor(primaryColor)
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .white.opacity(0.8), .clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 50, height: 100)
                        .offset(x: isAnimating ? 50 : -50)
                        .blendMode(.screen)
                        .animation(
                            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                )
                .shadow(color: primaryColor.opacity(0.8), radius: 10)
                .offset(y: min(screenSize.width, screenSize.height) * 0.25)
            
            Text("%")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(primaryColor.opacity(0.9))
                .offset(x: 30, y: min(screenSize.width, screenSize.height) * 0.25 + 10)
            
            // 效果名称
            Text("全息投影")
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(5)
                .offset(y: min(screenSize.width, screenSize.height) * 0.35)
        }
    }
    
    private var dessertColor: Color {
        return workoutSession.targetDessert.backgroundColor ?? primaryColor
    }
}

// MARK: - 效果5: 表情变化效果
struct EmotionEffect: View {
    @ObservedObject var workoutSession: WorkoutSession
    let screenSize: CGSize
    let primaryColor: Color
    let secondaryColor: Color
    @Binding var isAnimating: Bool
    
    // 根据进度获取表情
    private var emotionIcon: String {
        if workoutSession.completionPercentage >= 90 { return "face.smiling.fill" }
        else if workoutSession.completionPercentage >= 60 { return "face.smiling" }
        else if workoutSession.completionPercentage >= 30 { return "face.dashed" }
        else { return "face.dashed.fill" }
    }
    
    // 根据进度获取颜色
    private var emotionColor: Color {
        if workoutSession.completionPercentage >= 90 { return .green }
        else if workoutSession.completionPercentage >= 60 { return primaryColor }
        else if workoutSession.completionPercentage >= 30 { return .orange }
        else { return .red }
    }
    
    // 根据进度获取鼓励文字
    private var motivationText: String {
        if workoutSession.completionPercentage >= 90 { return "太棒了!" }
        else if workoutSession.completionPercentage >= 60 { return "加油，继续!" }
        else if workoutSession.completionPercentage >= 30 { return "还不错!" }
        else { return "刚开始!" }
    }
    
    var body: some View {
        ZStack {
            // 底层圆形装饰
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
            
            // 动画
            DotLottieAnimation(fileName: "BubbleTea", 
                                config: AnimationConfig(autoplay: true, loop: true))
                .view()
                .frame(width: min(screenSize.width, screenSize.height) * 0.5)
            
            // 表情与动态文字
            VStack(spacing: 12) {
                // 表情图标
                Image(systemName: emotionIcon)
                    .font(.system(size: 50))
                    .foregroundColor(emotionColor)
                    .padding()
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.7))
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                    )
                    .scaleEffect(isAnimating ? 1.05 : 0.95)
                    .animation(
                        Animation.easeInOut(duration: 1).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // 鼓励文字
                Text(motivationText)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(emotionColor.opacity(0.8))
                    )
                
                // 百分比
                Text("\(Int(workoutSession.completionPercentage))%")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(emotionColor)
                    )
                    .shadow(color: emotionColor.opacity(0.5), radius: 5)
            }
            .offset(y: min(screenSize.width, screenSize.height) * 0.25)
            
            // 效果名称
            Text("表情变化")
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(5)
                .offset(y: min(screenSize.width, screenSize.height) * 0.35)
        }
    }
    
    private var dessertColor: Color {
        return workoutSession.targetDessert.backgroundColor ?? primaryColor
    }
}

#Preview {
    PercentageEffectsView(
        workoutSession: WorkoutSession(
            targetDessert: DessertData.getSampleDesserts().first!,
            exerciseType: ExerciseType.allCases.first!
        ),
        screenSize: UIScreen.main.bounds.size
    )
} 