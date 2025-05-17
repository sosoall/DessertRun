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
    
    /// 从后端获取的图标URL
    @State private var iconImageURL: URL? = nil
    
    /// 提供一个环境变量，用于触发弹窗展示
    @Environment(\.presentationMode) var presentationMode
    
    /// 添加环境对象，用于获取美食券信息
    @EnvironmentObject var appState: AppState
    
    /// 添加状态变量存储图标图片
    @State private var iconImage: UIImage? = nil
    
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
        // 确保整个卡片没有任何外部padding
        .padding(0)
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
        // 首先检查是否有关联的美食券与固定图片
        if let voucher = associatedVoucher, let imageId = voucher.imageId {
            // 从后端通过image_id参数获取固定的图片
            let dessertId = record.dessert.id
            voucherImageURL = APIService.shared.getDessertImageURLWithImageID(dessertId: dessertId, type: "voucher", imageId: imageId)
            
            DRDebug("[DessertVoucherCard] 使用美食券固定图片: image_id=\(imageId), URL=\(voucherImageURL?.absoluteString ?? "nil")")
        } else {
            // 回退：如果没有关联的美食券或imageId，使用老方法
            let dessertId = record.dessert.id
            voucherImageURL = APIService.shared.getDessertImageURL(dessertId: dessertId, type: "voucher")
            
            DRWarning("[DessertVoucherCard] 使用随机美食券图片，可能导致显示不一致: \(voucherImageURL?.absoluteString ?? "nil")")
        }
        
        // 从后端获取icon类型图片URL
        let dessertId = record.dessert.id
        let iconURL = APIService.shared.getDessertImageURL(dessertId: dessertId, type: "icon")
        if let url = iconURL {
            // 记录尝试加载的icon URL
            DRInfo("[DessertVoucherCard] 尝试加载icon图片: \(url.absoluteString)")
            
            // 使用改进的ImageCacheService直接获取图片
            ImageCacheService.shared.downloadAndCacheImage(url: url.absoluteString) { image in
                if let image = image {
                    DispatchQueue.main.async {
                        self.iconImage = image
                        DRInfo("[DessertVoucherCard] 成功加载icon图片")
                    }
                } else {
                    DRError("[DessertVoucherCard] 加载美食图标失败: \(url)")
                    // 加载失败时不要设置图标，将使用默认值
                }
            }
        } else {
            DRWarning("[DessertVoucherCard] 获取icon URL失败，dessertId: \(dessertId)")
        }
        
        // 记录日志
        let iconURLString = APIService.shared.getDessertImageURL(dessertId: dessertId, type: "icon")?.absoluteString ?? "nil"
        DRDebug("[DessertVoucherCard] 加载美食图片: voucher=\(voucherImageURL?.absoluteString ?? "nil"), icon=\(iconURLString)")
    }
    
    // MARK: - 卡片主体部分
    private var cardHeader: some View {
        GeometryReader { geometry in 
            ZStack(alignment: .leading) {
                // 1. 背景渐变 - 放在最底层，确保完全填充
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
                    .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
                
                // 3. 内容布局 - 三段式布局
                HStack(spacing: 0) {
                    // 左侧部分 - 固定宽度
                    VStack {
                        HStack(spacing: 5) {
                            // 移除这里的图标，使用绝对定位的图标替代
                            
                            // 左侧美食及消耗美食数量的文本信息
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .center, spacing: 5) {
                                    Text(String(format: "%.1f", record.equivalentDessertCount))
                                        .font(.system(size: forceExpanded ? 32 : 20, weight: .semibold))
                                        .foregroundColor(Color(hex: "#FE5C72"))
                                    
                                    Text("x")
                                        .font(.system(size: forceExpanded ? 24 : 16, weight: .semibold))
                                        .foregroundColor(Color(hex: "#FE5C72"))
                                }
                                .fixedSize(horizontal: true, vertical: false) // 确保"1.4x"在一行内显示
                                
                                Text(record.dessert.name)
                                    .font(.system(size: forceExpanded ? 16 : 16, weight: .medium))
                                    .foregroundColor(Color(hex: "#FE5C72"))
                                    .lineLimit(forceExpanded ? nil : 1)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.leading, forceExpanded ? 65 : 60) // 为绝对定位的图标留出空间
                            .offset(y: isAnimating && forceExpanded ? -10 : 0)
                        }
                    }
                    .frame(width: geometry.size.width * 0.4 - 20) // 固定宽度
                    .zIndex(10) // 确保文字在图片上面
                    
                    // 中间分隔线
                    Rectangle()
                        .fill(Color(hex: "#D7B8BE"))
                        .frame(width: 1, height: forceExpanded ? 140 : 70)
                        .padding(.horizontal, 10)
                    
                    // 右侧信息区
                    VStack(alignment: .leading, spacing: forceExpanded ? 8 : 4) {
                        Text(record.exerciseType.name)
                            .font(.system(size: forceExpanded ? 32 : 20, weight: .semibold))
                            .lineLimit(nil) // 允许换行
                            .fixedSize(horizontal: false, vertical: true) // 确保文字完整显示
                            .offset(y: isAnimating && forceExpanded ? -5 : 0)
                        
                        if forceExpanded {
                            // 确保显示运动标签文本，根据tag内容调整颜色
                            Text(record.displayWorkoutTag)
                                .font(.system(size: 16, weight: .semibold))
                                // 根据tag类型设置不同颜色
                                .foregroundColor(record.displayWorkoutTag.contains("super") ? 
                                               Color(hex: "#F8A41C") : Color(hex: "#939393"))
                                .fixedSize(horizontal: true, vertical: false)
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
                                
                                // 日期放在这里与其他信息对齐 - 去掉icon
                                Text(formattedDateTime(record.date))
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color(hex: "#919191"))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .opacity(isAnimating ? 1 : 0)
                                    .padding(.top, 4)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.trailing, 70) // 为右侧图片留出空间
                    .zIndex(10) // 确保文字在最上层
                    
                    Spacer(minLength: 0)
                }
                .padding(.top, forceExpanded ? 15 : 10)
                .padding(.leading, 16) // 左侧留出空间
                
                // 4. 右侧美食图像 - 使用绝对定位确保靠右对齐
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
                                // 使用系统图像作为兜底图
                                Image(systemName: "fork.knife.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(Color(hex: "#FF9D0B"))
                                    .frame(width: forceExpanded ? 120 : 100, height: forceExpanded ? 120 : 100)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        // 使用系统图像作为兜底图
                        Image(systemName: "fork.knife.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(hex: "#FF9D0B"))
                            .frame(width: forceExpanded ? 120 : 100, height: forceExpanded ? 120 : 100)
                    }
                }
                .offset(y: isAnimating && forceExpanded ? 50 : 0)
                .position(x: geometry.size.width - (forceExpanded ? 60 : 50), y: forceExpanded ? 100 : 50) // 用绝对定位确保靠右
                .zIndex(0) // 确保图片在文字下面
                
                // 5. 左侧美食图标 - 使用绝对定位确保靠左对齐
                Group {
                    if let uiImage = iconImage {
                        // 如果通过ImageCacheService成功加载了图片
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: forceExpanded ? 55 : 50, height: forceExpanded ? 55 : 50)
                            .position(x: 40, y: forceExpanded ? (isAnimating ? 130 : 60) : 50)
                            .zIndex(0)
                    } else {
                        // 默认图标
                        Image(systemName: "cup.and.saucer.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(hex: "#FF9D0B"))
                            .frame(width: forceExpanded ? 55 : 50, height: forceExpanded ? 55 : 50)
                            .position(x: 40, y: forceExpanded ? (isAnimating ? 130 : 60) : 50)
                            .zIndex(0)
                    }
                }
            }
            .frame(height: forceExpanded ? 250 : 100)
        }
        .frame(height: forceExpanded ? 250 : 100)
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
        // 移除样本数据，使用环境预览
        DessertVoucherCardSimple(record: WorkoutRecord.createSample())
            .environmentObject(AppState.shared) // 使用单例而不是初始化新实例
            .frame(width: 350)
            .padding()
            .background(Color.gray.opacity(0.1))
    }
} 