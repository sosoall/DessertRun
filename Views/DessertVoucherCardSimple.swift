import SwiftUI

/// 美食券卡片视图（简化版本）
struct DessertVoucherCardSimple: View {
    /// 打卡记录
    let record: WorkoutRecord
    
    /// 是否正在核销
    @State private var isRedeeming: Bool = false
    
    /// 核销相关错误
    @State private var redeemError: String? = nil
    
    /// 显示核销确认
    @State private var showRedeemConfirm: Bool = false
    
    /// 强制展开状态（用于弹窗展示）
    var forceExpanded: Bool = false
    
    /// 动画状态
    @State private var isAnimating: Bool = false
    
    /// 从后端获取的图片URL
    @State private var voucherImageURL: URL? = nil
    
    /// 提供一个环境变量，用于触发弹窗展示
    @Environment(\.presentationMode) var presentationMode
    
    /// 添加环境对象，用于获取美食券信息
    @EnvironmentObject var appState: AppState
    
    // 获取与当前记录关联的美食券
    private var associatedVoucher: DessertVoucher? {
        return appState.dessertVouchers.first(where: { $0.workoutRecordId == record.id })
    }
    
    // 获取美食券创建日期
    private var voucherCreatedDate: Date? {
        return associatedVoucher?.createdAt
    }
    
    // 获取美食券过期日期
    private var voucherExpireDate: Date? {
        // 直接使用美食券的expireAt字段
        return associatedVoucher?.expireAt
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 卡片主体部分
            cardHeader
            
            // 底部操作区
            cardFooter
        }
        .onAppear {
            // 获取美食券相关图片
            loadImages()
            
            if forceExpanded {
                // 当显示为展开状态时，延迟一点启动动画
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isAnimating = true
                    }
                }
            }
        }
        .onTapGesture {
            // 只有非强制展开状态下才触发弹窗展示
            if !forceExpanded {
                // 通知父视图显示弹窗
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowExpandedCard"),
                    object: record
                )
            }
        }
        .alert("确认核销", isPresented: $showRedeemConfirm) {
            Button("取消", role: .cancel) {}
            Button("确认核销") {
                redeemVoucher()
            }
        } message: {
            Text("确定要核销这张美食券吗？\n只有VIP用户才能核销美食券。\n核销后无法恢复。")
        }
        .alert("核销失败", isPresented: Binding<Bool>(
            get: { redeemError != nil },
            set: { if !$0 { redeemError = nil } }
        )) {
            Button("确定", role: .cancel) {
                redeemError = nil
            }
        } message: {
            Text(redeemError ?? "未知错误")
        }
    }
    
    // 加载美食图片
    private func loadImages() {
        // 从后端获取voucher类型图片URL
        let dessertId = record.dessert.id
        voucherImageURL = APIService.shared.getDessertImageURL(dessertId: dessertId, type: "voucher")
        
        // 记录日志
        DRDebug("[DessertVoucherCard] 加载美食图片: voucher=\(voucherImageURL?.absoluteString ?? "nil")")
    }
    
    // MARK: - 卡片主体部分
    private var cardHeader: some View {
        ZStack(alignment: .center) {
            // 1. 背景渐变 - 放在最底层
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "#FF9D0B"), location: 0),
                    .init(color: Color(hex: "#FFEAC5"), location: 0.59),
                    .init(color: Color(hex: "#FFE5EC"), location: 1)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .cornerRadius(20, corners: [.topLeft, .topRight])
            
            // 2. 白色边框 - 只在上边加圆角
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white, lineWidth: 1)
                .cornerRadius(20, corners: [.topLeft, .topRight])
            
            // 3. 内容布局 - 使用VStack改善布局
            VStack(spacing: 0) {
                // 主要内容行
                HStack(alignment: forceExpanded ? .top : .center, spacing: 0) {
                    // 左侧部分 - 固定在40%宽度
                    HStack(spacing: 5) {
                        // 左侧美食图标 - 使用本地图标
                        Image("milktea_icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: forceExpanded ? 55 : 50, height: forceExpanded ? 55 : 50)
                            .offset(y: isAnimating && forceExpanded ? 100 : 0)
                        
                        // 左侧美食及消耗美食数量的文本信息
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .center, spacing: 5) {
                                Text(String(format: "%.1f", record.equivalentDessertCount))
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(Color(hex: "#FE5C72"))
                                
                                Text("x")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(hex: "#FE5C72"))
                            }
                            
                            Text(record.dessert.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "#FE5C72"))
                                .lineLimit(forceExpanded ? nil : 1)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.leading, 5)
                        .offset(y: isAnimating && forceExpanded ? -10 : 0)
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.4 - 20) // 修正为屏幕宽度的40%
                    
                    // 中间分隔线
                    Rectangle()
                        .fill(Color(hex: "#D7B8BE"))
                        .frame(width: 1, height: forceExpanded ? 140 : 70)
                        .padding(.horizontal, 10)
                    
                    // 右侧运动信息
                    VStack(alignment: .leading, spacing: forceExpanded ? 8 : 4) {
                        Text(record.exerciseType.name)
                            .font(.system(size: 20, weight: .semibold))
                            .lineLimit(forceExpanded ? nil : 1)
                            .offset(y: isAnimating && forceExpanded ? -5 : 0)
                        
                        if forceExpanded {
                            // 确保显示运动标签文本
                            Text(record.displayWorkoutTag)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "#F8A41C"))
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                                .padding(.top, isAnimating ? 2 : 0)
                                .opacity(isAnimating ? 1 : 0)
                            
                            // 展开时显示运动详情
                            VStack(alignment: .leading, spacing: 12) {
                                // 运动时长
                                if let duration = record.duration {
                                    HStack(spacing: 8) {
                                        Image(systemName: "clock")
                                            .foregroundColor(Color(hex: "#FF7B15"))
                                        
                                        Text(formatDuration(seconds: Int(duration)))
                                            .font(.system(size: 16, weight: .medium))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .opacity(isAnimating ? 1 : 0)
                                }
                                
                                // 运动距离
                                if let distance = record.distance {
                                    HStack(spacing: 8) {
                                        Image(systemName: "figure.walk")
                                            .foregroundColor(Color(hex: "#FF7B15"))
                                        
                                        Text(String(format: "%.1f公里", distance / 1000))
                                            .font(.system(size: 16, weight: .medium))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .opacity(isAnimating ? 1 : 0)
                                }
                                
                                // 消耗热量
                                HStack(spacing: 8) {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(.red)
                                    
                                    Text("\(Int(record.caloriesBurned))卡路里")
                                        .font(.system(size: 16, weight: .medium))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .opacity(isAnimating ? 1 : 0)
                                
                                // 日期放在这里与其他信息对齐
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(Color(hex: "#919191"))
                                    
                                    Text(formattedDateTime(record.date))
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(Color(hex: "#919191"))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .opacity(isAnimating ? 1 : 0)
                                .padding(.top, 4)
                            }
                            .padding(.top, 8)
                        }
                    }
                    
                    Spacer(minLength: 0)
                    
                    // 右侧美食图像 - 使用从后端获取的voucher图片
                    Group {
                        if let imageURL = voucherImageURL {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: forceExpanded ? 120 : 100, height: forceExpanded ? 120 : 100)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: forceExpanded ? 120 : 100, height: forceExpanded ? 120 : 100)
                                case .failure:
                                    // 加载失败时显示默认图像
                                    Image("dessert_background")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: forceExpanded ? 120 : 100, height: forceExpanded ? 120 : 100)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            // 默认图像
                            Image("dessert_background")
                                .resizable()
                                .scaledToFit()
                                .frame(width: forceExpanded ? 120 : 100, height: forceExpanded ? 120 : 100)
                        }
                    }
                    .offset(y: isAnimating && forceExpanded ? 50 : 0)
                }
                .padding(.top, forceExpanded ? 15 : 10) // 增加顶部padding
                .frame(height: forceExpanded ? 200 : 100) // 增加高度
            }
        }
        .frame(height: forceExpanded ? 250 : 100) // 整体增加高度
    }
    
    // 格式化时长的辅助函数
    private func formatDuration(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    // 日期格式化函数
    private func formattedDateTime(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
        return dateFormatter.string(from: date)
    }
    
    // 格式化过期日期
    private func formattedExpiryDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日"
        
        if let expireDate = voucherExpireDate {
            return dateFormatter.string(from: expireDate)
        } else {
            // 默认30天过期期限
            let calendar = Calendar.current
            if let expiryDate = calendar.date(byAdding: .day, value: 30, to: record.date) {
                return dateFormatter.string(from: expiryDate)
            } else {
                return "未知"
            }
        }
    }
    
    // MARK: - 卡片底部部分
    private var cardFooter: some View {
        // 底部核销区域
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if forceExpanded {
                        Text("美食券")
                            .font(.system(size: 16, weight: .bold))
                    }
                    
                    // 使用美食券的剩余天数
                    let daysRemaining = associatedVoucher?.remainingDays ?? calculateRemainingDays()
                    // 剩余天数
                    Text("剩余\(daysRemaining)天")
                        .font(.system(size: 14, weight: .regular))
                }
                
                Spacer()
                
                // 核销按钮
                Button(action: {
                    showRedeemConfirm = true
                }) {
                    Text("立即核销")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)
                        .background(Color(hex: forceExpanded ? "#FF318D" : "#FE2D55"))
                        .cornerRadius(10)
                }
                .disabled(isRedeeming)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, forceExpanded ? 15 : 10) // 增加底部高度
            .background(Color.white)
            .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        Color.gray.opacity(0.5),
                        style: StrokeStyle(
                            lineWidth: 1,
                            dash: [5, 5]
                        )
                    )
                    .clipShape(RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight]))
            )
        }
        .frame(height: forceExpanded ? 65 : 45) // 增加底部高度
    }
    
    // 计算美食券剩余天数（使用美食券的过期日期）
    private func calculateRemainingDays() -> Int {
        let calendar = Calendar.current
        
        // 优先使用美食券的过期日期
        if let expireDate = voucherExpireDate {
            // 计算当前时间与过期时间的天数差
            let days = calendar.dateComponents([.day], from: Date(), to: expireDate).day ?? 0
            // 如果已过期，返回0
            return max(0, days)
        }
        
        // 如果没有关联的美食券信息，使用原来的逻辑（创建日期+30天）
        let validityPeriodInDays = 30
        guard let expiryDate = calendar.date(byAdding: .day, value: validityPeriodInDays, to: record.date) else {
            return 0
        }
        
        // 计算当前时间与过期时间的天数差
        let days = calendar.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
        
        // 如果已过期，返回0
        return max(0, days)
    }
    
    // MARK: - 核销操作
    private func redeemVoucher() {
        guard let voucher = associatedVoucher else {
            redeemError = "未找到对应的美食券"
            return
        }
        
        isRedeeming = true
        
        // 调用VoucherService实现核销
        VoucherService.shared.redeemVoucher(voucherID: UUID(uuidString: voucher.id) ?? UUID()) { success, error in
            isRedeeming = false
            
            if !success {
                redeemError = error ?? "核销失败，请稍后再试"
            } else {
                // 核销成功，刷新美食券列表
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    VoucherService.shared.loadVouchers(forceRefresh: true)
                }
                
                // 关闭弹窗
                if forceExpanded {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

// MARK: - 辅助扩展

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
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

// MARK: - 预览

struct DessertVoucherCardSimple_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 收起状态
            DessertVoucherCardSimple(record: WorkoutRecord.createSample())
                .frame(width: 350)
            
            // 自定义样本 - 展开状态
            let sampleRecord = WorkoutRecord(
                id: UUID().uuidString,
                userId: UUID().uuidString,
                exerciseType: ExerciseType(
                    type: "walking",
                    name: "跑步",
                    description: "跑步是一种有氧运动",
                    iconName: "figure.run",
                    usesDistance: true,
                    backgroundColor: "#FF6B6B",
                    caloriesPerMinPerKg: 0.1,
                    caloriesPerKmPerKg: 0.7,
                    displayOrder: 1
                ),
                duration: 57,
                distance: 2500,
                caloriesBurned: 350,
                dessert: DessertItem(
                    id: "1", 
                    name: "芝芝奶茶", 
                    imageName: "dessert_01",
                    calories: "235",
                    category: .drink,
                    description: "",
                    backgroundColor: nil,
                    isFeatured: false,
                    relatedItems: [],
                    categoryId: "1",
                    categoryName: "饮品",
                    displayOrder: 1,
                    images: []
                ),
                date: Date(),
                workoutTag: "运动量super!",
                equivalentDessertCount: 1.3
            )
            
            // 展开状态预览
            DessertVoucherCardSimple(record: sampleRecord, forceExpanded: true)
                .frame(width: 350)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
} 