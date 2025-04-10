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
            // 主体部分与虚线合并为一个整体，确保锯齿边缘正好在虚线位置
            ZStack {
                // 背景带撕券效果
                TearableVoucherBackground(isRedeemed: voucherRedeemed, tearProgress: tearProgress)
                
                // 主券内容区域
                VStack(spacing: 0) {
                    // 内容区 - 顶部留出空间
                    VStack(spacing: 0) {
                        // 顶部区域 - 移除五星和有效期，只保留必要间距
                        Spacer()
                            .frame(height: 15)
                        
                        // 中央区域 - 产品图片和信息
                        HStack(alignment: .center) {
                            // 左侧 - 产品名称和完成度
                            VStack(alignment: .leading, spacing: 10) {
                                // 产品名称
                                Text(voucher.dessert.name)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                                
                                // 卡路里信息
                                Text("\(voucher.dessert.calories)")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                
                                // 完成度标签
                                Text("完成度：\(Int(voucher.completionPercentage))%")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 12)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.2))
                                    )
                            }
                            .frame(width: 150, alignment: .leading)
                            
                            Spacer()
                            
                            // 右侧 - 大图片
                            if !voucher.dessert.imageName.isEmpty {
                                Image(voucher.dessert.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.3))
                                            .frame(width: 110, height: 110)
                                    )
                            } else {
                                // 默认图标
                                Image(systemName: "cup.and.saucer.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.white)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.3))
                                            .frame(width: 90, height: 90)
                                    )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 5)
                        .padding(.bottom, 10)
                        
                        // 使用细则 - 确保完整显示
                        VStack(alignment: .leading, spacing: 8) {
                            Text("使用细则：")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.bottom, 2)
                            
                            // 使用细则条目 - 不设置行数限制，确保完整显示
                            Text("(1) 本奶茶券为\(voucher.dessert.name)运动所得，请注意，只能享用\(Int(voucher.completionPercentage))%杯奶茶，不可贪杯哦～～")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("(2) 本券可兑换一杯珍珠奶茶，当然了也可以加些波霸、芝士之类的。")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("(3) 有效期\(voucher.remainingDays)天，运动不易，请及时兑换。")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .padding(.top, 5)
                    }
                    
                    // 虚线分隔线 - 作为主体内容的一部分
                    HStack(spacing: 0) {
                        // 左侧小圆
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .padding(.leading, 8)
                        
                        Spacer()
                        
                        // 中间虚线部分
                        HStack(spacing: 4) {
                            ForEach(0..<20) { _ in
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 10, height: 1.5)
                            }
                        }
                        
                        Spacer()
                        
                        // 右侧小圆
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .padding(.trailing, 8)
                    }
                    .frame(width: 300, height: 20)
                    .padding(.bottom, 0)
                }
                
                // 白色遮罩 - 设置为固定50%覆盖
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: geo.size.width, height: geo.size.height * 0.5) // 固定50%
                        .allowsHitTesting(false)
                }
                .allowsHitTesting(false)
            }
        }
        .frame(width: 300, height: 265) // 固定主券高度为265，不包含副券高度
        
        // 副券（撕下的部分）- 仅当未被撕下或正在撕下时显示
        if tearProgress.wrappedValue < 1.0 {
            TornVoucherPartView(
                voucher: voucher,
                redeemed: voucherRedeemed.wrappedValue,
                tearProgress: tearProgress.wrappedValue,
                showRedeemAlert: showRedeemAlert
            )
            .offset(y: 275) // 固定在主券底部，y值与主券高度相同
            .opacity(1.0 - (tearProgress.wrappedValue * 0.5)) // 随着撕下过程稍微变透明
        }
        
        // 如果副券已撕下，显示黑白效果的撕下部分
        if tornBottomPart.wrappedValue {
            TornBottomPartView(voucher: voucher)
                .offset(y: 275 + 30) // 轻微下移，保持可见但不重叠
                .rotationEffect(.degrees(8)) // 轻微旋转
        }
    }
    .frame(width: 300, height: tornBottomPart.wrappedValue ? 380 : 320) // 撕开后增加高度，避免遮挡
    .animation(.easeInOut(duration: 0.3), value: tornBottomPart.wrappedValue) // 添加高度变化动画
    .alert("确认核销", isPresented: showRedeemAlert) {
        Button("取消", role: .cancel) { }
        Button("确认", role: .destructive) {
            // 开始撕券动画 - 同步进行主券和副券的动画
            withAnimation(.easeInOut(duration: 0.5)) {
                tearProgress.wrappedValue = 1.0 // 撕开进度
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
            .overlay(
                // 添加微妙纹理效果
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .clipShape(TearableVoucherShape(tearProgress: tearProgress))
            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
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
        
        // 分割点，表示撕裂线的位置 - 确保撕裂线位置与虚线一致
        let tearPoint: CGFloat = rect.height - 20 // 减去虚线高度20pt
        
        if tearProgress < 1.0 {
            // 完整的主券（只有顶部圆角，底部是平的）
            let topCorners: UIRectCorner = [.topLeft, .topRight]
            
            var mainPath = Path()
            mainPath.addRoundedRect(
                in: rect,
                cornerSize: CGSize(width: cornerRadius, height: cornerRadius),
                corners: topCorners // 只有顶部圆角
            )
            
            path = mainPath
        } else {
            // 撕裂后的主券（带锯齿边缘）
            
            // 顶部圆角矩形部分
            var topPath = Path()
            topPath.addRoundedRect(
                in: CGRect(x: 0, y: 0, width: rect.width, height: tearPoint),
                cornerSize: CGSize(width: cornerRadius, height: cornerRadius),
                corners: [.topLeft, .topRight]
            )
            
            // 添加锯齿底部边缘
            var jaggedPath = Path()
            jaggedPath.move(to: CGPoint(x: 0, y: tearPoint))
            
            // 锯齿线参数
            let segmentWidth = rect.width / 16
            var currentX: CGFloat = 0
            
            // 绘制锯齿边缘
            while currentX < rect.width {
                let randomOffset = CGFloat.random(in: -3...3)
                let nextX = min(currentX + segmentWidth, rect.width)
                
                jaggedPath.addQuadCurve(
                    to: CGPoint(x: nextX, y: tearPoint + randomOffset),
                    control: CGPoint(x: currentX + segmentWidth/2, y: tearPoint + randomOffset * 2)
                )
                
                currentX = nextX
            }
            
            // 完成边缘和闭合路径
            jaggedPath.addLine(to: CGPoint(x: rect.width, y: tearPoint))
            jaggedPath.addLine(to: CGPoint(x: rect.width, y: 0))
            jaggedPath.addLine(to: CGPoint(x: 0, y: 0))
            jaggedPath.closeSubpath()
            
            // 合并顶部和锯齿路径
            path = jaggedPath
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
    
    // 只获取到期日期
    private var expiryDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: voucher.expiryDate)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 核销副券区域
            HStack {
                // 左侧核销券标题和有效期限
                VStack(alignment: .leading, spacing: 4) {
                    Text("核销副券")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    // 有效期限只显示结束日期
                    HStack(spacing: 3) {
                        Text("有效期至：")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(expiryDateString)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                }
                .padding(.leading, 20)
                
                Spacer()
                
                // 核销按钮 - 更明显
                Button(action: {
                    showRedeemAlert = true
                }) {
                    Text("立即核销")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.25))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white, lineWidth: 1)
                                )
                        )
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
            .overlay(
                // 添加微妙纹理效果，与主券保持一致
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            // 只有底部有圆角，顶部是平的
            .clipShape(
                RoundedCornerShape(radius: 16, corners: [.bottomLeft, .bottomRight])
            )
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        )
    }
}

// 被撕下的副券黑白效果
struct TornBottomPartView: View {
    var voucher: DessertVoucher
    
    // 只获取到期日期
    private var expiryDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: voucher.expiryDate)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 核销副券区域
            HStack {
                // 左侧核销券标题和有效期限
                VStack(alignment: .leading, spacing: 4) {
                    Text("核销副券")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    // 有效期限只显示结束日期
                    HStack(spacing: 3) {
                        Text("有效期至：")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(expiryDateString)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                }
                .padding(.leading, 20)
                
                Spacer()
                
                // 已核销标记
                Text("已核销")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.25))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white, lineWidth: 1)
                            )
                    )
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


