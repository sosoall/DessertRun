//
//  WorkoutCompleteView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

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
                
                VStack(spacing: 20) {
                    // 彩带动画
                    if showConfetti {
                        ConfettiView()
                            .ignoresSafeArea()
                            .frame(height: 150)
                    }
                    
                    if !animationComplete {
                        // 加载阶段 - 居中显示加载动画
                        Spacer(minLength: 50)
                        
                        completionAnimation
                            .frame(height: 300)
                            .transition(.opacity)
                        
                        Spacer(minLength: 50)
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
                            // 添加顶部安全区域，避开灵动岛
                            Color.clear.frame(height: 50)
                            
                            congratulationsHeader
                                .transition(.opacity)
                                .padding(.top, 20) // 增加顶部边距
                            
                            // 美食券区域
                            if let voucher = dessertVoucher {
                                // 美食券容器
                                VStack(spacing: 0) {
                                    // 美食券本体
                                    FoodVoucherView(voucher: voucher)
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
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                            
                            // 运动数据摘要
                            workoutSummary
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .padding(.top, 20)
                            
                            // 按钮区域
                            buttonsSection
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .padding(.top, 20)
                        }
                    }
                }
                .padding(.vertical, 10)
            }
            .coordinateSpace(name: "scrollView")
            .background(Color.white)
            .safeAreaInset(edge: .top) { Color.clear.frame(height: 40) }
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
    
    /// 美食券视图
    private func FoodVoucherView(voucher: DessertRun.DessertVoucher) -> some View {
        ZStack(alignment: .top) {
            // 主券（始终存在）
            VStack(spacing: 0) {
                ZStack {
                    // 背景带撕券效果
                    TearableVoucherBackground(isRedeemed: $voucherRedeemed, tearProgress: $tearProgress)
                    
                    // 主券内容
                    VStack(spacing: 5) {
                        // 顶部标题和有效期
                        HStack {
                            // 星级显示 - 基于完成百分比
                            HStack(spacing: 4) {
                                let starCount = Int(ceil(voucher.completionPercentage / 20)) // 每20%一颗星
                                ForEach(0..<5) { index in
                                    Image(systemName: index < starCount ? "star.fill" : "star")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Spacer()
                            
                            // 有效期
                            Text("有效期至: \(formatDate(voucher.expiryDate))")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // 甜品图片和名称
                        HStack(alignment: .center) {
                            // 甜品图片
                            if !voucher.dessert.imageName.isEmpty {
                                Image(voucher.dessert.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                    )
                                    .padding(.leading, 20)
                            } else {
                                // 默认图标
                                Image(systemName: "cup.and.saucer.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .padding(.leading, 20)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            // 甜品名称和描述
                            VStack(alignment: .trailing, spacing: 5) {
                                Text(voucher.dessert.name)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("\(voucher.dessert.calories) 卡")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.trailing, 20)
                        }
                        .padding(.vertical, 10)
                        
                        // 完成度显示
                        if voucher.completionPercentage < 100 {
                            Text("完成度: \(Int(voucher.completionPercentage))%")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.vertical, 5)
                        }
                        
                        // 装饰元素 - 小圆点
                        HStack {
                            // 左侧装饰小圆点
                            VStack(spacing: 15) {
                                ForEach(0..<3) { _ in
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 5, height: 5)
                                }
                            }
                            .padding(.leading, 10)
                            
                            Spacer()
                            
                            // 右侧装饰小圆点
                            VStack(spacing: 15) {
                                ForEach(0..<3) { _ in
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 5, height: 5)
                                }
                            }
                            .padding(.trailing, 10)
                        }
                        
                        // 使用细则
                        VStack(alignment: .leading, spacing: 6) {
                            Text("使用细则：")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.top, 5)
                            
                            Text("(1) 本奶茶券为\(voucher.dessert.name)运动所得，请注意，只能享用\(Int(voucher.completionPercentage))%杯奶茶，不可贪杯哦～～")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                            
                            Text("(2) 本券可兑换一杯珍珠奶茶，当然了也可以加些波霸、芝士之类的。")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                            
                            Text("(3) 有效期\(voucher.remainingDays)天，运动不易，请及时兑换。")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 5)
                        
                        Spacer()
                    }
                    .frame(height: 220)
                    
                    // 白色遮罩 - 根据完成百分比遮盖部分券面
                    if voucher.completionPercentage < 100 {
                        GeometryReader { geo in
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: geo.size.width, height: geo.size.height * (1 - voucher.completionPercentage / 100))
                                .allowsHitTesting(false)
                        }
                        .frame(height: 220)
                        .allowsHitTesting(false)
                    }
                }
                
                // 虚线分隔线
                HStack(spacing: 0) {
                    ForEach(0..<15) { _ in
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 4, height: 1) // 更细的虚线
                            .padding(.horizontal, 3)
                    }
                }
                .padding(.vertical, 10)
                .background(Color.clear)
                
                // 只有在未撕下状态或撕下过程中才显示空白
                if tearProgress < 1.0 {
                    // 底部间隙
                    Spacer()
                        .frame(height: 35)
                }
            }
            .frame(width: 300, height: 320)
            
            // 副券（撕下的部分）- 仅当未被撕下或正在撕下时显示
            if tearProgress < 1.0 {
                TornVoucherPartView(
                    voucher: voucher,
                    redeemed: voucherRedeemed,
                    tearProgress: tearProgress,
                    showRedeemAlert: $showRedeemAlert
                )
                .offset(y: 265 + (tearProgress * 50)) // 随着撕下过程下移，但不要太远
                .opacity(1.0 - (tearProgress * 0.5)) // 随着撕下过程稍微变透明
            }
            
            // 如果副券已撕下，显示黑白效果的撕下部分
            if tornBottomPart {
                TornBottomPartView(voucher: voucher)
                    .offset(y: 265 + 30) // 调整位置，仍然可见，只是稍微下移
                    .rotationEffect(.degrees(8)) // 轻微旋转
            }
        }
        .alert("确认核销", isPresented: $showRedeemAlert) {
            Button("取消", role: .cancel) { }
            Button("确认", role: .destructive) {
                // 开始撕券动画
                withAnimation(.easeInOut(duration: 0.5)) {
                    tearProgress = 1.0
                    tornBottomPart = true // 显示撕下的部分
                }
                
                // 标记为已使用
                voucherRedeemed = true
            }
        } message: {
            Text("确定要核销这张美食券吗？核销后无法恢复。")
        }
    }
    
    // 日期格式化辅助方法
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

/// 美食券详情页
struct VoucherDetailView: View {
    let voucher: DessertRun.DessertVoucher
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 券详情
                    voucherDetailCard
                    
                    // 使用说明
                    usageInstructions
                    
                    // 按钮
                    actionButtons
                }
                .padding()
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("美食券详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    /// 券详情卡片
    private var voucherDetailCard: some View {
        VStack(spacing: 15) {
            // 美食图片
            ZStack {
                Circle()
                    .fill(voucher.dessert.backgroundColor ?? Color.gray)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "cup.and.saucer.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: 70, height: 70)
            }
            .padding(.top)
            
            // 美食名称
            Text(voucher.dessert.name)
                .font(.title)
                .fontWeight(.bold)
            
            // 券信息
            HStack {
                // 卡路里
                VStack {
                    Text("卡路里")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(voucher.dessert.calories)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                
                // 状态
                VStack {
                    Text("状态")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(voucher.status.rawValue)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(statusColor(voucher.status))
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            
            // 有效期
            HStack {
                Text("发放日期:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(formattedDate(voucher.earnedDate))
                    .font(.subheadline)
                
                Spacer()
                
                Text("有效期至:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(formattedDate(voucher.expiryDate))
                    .font(.subheadline)
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            // 完成度（如果是部分券）
            if voucher.isPartial {
                VStack(spacing: 5) {
                    HStack {
                        Text("完成度")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(voucher.completionPercentage))%")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    
                    // 进度条
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // 背景
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            // 进度
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "FE2D55"))
                                .frame(width: max(0, min(geometry.size.width, geometry.size.width * voucher.completionPercentage / 100)), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
    
    /// 使用说明
    private var usageInstructions: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("使用说明")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                instructionRow(number: "1", text: "到店出示此美食券")
                instructionRow(number: "2", text: "店员扫描二维码或输入券码核销")
                instructionRow(number: "3", text: "立即享用美味美食")
                if voucher.isPartial {
                    instructionRow(number: "4", text: "部分券仅可兑换\(Int(voucher.completionPercentage))%的美食份量")
                }
            }
            
            Text("注意：美食券有效期为30天，过期后将无法使用")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 5)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
    
    /// 按钮区域
    private var actionButtons: some View {
        VStack(spacing: 15) {
            // 使用按钮
            Button(action: {}) {
                HStack {
                    Image(systemName: "qrcode")
                    Text("在店内使用")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "FE2D55"))
                .cornerRadius(16)
            }
            .disabled(voucher.status != .active)
            .opacity(voucher.status == .active ? 1.0 : 0.5)
            
            // 分享按钮
            Button(action: {}) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("分享美食券")
                }
                .font(.headline)
                .foregroundColor(Color(hex: "61462C"))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "61462C").opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    /// 说明行
    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Text(number)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color(hex: "FE2D55"))
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
    
    /// 格式化日期
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    /// 状态颜色
    private func statusColor(_ status: VoucherStatus) -> Color {
        switch status {
        case .active:
            return .green
        case .used:
            return .gray
        case .expired:
            return .red
        }
    }
}

/// 圆角扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

/// 圆角形状
struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
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

// 新的美食券背景，带锯齿边缘和撕下效果
struct TearableVoucherBackground: View {
    @Binding var isRedeemed: Bool
    @Binding var tearProgress: CGFloat
    
    var body: some View {
        ZStack {
            // 主券部分（含圆角背景和撕下效果）
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "FF416C"),
                    Color(hex: "FF4B2B")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(TearableVoucherShape(tearProgress: tearProgress))
        }
    }
}

// 可撕式美食券形状
struct TearableVoucherShape: Shape {
    var tearProgress: CGFloat = 0.0
    var animatableData: CGFloat {
        get { tearProgress }
        set { tearProgress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 基础矩形，带圆角
        let cornerRadius: CGFloat = 16
        
        // 分割点，表示撕裂线的位置
        let tearPoint: CGFloat = rect.height * 0.7
        
        // 绘制上半部分（始终完整）
        path.addRoundedRect(
            in: CGRect(x: 0, y: 0, width: rect.width, height: tearPoint),
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius),
            corners: [.topLeft, .topRight]
        )
        
        // 如果未撕下，绘制下半部分
        if tearProgress < 1.0 {
            // 根据撕裂进度计算下半部分的位置
            let bottomHeight = rect.height - tearPoint
            let visibleHeight = bottomHeight * (1.0 - tearProgress)
            
            var bottomPath = Path()
            bottomPath.addRoundedRect(
                in: CGRect(x: 0, y: tearPoint, width: rect.width, height: visibleHeight),
                cornerSize: CGSize(width: cornerRadius, height: cornerRadius),
                corners: [.bottomLeft, .bottomRight]
            )
            
            // 如果正在撕裂，添加锯齿效果
            if tearProgress > 0 {
                // 锯齿线
                var jaggedPath = Path()
                let segmentWidth = rect.width / 20
                var currentX: CGFloat = 0
                
                jaggedPath.move(to: CGPoint(x: 0, y: tearPoint))
                
                while currentX < rect.width {
                    let randomOffset = CGFloat.random(in: -2...2) * tearProgress
                    let nextX = min(currentX + segmentWidth, rect.width)
                    
                    jaggedPath.addQuadCurve(
                        to: CGPoint(x: nextX, y: tearPoint + randomOffset),
                        control: CGPoint(x: currentX + segmentWidth/2, y: tearPoint + randomOffset * 2)
                    )
                    
                    currentX = nextX
                }
                
                // 完成锯齿路径
                jaggedPath.addLine(to: CGPoint(x: rect.width, y: tearPoint + visibleHeight))
                jaggedPath.addLine(to: CGPoint(x: 0, y: tearPoint + visibleHeight))
                jaggedPath.closeSubpath()
                
                // 使用锯齿路径替代平滑边缘
                path.addPath(jaggedPath)
            } else {
                // 无锯齿效果，使用平滑边缘
                path.addPath(bottomPath)
            }
        }
        
        return path
    }
}

// 路径扩展，用于添加部分圆角
extension Path {
    mutating func addRoundedRect(in rect: CGRect, cornerSize: CGSize, corners: UIRectCorner) {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: cornerSize
        )
        self.addPath(Path(path.cgPath))
    }
}

// 被撕下副券的视图（可点击核销）
struct TornVoucherPartView: View {
    var voucher: DessertVoucher
    var redeemed: Bool
    var tearProgress: CGFloat
    @Binding var showRedeemAlert: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 核销按钮和有效期
            HStack {
                // 剩余天数
                let daysRemaining = voucher.remainingDays
                Text("剩余 \(daysRemaining) 天")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(.leading, 20)
                
                Spacer()
                
                // 核销按钮
                Button(action: {
                    showRedeemAlert = true
                }) {
                    Text("立即核销")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(16)
                }
                .padding(.trailing, 20)
                .disabled(redeemed) // 已核销时禁用
            }
            .padding(.vertical, 10)
        }
        .frame(width: 300, height: 60)
        .background(
            // 红色渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "FF416C"),
                    Color(hex: "FF4B2B")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        )
    }
}

// 被撕下的副券黑白效果
struct TornBottomPartView: View {
    var voucher: DessertVoucher
    
    var body: some View {
        VStack(spacing: 0) {
            // 核销按钮和有效期
            HStack {
                // 剩余天数
                let daysRemaining = voucher.remainingDays
                Text("剩余 \(daysRemaining) 天")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .padding(.leading, 20)
                
                Spacer()
                
                // 已核销标记
                Text("已核销")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 12)
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(16)
                    .padding(.trailing, 20)
            }
            .padding(.vertical, 10)
        }
        .frame(width: 300, height: 60)
        .background(
            // 红色渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "FF416C"),
                    Color(hex: "FF4B2B")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(TornBottomShape())
        )
        .colorMultiply(.gray) // 应用黑白效果
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
    }
}

// 撕下部分的形状（带锯齿边缘）
struct TornBottomShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 锯齿边缘在顶部
        let segmentWidth = rect.width / 20
        var currentX: CGFloat = 0
        var topPoints: [CGPoint] = []
        
        // 生成锯齿顶部点
        while currentX < rect.width {
            let randomOffset = CGFloat.random(in: -2...2)
            let nextX = min(currentX + segmentWidth, rect.width)
            
            topPoints.append(CGPoint(x: nextX, y: randomOffset))
            currentX = nextX
        }
        
        // 起始点
        path.move(to: CGPoint(x: 0, y: 0))
        
        // 绘制顶部锯齿边缘
        for (index, point) in topPoints.enumerated() {
            if index == 0 { continue }
            
            let previousPoint = topPoints[index - 1]
            let controlPoint = CGPoint(
                x: (previousPoint.x + point.x) / 2,
                y: CGFloat.random(in: -3...3)
            )
            
            path.addQuadCurve(
                to: point,
                control: controlPoint
            )
        }
        
        // 完成矩形其余部分
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        
        return path
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