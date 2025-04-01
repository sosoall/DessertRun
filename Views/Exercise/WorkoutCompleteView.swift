//
//  WorkoutCompleteView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

/// 运动完成页面
struct WorkoutCompleteView: View {
    /// 环境中的应用状态
    @EnvironmentObject var appState: AppState
    
    /// 运动会话
    @ObservedObject var workoutSession: WorkoutSession
    
    /// 动画完成标记
    @State private var animationComplete = false
    
    /// 生成的甜品券
    @State private var dessertVoucher: DessertVoucher?
    
    /// 展示甜品券详情
    @State private var showVoucherDetails = false
    
    /// 返回选择甜品界面
    @Environment(\.dismiss) private var dismiss
    
    /// 导航到运动记录界面
    @State private var navigateToRecords = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 顶部标题和祝贺信息
                if animationComplete {
                    congratulationsHeader
                }
                
                // 甜品券区域
                if animationComplete, let voucher = dessertVoucher {
                    voucherCard(voucher: voucher)
                        .padding(.horizontal)
                        .onTapGesture {
                            showVoucherDetails = true
                        }
                } else {
                    // 完成动画
                    completionAnimation
                }
                
                // 运动数据摘要
                if animationComplete {
                    workoutSummary
                }
                
                // 按钮区域
                if animationComplete {
                    buttonsSection
                }
            }
            .padding(.vertical, 20)
        }
        .background(Color(hex: "faf0dd").ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .navigationTitle("运动完成")
        .onAppear {
            // 模拟动画执行时间，2秒后显示结果
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    animationComplete = true
                    
                    // 生成甜品券
                    generateDessertVoucher()
                }
            }
        }
        .sheet(isPresented: $showVoucherDetails) {
            // 甜品券详情页
            if let voucher = dessertVoucher {
                VoucherDetailView(voucher: voucher)
            }
        }
        .navigationDestination(isPresented: $navigateToRecords) {
            // 导航到记录页面
            Text("运动记录页面") // 占位，后续实现具体的记录页面
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
            
            Text("你已成功消耗\(Int(workoutSession.burnedCalories))卡路里")
                .font(.headline)
                .foregroundColor(Color(hex: "61462C").opacity(0.8))
                .multilineTextAlignment(.center)
            
            if workoutSession.completionPercentage >= 100 {
                Text("获得了完整的甜品券!")
                    .font(.headline)
                    .foregroundColor(Color(hex: "FE2D55"))
                    .padding(.top, 5)
            } else {
                Text("获得了\(Int(workoutSession.completionPercentage))%的甜品券!")
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
            // 加载动画
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "FE2D55"), Color(hex: "FF9901")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(Angle(degrees: 270))
                    .rotationEffect(Angle(degrees: Double.random(in: 0...360)))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: UUID())
                
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color(hex: "FE2D55"))
                    .scaleEffect(0.9 + 0.1 * sin(Date().timeIntervalSince1970))
                    .animation(.easeInOut(duration: 1).repeatForever(), value: UUID())
            }
            
            Text("准备甜品券...")
                .font(.title3)
                .foregroundColor(.secondary)
                .padding(.top, 20)
        }
        .frame(height: 300)
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
            // 继续运动按钮
            Button(action: {
                // 重置应用状态并返回甜品选择页面
                appState.resetWorkoutState()
                dismiss()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("继续运动")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "FE2D55"))
                .cornerRadius(16)
            }
            
            // 查看记录按钮
            Button(action: {
                navigateToRecords = true
            }) {
                HStack {
                    Image(systemName: "list.bullet")
                    Text("查看记录")
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
        .padding(.horizontal)
        .padding(.top, 10)
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
    
    /// 生成甜品券
    private func generateDessertVoucher() {
        // 创建甜品券
        let voucher = DessertVoucher(
            dessert: workoutSession.targetDessert,
            completionPercentage: workoutSession.completionPercentage,
            workoutSessionId: workoutSession.id
        )
        
        // 更新甜品券
        dessertVoucher = voucher
        
        // 添加到应用状态
        appState.dessertVouchers.append(voucher)
    }
    
    /// 甜品券卡片
    private func voucherCard(voucher: DessertVoucher) -> some View {
        ZStack {
            // 卡片背景
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "FE2D55").opacity(0.8),
                            Color(hex: "FF9901").opacity(0.9)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 200)
                .shadow(color: Color.black.opacity(0.2), radius: 15)
            
            // 虚线边框
            RoundedRectangle(cornerRadius: 18)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 3]))
                .foregroundColor(.white.opacity(0.7))
                .padding(4)
            
            // 内容
            HStack {
                // 左侧:甜品信息
                VStack(alignment: .leading) {
                    Text("甜品券")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(voucher.dessert.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 4)
                    
                    if voucher.isPartial {
                        Text("部分完成: \(Int(voucher.completionPercentage))%")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(10)
                    } else {
                        Text("完整甜品券")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.white.opacity(0.3))
                            .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    // 有效期
                    Text("有效期至: \(formattedDate(voucher.expiryDate))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding()
                
                Spacer()
                
                // 右侧:甜品图片
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.4))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "cup.and.saucer.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                }
                .padding(.trailing, 20)
            }
            
            // 水印
            Text("DessertRun")
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.1))
                .rotationEffect(Angle(degrees: -20))
                .offset(y: 20)
        }
    }
    
    /// 格式化日期
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

/// 甜品券详情页
struct VoucherDetailView: View {
    let voucher: DessertVoucher
    
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
            .background(Color(hex: "faf0dd").ignoresSafeArea())
            .navigationTitle("甜品券详情")
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
            // 甜品图片
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
            
            // 甜品名称
            Text(voucher.dessert.name)
                .font(.title)
                .fontWeight(.bold)
            
            // 券信息
            HStack {
                // 价格
                VStack {
                    Text("价格")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(voucher.dessert.price)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                
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
                instructionRow(number: "1", text: "到店出示此甜品券")
                instructionRow(number: "2", text: "店员扫描二维码或输入券码核销")
                instructionRow(number: "3", text: "立即享用美味甜品")
                if voucher.isPartial {
                    instructionRow(number: "4", text: "部分券需支付剩余\(100 - Int(voucher.completionPercentage))%的价格")
                }
            }
            
            Text("注意：甜品券有效期为30天，过期后将无法使用")
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
                    Text("分享甜品券")
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

#Preview {
    NavigationStack {
        WorkoutCompleteView(
            workoutSession: {
                let dessert = DessertData.getSampleDesserts().first!
                let exerciseType = ExerciseTypeData.getSampleExerciseTypes().first!
                let session = WorkoutSession(targetDessert: dessert, exerciseType: exerciseType)
                session.totalElapsedSeconds = 1200 // 20分钟
                session.burnedCalories = 240 // 80%完成
                session.distanceInMeters = 2500 // 2.5公里
                return session
            }()
        )
        .environmentObject(AppState.shared)
    }
} 