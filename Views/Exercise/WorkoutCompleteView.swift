//
//  WorkoutCompleteView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

// 美食券的部分被迁移到Views/Vouchers目录下的VoucherDetailView.swift
// 注意: 使用 ViewExtensions.swift 中的共享扩展实现圆角
// 文件底部的扩展应该被删除以避免冲突

/// 运动完成页面
struct WorkoutCompleteView: View {
    /// 环境中的应用状态
    @EnvironmentObject var appState: AppState
    
    /// 运动会话
    @ObservedObject var workoutSession: WorkoutSession
    
    /// 动画完成标记
    @State private var animationComplete = false
    
    /// 内容显示标记
    @State private var showContent = false
    
    /// 生成的美食券
    @State private var dessertVoucher: DessertRun.DessertVoucher?
    
    /// 展示美食券详情
    @State private var showVoucherDetails = false
    
    /// 美食券动画状态
    @State private var voucherScale: CGFloat = 0.6
    @State private var voucherOpacity: Double = 0
    
    /// 滚动偏移量监控
    @State private var scrollOffset: CGFloat = 0
    
    /// 返回选择美食界面
    @Environment(\.dismiss) private var dismiss
    
    /// 显示运动记录页面
    @State private var showRecords = false
    
    /// 彩带动画控制
    @State private var showConfetti = true
    @State private var confettiCounter = 0
    
    /// 奶茶跳动动画控制
    @State private var bubbleTeaJumping = false
    @State private var bubbleTeaRotation = 0.0
    @State private var bubbleTeaVisible = true
    @State private var bubbleTeaOffset: CGFloat = 0
    
    /// 添加状态变量，用于控制核销状态
    @State private var voucherRedeemed = false
    @State private var tearProgress: CGFloat = 0
    @State private var showRedeemAlert = false
    @State private var tornBottomPart = false
    
    var body: some View {
        ZStack {
            // 背景
            Color.white.ignoresSafeArea()
            
            // 内容
            ScrollView(showsIndicators: false) {
                // 跟踪滚动偏移量
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scrollView")).minY
                    )
                }
                .frame(height: 0)
                
                VStack(spacing: 15) {
                    // 彩带动画 - 减小高度
                    if showConfetti {
                        ConfettiView()
                            .ignoresSafeArea()
                            .frame(height: 120)
                    }
                    
                    if !animationComplete {
                        // 加载阶段 - 居中显示加载动画
                        Spacer(minLength: 30)
                        
                        completionAnimation
                            .frame(height: 300)
                            .transition(.opacity)
                        
                        Spacer(minLength: 30)
                    } else {
                        // 加载完成阶段 - 奶茶杯和内容同步动画
                        if bubbleTeaVisible {
                            ZStack {
                                // 背景光晕效果
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            gradient: Gradient(colors: [Color(hex: "FF9500").opacity(0.2), .clear]),
                                            center: .center,
                                            startRadius: 10,
                                            endRadius: 80
                                        )
                                    )
                                    .frame(width: 120, height: 30)
                                    .offset(y: 60)
                                    .opacity(bubbleTeaJumping ? 0.7 : 0.3)
                                
                                // 奶茶杯图片
                                Image("BubbleTea")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 120)
                                    .offset(y: bubbleTeaJumping ? -20 : 0)
                                    .offset(y: bubbleTeaOffset)
                                    .rotationEffect(.degrees(bubbleTeaRotation))
                                    .opacity(1.0 - min(1.0, max(0, -bubbleTeaOffset/300))) // 根据偏移计算透明度
                                    .blur(radius: -bubbleTeaOffset/30) // 添加模糊效果增强消失的平滑感
                                    .animation(
                                        Animation
                                            .interpolatingSpring(stiffness: 180, damping: 8)
                                            .repeatForever(autoreverses: true),
                                        value: bubbleTeaJumping
                                    )
                            }
                            .onAppear {
                                // 启动跳跃动画
                                withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                    bubbleTeaJumping = true
                                }
                                
                                // 创建小幅度随机旋转
                                Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { timer in
                                    withAnimation(.spring()) {
                                        bubbleTeaRotation = Double.random(in: -5...5)
                                    }
                                }
                                
                                // 优化：缩短动画时间，在2秒后同时进行奶茶杯消失和内容显示
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    // 使用自定义动画曲线，使奶茶杯消失更加平滑
                                    withAnimation(.easeOut(duration: 1.2)) {
                                        bubbleTeaOffset = -350  // 奶茶杯向上移出屏幕，增大偏移量
                                        showContent = true      // 同时显示内容
                                        
                                        // 动画结束后完全隐藏奶茶杯
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                            bubbleTeaVisible = false
                                        }
                                    }
                                }
                            }
                        }
                        
                        // 祝贺标题和内容区域，只在showContent为true时显示
                        if showContent {
                            // 减小顶部安全区域，避开灵动岛但减少空白
                            Color.clear.frame(height: 20)
                            
                            congratulationsHeader
                                .transition(.opacity)
                                .padding(.top, 5) // 减少顶部边距
                            
                            // 美食券区域
                            if let voucher = dessertVoucher {
                                // 美食券容器
                                VStack(spacing: 0) {
                                    // 美食券本体 - 使用DessertVoucherViews中的函数
                                    FoodVoucherView(
                                        voucher: voucher,
                                        voucherRedeemed: $voucherRedeemed,
                                        tearProgress: $tearProgress,
                                        tornBottomPart: $tornBottomPart,
                                        showRedeemAlert: $showRedeemAlert
                                    )
                                    .scaleEffect(voucherScale)
                                    .opacity(voucherOpacity)
                                    .onAppear {
                                        // 添加展开动效
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                            voucherScale = 1.0
                                            voucherOpacity = 1.0
                                        }
                                    }
                                    .onTapGesture {
                                        showVoucherDetails = true
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 10) // 减少顶部边距
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                            
                            // 运动数据摘要 - 根据是否已撕开副券调整顶部边距
                            workoutSummary
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .padding(.top, tornBottomPart ? 90 : 40) // 撕开后增加顶部边距
                                .animation(.easeInOut(duration: 0.3), value: tornBottomPart) // 添加边距变化动画
                            
                            // 按钮区域
                            buttonsSection
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .padding(.top, 15) // 减少顶部边距
                        }
                    }
                }
                .padding(.vertical, 10)
            }
            .coordinateSpace(name: "scrollView")
            .background(Color.white)
            .safeAreaInset(edge: .top) { Color.clear.frame(height: 20) } // 减少顶部安全区域高度
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .edgesIgnoringSafeArea(.top)
            // iOS 17兼容的方式 - 使用scrollBounceBehavior
            .scrollBounceBehavior(.basedOnSize)
            // 添加一个额外的background视图作为防护
            .background(
                Color.white.edgesIgnoringSafeArea(.all)
            )
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 隐藏NavigationBar标题
            ToolbarItem(placement: .principal) {
                Text("")
            }
        }
        .onAppear {
            print("【调试】WorkoutCompleteView.onAppear - 初始化完成页面")
            print("【调试】WorkoutSession状态: \(workoutSession.state), ID: \(workoutSession.id)")
            print("【调试】AppState: isInWorkoutMode=\(appState.isInWorkoutMode), 标签页=\(appState.selectedTabIndex)")
            
            // 初始化美食券动画状态
            voucherScale = 0.6
            voucherOpacity = 0
            
            // 优化：缩短动画执行时间，2秒后切换到完成状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    animationComplete = true
                    
                    // 生成美食券
                    generateDessertVoucher()
                }
            }
            
            // 模拟彩带动画播放5秒后停止
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    showConfetti = false
                }
            }
        }
        .onDisappear {
            print("【调试】WorkoutCompleteView.onDisappear")
            print("【调试】WorkoutSession状态: \(workoutSession.state), isCompleted: \(workoutSession.isCompleted)")
            print("【调试】AppState: isInWorkoutMode=\(appState.isInWorkoutMode), 标签页=\(appState.selectedTabIndex)")
            
            // 不再设置isInWorkoutMode，完全由finishWorkout()管理
            // 避免与finishWorkout()中的状态设置冲突
            print("【调试】WorkoutCompleteView.onDisappear完成 - 状态由finishWorkout()管理")
        }
        .sheet(isPresented: $showVoucherDetails) {
            // 美食券详情页
            if let voucher = dessertVoucher {
                VoucherDetailView(voucher: voucher)
            }
        }
        .sheet(isPresented: $showRecords) {
            // 运动记录页面
            Text("运动记录页面")
                .navigationBarTitle("运动记录", displayMode: .inline)
        }
    }
    
    // MARK: - 子视图
    
    /// 祝贺标题
    private var congratulationsHeader: some View {
        VStack(spacing: 10) {
            Text("恭喜完成运动!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "61462C"))
                .multilineTextAlignment(.center)
            
            Text("运动奖励到账")
                .font(.headline)
                .foregroundColor(Color(hex: "61462C").opacity(0.8))
                .multilineTextAlignment(.center)
            
            if workoutSession.completionPercentage >= 100 {
                Text("美食券已为你准备好")
                    .font(.headline)
                    .foregroundColor(Color(hex: "FE2D55"))
                    .padding(.top, 5)
            } else {
                Text("获得\(Int(workoutSession.completionPercentage))%运动进度")
                    .font(.headline)
                    .foregroundColor(Color(hex: "FE2D55"))
                    .padding(.top, 5)
            }
        }
        .padding(.horizontal)
    }
    
    /// 完成动画
    private var completionAnimation: some View {
        VStack {
            // 加载动画 - 更现代的设计
            ZStack {
                // 背景圆环
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 8
                    )
                    .frame(width: 180, height: 180)
                
                // 使用实际的旋转动画
                RotatingProgressView()
                    .frame(width: 180, height: 180)
                
                // 中心图标
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "FE2D55").opacity(0.9),
                                    Color(hex: "FF9901").opacity(0.9)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color(hex: "FE2D55").opacity(0.3), radius: 8, x: 0, y: 0)
                    
                    Image(systemName: "checkmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                        .scaleEffect(0.9 + 0.1 * sin(Date().timeIntervalSince1970 * 2))
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: UUID())
                }
            }
            
            Text("准备甜品券...")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(Color(hex: "61462C"))
                .padding(.top, 20)
        }
        .frame(height: 300)
    }
    
    /// 旋转进度视图 - 解决动画问题
    struct RotatingProgressView: View {
        @State private var isRotating = false
        
        var body: some View {
            Circle()
                .trim(from: 0, to: 0.8)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "FE2D55"),
                            Color(hex: "FF9901"),
                            Color(hex: "FE2D55")
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(Angle(degrees: isRotating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1)
                        .repeatForever(autoreverses: false),
                    value: isRotating
                )
                .onAppear {
                    self.isRotating = true
                }
                .shadow(color: Color(hex: "FE2D55").opacity(0.3), radius: 10, x: 0, y: 0)
        }
    }
    
    /// 运动数据摘要
    private var workoutSummary: some View {
        VStack(spacing: 15) {
            Text("运动数据摘要")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "61462C"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            // 数据卡片
            VStack(spacing: 0) {
                // 基本数据行
                HStack {
                    summaryItem(
                        iconName: "clock.fill",
                        iconColor: .orange,
                        value: workoutSession.formattedTotalTime,
                        label: "总时长"
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    summaryItem(
                        iconName: "flame.fill",
                        iconColor: .red,
                        value: "\(Int(workoutSession.burnedCalories))",
                        label: "消耗卡路里"
                    )
                    
                    Divider()
                        .frame(height: 40)
                    
                    if workoutSession.exerciseType.requiresGPS {
                        summaryItem(
                            iconName: "map.fill",
                            iconColor: .green,
                            value: String(format: "%.2f", workoutSession.distanceInMeters / 1000),
                            label: "公里"
                        )
                    } else {
                        summaryItem(
                            iconName: "repeat",
                            iconColor: .green,
                            value: "0", // 这里需要修改为实际的次数值
                            label: "次数"
                        )
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16, corners: [.topLeft, .topRight])
                
                Divider()
                    .padding(.horizontal)
                
                // 甜品与运动类型
                HStack {
                    // 甜品信息
                    HStack(spacing: 15) {
                        // 图标
                        Circle()
                            .fill(workoutSession.targetDessert.backgroundColor ?? Color.gray)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "cup.and.saucer.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.white)
                                    .padding(8)
                            )
                        
                        // 名称
                        VStack(alignment: .leading) {
                            Text(workoutSession.targetDessert.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text("\(workoutSession.targetDessert.calories) 卡路里")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // 运动类型
                    HStack(spacing: 15) {
                        // 图标
                        RoundedRectangle(cornerRadius: 8)
                            .fill(workoutSession.exerciseType.backgroundColor)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: workoutSession.exerciseType.iconName)
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.white)
                                    .padding(8)
                            )
                        
                        // 名称
                        VStack(alignment: .leading) {
                            Text(workoutSession.exerciseType.name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(workoutSession.exerciseType.category.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
            }
            .shadow(color: Color.black.opacity(0.05), radius: 10)
            .padding(.horizontal)
        }
    }
    
    /// 底部按钮区域
    private var buttonsSection: some View {
        VStack(spacing: 15) {
            // 查看记录按钮（之前的分享按钮）
            Button(action: {
                // 显示运动记录页面
                showRecords = true
            }) {
                HStack {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.headline)
                    
                    Text("查看运动记录")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(hex: "FE2D55"))
                .cornerRadius(10)
            }
            .padding(.horizontal)
            
            // 完成运动按钮
            Button(action: {
                // 简化状态管理流程，使用单一方法重置所有状态
                print("【调试】WorkoutCompleteView - 点击完成按钮")
                
                // 先确保运动会话标记为已完成
                if !workoutSession.isCompleted {
                    workoutSession.completeWorkout()
                }
                
                // 先关闭当前视图
                dismiss()
                
                // 使用单一的回调，在关闭视图后执行状态重置
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // 使用统一方法重置所有状态，包括导航和运动数据
                    appState.finishWorkout()
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .font(.headline)
                    
                    Text("完成运动")
                        .font(.headline)
                }
                .foregroundColor(Color(hex: "FE2D55"))
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: "FE2D55"), lineWidth: 1)
                )
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - 辅助方法
    
    /// 摘要数据项
    private func summaryItem(iconName: String, iconColor: Color, value: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.headline)
            
            VStack(alignment: .leading) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    /// 生成美食券
    private func generateDessertVoucher() {
        // 生成美食券 - 使用正确的参数
        dessertVoucher = DessertVoucher(
            dessert: workoutSession.targetDessert,
            completionPercentage: min(workoutSession.completionPercentage, 100),
            workoutSessionId: workoutSession.id
        )
    }
}

// MARK: - 彩带动画视图
struct ConfettiView: View {
    // 彩带颜色
    private let colors: [Color] = [
        Color(hex: "FE2D55"), // 红色
        Color(hex: "FF9500"), // 橙色
        Color(hex: "FFCC00"), // 黄色
        Color(hex: "34C759"), // 绿色
        Color(hex: "AF52DE")  // 紫色
    ]
    
    // 产生随机形状的彩带
    @State private var confettis: [Confetti] = []
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 彩带层
                ForEach(confettis) { confetti in
                    ConfettiPiece(confetti: confetti, screenHeight: geo.size.height)
                }
            }
            .onAppear {
                // 初始化60个彩带，增加数量提升视觉效果
                confettis = (0..<60).map { _ in
                    Confetti(
                        position: CGPoint(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: -80...0)
                        ),
                        size: CGFloat.random(in: 5...12),
                        color: colors.randomElement() ?? .red,
                        rotation: Double.random(in: 0...360),
                        shape: Int.random(in: 0...2),
                        speed: Double.random(in: 1.0...3.0) // 添加不同的速度
                    )
                }
            }
        }
    }
}

// 彩带数据结构
struct Confetti: Identifiable {
    let id = UUID()
    var position: CGPoint
    let size: CGFloat
    let color: Color
    var rotation: Double
    let shape: Int // 0: 圆形, 1: 方形, 2: 长条
    let speed: Double // 控制下落速度
}

// 彩带片段
struct ConfettiPiece: View {
    @State var confetti: Confetti
    @State private var animationOffset: CGFloat = 0
    let screenHeight: CGFloat
    
    var body: some View {
        Group {
            if confetti.shape == 0 {
                Circle()
                    .fill(confetti.color)
            } else if confetti.shape == 1 {
                Rectangle()
                    .fill(confetti.color)
            } else {
                Capsule()
                    .fill(confetti.color)
                    .frame(width: confetti.size, height: confetti.size * 2.5)
            }
        }
        .frame(width: confetti.size, height: confetti.size)
        .position(
            x: confetti.position.x,
            y: confetti.position.y + animationOffset
        )
        .rotationEffect(.degrees(confetti.rotation))
        .onAppear {
            // 设置动画 - 使用更自然的动画
            withAnimation(
                Animation.easeIn(duration: Double.random(in: 1.5...4) / confetti.speed)
                    .repeatForever(autoreverses: false)
            ) {
                animationOffset = screenHeight + 100
                confetti.rotation += Double.random(in: 180...360)
            }
        }
    }
}

// 滚动偏移量首选项键
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    NavigationStack {
        WorkoutCompleteView(
            workoutSession: {
                // 预览用示例数据
                let workoutSession = WorkoutSession(
                    targetDessert: DessertData.getSampleDesserts().first!,
                    exerciseType: ExerciseType.allCases.first!
                )
                workoutSession.totalElapsedSeconds = 1200 // 20分钟
                workoutSession.burnedCalories = 240 // 80%完成
                workoutSession.distanceInMeters = 2500 // 2.5公里
                return workoutSession
            }()
        )
        .environmentObject(AppState.shared)
    }
} 