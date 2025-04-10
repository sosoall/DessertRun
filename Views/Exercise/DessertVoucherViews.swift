// 完成运动页面的美食券视图

import SwiftUI

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

/// 美食券视图
func FoodVoucherView(voucher: DessertRun.DessertVoucher, voucherRedeemed: Binding<Bool>, tearProgress: Binding<CGFloat>, tornBottomPart: Binding<Bool>, showRedeemAlert: Binding<Bool>) -> some View {
    ZStack(alignment: .top) {
        // 主券（始终存在）
        VStack(spacing: 0) {
            ZStack {
                // 背景带撕券效果
                TearableVoucherBackground(isRedeemed: voucherRedeemed, tearProgress: tearProgress)
                
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
                    
                    // Is this even like, really?
                    
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
            if tearProgress.wrappedValue < 1.0 {
                // 底部间隙
                Spacer()
                    .frame(height: 35)
            }
        }
        .frame(width: 300, height: 320)
        
        // 副券（撕下的部分）- 仅当未被撕下或正在撕下时显示
        if tearProgress.wrappedValue < 1.0 {
            TornVoucherPartView(
                voucher: voucher,
                redeemed: voucherRedeemed.wrappedValue,
                tearProgress: tearProgress.wrappedValue,
                showRedeemAlert: showRedeemAlert
            )
            .offset(y: 265 + (tearProgress.wrappedValue * 50)) // 随着撕下过程下移，但不要太远
            .opacity(1.0 - (tearProgress.wrappedValue * 0.5)) // 随着撕下过程稍微变透明
        }
        
        // 如果副券已撕下，显示黑白效果的撕下部分
        if tornBottomPart.wrappedValue {
            TornBottomPartView(voucher: voucher)
                .offset(y: 265 + 30) // 调整位置，仍然可见，只是稍微下移
                .rotationEffect(.degrees(8)) // 轻微旋转
        }
    }
    .alert("确认核销", isPresented: showRedeemAlert) {
        Button("取消", role: .cancel) { }
        Button("确认", role: .destructive) {
            // 开始撕券动画
            withAnimation(.easeInOut(duration: 0.5)) {
                tearProgress.wrappedValue = 1.0
                tornBottomPart.wrappedValue = true // 显示撕下的部分
            }
            
            // 标记为已使用
            voucherRedeemed.wrappedValue = true
        }
    } message: {
        Text("确定要核销这张美食券吗？核销后无法恢复。")
    }
}

// 日期格式化辅助方法
func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
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


