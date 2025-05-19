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
    
    /// 添加新的动画状态变量
    @State private var animateGradientBackground: Bool = false  // 第一阶段：渐变背景
    @State private var animateBaseContent: Bool = false         // 第一阶段：基础文字内容
    @State private var animateFooterBase: Bool = false          // 第一阶段：副券基础部分(底色、虚线边框、文字、按钮)
    @State private var animateExtraContent: Bool = false        // 第二阶段：其他文字内容
    @State private var animateVisuals: Bool = false             // 第三阶段：图标和美食图
    @State private var animateBackgroundShine: Bool = false     // 第四阶段：背景光韵效果
    @State private var animateEdgeHighlight: Bool = false       // 第四阶段：边缘勾边效果
    @State private var animateButtonShine: Bool = false         // 第五阶段：按钮光韵效果
    
    // 光韵效果的位置参数
    @State private var shineOffset: CGFloat = -200
    @State private var buttonShineOffset: CGFloat = -100
    
    // 边缘勾边动画进度
    @State private var edgeProgress: CGFloat = 0
    
    /// 从后端获取的图片URL
    @State private var voucherImageURL: URL? = nil
    
    /// 从后端获取的图标URL
    @State private var iconImageURL: URL? = nil
    
    /// 添加图片加载状态标志，避免重复加载
    @State private var hasLoadedImages: Bool = false
    
    /// 添加唯一ID，防止多个实例混淆状态
    private let instanceId = UUID().uuidString
    
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
        GeometryReader { geometry in // 使用GeometryReader获取整体宽度
            ZStack(alignment: .top) {
                // 1. 背景部分 - 直接使用渐变背景
                if forceExpanded {
                    // 渐变背景 - 第一阶段直接出现
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(hex: "#FF9D0B"), location: 0),
                            .init(color: Color(hex: "#FFEAC5"), location: 0.59),
                            .init(color: Color(hex: "#FFE5EC"), location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(
                        RoundedCorner(
                            radius: 20,
                            corners: [.topLeft, .topRight]
                        )
                    )
                    .frame(height: 220)
                    .opacity(animateGradientBackground ? 1 : 0)
                    .animation(.easeIn(duration: 0.3), value: animateGradientBackground)
                    
                    // 完整卡片边缘勾边效果 - 第四阶段
                    // 定义一个自定义形状，包含上半部分和下半部分
                    ZStack {
                        // 创建一个完整形状的边缘高亮，使用对角线渐变而不是勾边
                        FullCardShape(
                            topRadius: 20,
                            bottomRadius: 10,
                            topHeight: 220,
                            bottomHeight: 68
                        )
                        .stroke(LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.white.opacity(1), location: 0),
                                .init(color: Color.white.opacity(0.8), location: 0.3),
                                .init(color: Color.white.opacity(0.6), location: 0.7),
                                .init(color: Color.white.opacity(0.4), location: 1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), lineWidth: 2)
                        .mask(
                            // 使用遮罩实现从左上角到右下角的对角线渐显效果
                            DiagonalGradientMask(progress: edgeProgress)
                                .frame(width: UIScreen.main.bounds.width, height: 220 + 68)
                        )
                    }
                    .opacity(animateEdgeHighlight ? 1 : 0)
                    
                    // 光韵效果层 - 第四阶段
                    ZStack {
                        Color.clear
                            .frame(height: 220)
                            .clipShape(
                                RoundedCorner(
                                    radius: 20,
                                    corners: [.topLeft, .topRight]
                                )
                            )
                            .overlay(
                                // 白色光韵从左到右扫过
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color.white.opacity(0.0), location: 0),
                                        .init(color: Color.white.opacity(0.5), location: 0.4),
                                        .init(color: Color.white.opacity(0.7), location: 0.5),
                                        .init(color: Color.white.opacity(0.5), location: 0.6),
                                        .init(color: Color.white.opacity(0.0), location: 1)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: 300)
                                .offset(x: shineOffset)
                                .opacity(animateBackgroundShine ? 1 : 0) // 控制整个光韵效果的显示
                            )
                            .mask(
                                // 确保只有卡片范围内才有光韵效果
                                RoundedCorner(
                                    radius: 20,
                                    corners: [.topLeft, .topRight]
                                ).fill(Color.black)
                            )
                    }
                    .frame(height: 220)
                } else {
                    // 收起状态使用白色背景
                    Color.white
                        .clipShape(
                            RoundedCorner(
                                radius: 20,
                                corners: [.topLeft, .topRight]
                            )
                        )
                }
                
                // 2. 图标和美食图像 - 第三阶段出现
                if forceExpanded {
                    // 展开状态下的图片
                    Group {
                        if let imageURL = voucherImageURL {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 90, height: 90)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 90, height: 90)
                                case .failure:
                                    // 使用系统图像作为兜底图
                                    Image(systemName: "fork.knife.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color(hex: "#FF9D0B"))
                                        .frame(width: 90, height: 90)
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
                                .frame(width: 90, height: 90)
                        }
                    }
                    .position(x: max(30, geometry.size.width - 60), y: 170)
                    .scaleEffect(animateVisuals ? 1 : 0.6)
                    .opacity(animateVisuals ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateVisuals)
                    .zIndex(1)
                    
                    // 展开状态下的左侧图标
                    Group {
                        if let uiImage = iconImage {
                            // 如果通过ImageCacheService成功加载了图片
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 42, height: 42)
                                .position(x: 22, y: 190)
                                .scaleEffect(animateVisuals ? 1 : 0.6)
                                .opacity(animateVisuals ? 1 : 0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateVisuals)
                        } else {
                            // 默认图标
                            Image(systemName: "cup.and.saucer.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Color(hex: "#FF9D0B"))
                                .frame(width: 42, height: 42)
                                .position(x: 22, y: 190)
                                .scaleEffect(animateVisuals ? 1 : 0.6)
                                .opacity(animateVisuals ? 1 : 0)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateVisuals)
                        }
                    }
                    .zIndex(5)
                } else {
                    // 收起状态下的图片
                    Group {
                        if let imageURL = voucherImageURL {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 65, height: 65)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 65, height: 65)
                                case .failure:
                                    // 使用系统图像作为兜底图
                                    Image(systemName: "fork.knife.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color(hex: "#FF9D0B"))
                                        .frame(width: 65, height: 65)
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
                                .frame(width: 65, height: 65)
                        }
                    }
                    .position(x: max(30, geometry.size.width - 40), y: 38)
                    .zIndex(1)
                    
                    // 收起状态下的左侧图标
                    Group {
                        if let uiImage = iconImage {
                            // 如果通过ImageCacheService成功加载了图片
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                                .position(x: 22, y: 56)
                        } else {
                            // 默认图标
                            Image(systemName: "cup.and.saucer.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Color(hex: "#FF9D0B"))
                                .frame(width: 36, height: 36)
                                .position(x: 22, y: 56)
                        }
                    }
                    .zIndex(5)
                }
                
                // 3. 文字内容部分
                VStack(spacing: 0) {
                    cardHeader
                }
                .zIndex(10)  // 确保文字在最上层
                
                // 4. 底部操作区 - 第一阶段就完整显示
                if forceExpanded {
                    // 展开状态下的底部区域
                    VStack(spacing: 0) {
                        // 底部核销区域背景、文字和按钮
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                if forceExpanded {
                                    Text("美食券")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                
                                // 使用美食券的剩余天数
                                let daysRemaining = associatedVoucher?.remainingDays ?? calculateRemainingDays()
                                // 剩余天数
                                Text("剩余\(daysRemaining)天")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            // 核销按钮 - 加入到底部区域中
                            Button(action: {
                                showRedeemConfirm = true
                            }) {
                                // 按钮层
                                ZStack {
                                    Text("立即核销")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.vertical, 5)
                                        .padding(.horizontal, 14)
                                        .background(Color(hex: "#FF318D"))
                                        .cornerRadius(8)
                                    
                                    // 按钮光韵效果 - 第五阶段
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(stops: [
                                                    .init(color: Color.white.opacity(0.0), location: 0),
                                                    .init(color: Color.white.opacity(0.5), location: 0.3),
                                                    .init(color: Color.white.opacity(0.8), location: 0.5),
                                                    .init(color: Color.white.opacity(0.5), location: 0.7),
                                                    .init(color: Color.white.opacity(0.0), location: 1)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: 100, height: 30)
                                        .offset(x: buttonShineOffset)
                                        .mask(
                                            Text("立即核销")
                                                .font(.system(size: 14, weight: .medium))
                                                .padding(.vertical, 5)
                                                .padding(.horizontal, 14)
                                                .background(Color.white)
                                                .cornerRadius(8)
                                        )
                                        .opacity(animateButtonShine ? 1 : 0)
                                }
                            }
                            .disabled(isRedeeming)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16) // 垂直内边距
                    }
                    .frame(width: geometry.size.width, height: 68) // 固定高度
                    .background(
                        CustomShape(radius: 10, corners: [.bottomLeft, .bottomRight])
                            .fill(Color.white)
                    )
                    .overlay(
                        // 只添加顶部的虚线分隔线
                        Rectangle()
                            .frame(width: geometry.size.width, height: 1)
                            .foregroundColor(Color.gray.opacity(0.5))
                            .position(x: geometry.size.width/2, y: 0.5) // 放置在顶部
                            .overlay(
                                Rectangle()
                                    .frame(width: geometry.size.width, height: 1)
                                    .foregroundColor(.white)
                                    .mask(
                                        HStack(spacing: 2.5) {
                                            ForEach(0..<Int(geometry.size.width/5), id: \.self) { _ in
                                                Rectangle().frame(width: 2.5, height: 1)
                                                Spacer().frame(width: 2.5)
                                            }
                                        }
                                    )
                                    .position(x: geometry.size.width/2, y: 0.5) // 放置在顶部
                            )
                    )
                    .offset(y: 220) // 位置固定，紧接着上面的卡片
                    .opacity(animateFooterBase ? 1 : 0)
                    .animation(.easeIn(duration: 0.2), value: animateFooterBase)
                    .zIndex(10)
                } else {
                    // 收起状态下的底部
                    cardFooter
                        .frame(width: geometry.size.width)
                        .offset(y: 75)
                        .zIndex(10)
                }
            }
            .frame(width: geometry.size.width) // 确保整体宽度一致
        }
        // 确保整个卡片没有任何外部padding
        .padding(0)
        .frame(height: forceExpanded ? (220 + 68) : (75 + 40)) // 明确设置总高度为两部分高度之和
        .id("card-\(record.id)-\(instanceId)") // 添加唯一ID避免状态混淆
        .onAppear {
            // 获取美食券相关图片
            loadImages()
            
            if forceExpanded {
                // 当显示为展开状态时，按顺序启动动画
                animateSequence()
            } else {
                // 收起状态默认全部显示
                resetAnimations(true)
            }
        }
        // 修复iOS 17中onChange废弃问题
        .onChange(of: forceExpanded) { _, newValue in
            // 当状态变化时，触发动画序列
            if newValue {
                animateSequence()
            } else {
                // 收起时反向动画
                reverseAnimateSequence()
            }
        }
        .onTapGesture {
            // 只有非强制展开状态下才触发弹窗展示
            if !forceExpanded {
                // 创建包含已加载图片信息的userInfo字典
                var userInfo: [String: Any] = [
                    "preloadedImages": hasLoadedImages,  // 传递已加载状态
                    "instanceId": instanceId             // 传递实例ID
                ]
                
                // 如果有图片URL，也传递
                if let imageURL = voucherImageURL {
                    userInfo["imageURL"] = imageURL.absoluteString
                }
                
                // 如果有图标图片，标记为已加载
                if iconImage != nil {
                    userInfo["iconLoaded"] = true
                }
                
                // 通知父视图显示弹窗，并传递额外信息
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowExpandedCard"),
                    object: record,
                    userInfo: userInfo
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
    
    // 按照顺序执行动画序列
    private func animateSequence() {
        // 重置所有动画状态
        resetAnimations(false)
        
        // 1. 第一阶段：渐变背景 + 基础文字内容 + 副券(包含立即核销按钮)
        withAnimation(.easeIn(duration: 0.3)) {
            animateGradientBackground = true
            animateBaseContent = true
            animateFooterBase = true
        }
        
        // 2. 第二阶段：其他所有文字内容
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // 增加延迟
            withAnimation(.easeInOut(duration: 0.4)) {
                animateExtraContent = true
                isAnimating = true // 原有动画状态激活
            }
        }
        
        // 3. 第三阶段：图标和美食图直接出现并放大
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // 增加延迟
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateVisuals = true
            }
        }
        
        // 4. 第四阶段：边缘勾边效果和背景光韵效果 - 同步启动并保持一致的时长
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) { // 增加延迟
            // 激活边缘勾边动画
            withAnimation {
                animateEdgeHighlight = true
            }
            
            // 启动边缘勾边对角线渐显动画 - 调整为与光韵效果相同的时长(1.0秒)
            withAnimation(.easeInOut(duration: 1.0)) {
                edgeProgress = 1.0 // 完全显示边缘高亮
            }
            
            // 延迟一点启动光韵扫过效果，等待边缘勾边开始后
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // 激活背景光韵动画并设置初始位置
                shineOffset = -200
                animateBackgroundShine = true
                
                // 从左到右移动光韵
                withAnimation(.easeInOut(duration: 1.0)) {
                    self.shineOffset = UIScreen.main.bounds.width + 200 // 移动到右侧外部
                }
                
                // 动画完成后隐藏光韵效果，但保留边缘勾边
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    animateBackgroundShine = false
                }
            }
        }
        
        // 5. 第五阶段：按钮光韵效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { // 增加延迟，确保边缘勾边完成
            // 激活按钮光韵并设置初始位置
            animateButtonShine = true
            buttonShineOffset = -100
            
            // 从左到右移动光韵
            withAnimation(.easeInOut(duration: 0.8)) {
                buttonShineOffset = 100 // 移动到右侧
            }
            
            // 动画完成后隐藏按钮光韵
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                animateButtonShine = false
            }
        }
        
        // 6. 第六阶段：展示分享和关闭按钮 
        // 这部分在ExpandedCardView中处理，通过延迟发送通知实现
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) { // 增加延迟
            // 不再重置边缘勾边效果，保持其显示
            // animateEdgeHighlight = false
            
            NotificationCenter.default.post(
                name: NSNotification.Name("AnimationComplete"),
                object: nil
            )
        }
    }
    
    // 反向动画序列
    private func reverseAnimateSequence() {
        // 按相反顺序执行动画
        
        // 1. 首先隐藏图标和图片
        withAnimation(.easeOut(duration: 0.2)) {
            animateVisuals = false
        }
        
        // 2. 隐藏额外文字内容
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.2)) {
                animateExtraContent = false
                isAnimating = false
            }
        }
        
        // 3. 最后隐藏基础内容、副券和渐变背景
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.3)) {
                animateBaseContent = false
                animateFooterBase = false
                animateGradientBackground = false
                animateEdgeHighlight = false // 一并隐藏边缘勾边
                edgeProgress = 0
            }
        }
        
        // 延迟后再重置所有状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            resetAnimations(false)
            // 重置光韵和边缘勾边位置
            shineOffset = -200
            buttonShineOffset = -100
            edgeProgress = 0
        }
    }
    
    // 重置所有动画状态
    private func resetAnimations(_ value: Bool) {
        animateGradientBackground = value
        animateBaseContent = value
        animateFooterBase = value
        animateExtraContent = value
        animateVisuals = value
        animateBackgroundShine = value
        animateButtonShine = value
        animateEdgeHighlight = value
        isAnimating = value
    }
    
    // 加载美食图片
    private func loadImages() {
        // 使用状态标志防止重复加载
        if hasLoadedImages {
            DRDebug("[DessertVoucherCard-\(instanceId.prefix(6))] 图片已加载，跳过重复加载")
            return
        }
        
        // 添加instanceId到日志，方便追踪
        DRDebug("[DessertVoucherCard-\(instanceId.prefix(6))] 开始加载图片")
        
        // 检查是否已加载图片，避免重复加载
        if voucherImageURL != nil && iconImage != nil {
            hasLoadedImages = true
            DRDebug("[DessertVoucherCard-\(instanceId.prefix(6))] 图片URL和图标已存在，标记为已加载")
            return
        }

        // 首先检查是否有关联的美食券
        if let voucher = associatedVoucher {
            // 1. 加载美食券图片
            if voucherImageURL == nil {
                if let imageId = voucher.imageId {
                    // 首先尝试从URL缓存获取
                    if let cachedURL = ImageCacheService.shared.getCachedImageURL(forId: imageId) {
                        voucherImageURL = URL(string: cachedURL)
                        DRDebug("[DessertVoucherCard-\(instanceId.prefix(6))] 使用缓存的美食券图片URL: \(cachedURL)")
                        
                        // 标记图片部分加载完成
                        if iconImage != nil {
                            hasLoadedImages = true
                        }
                    } else {
                        // 缓存未命中，使用标准API获取
                        let dessertId = record.dessert.id
                        let newURL = APIService.shared.getDessertImageURLWithImageID(dessertId: dessertId, type: "voucher", imageId: imageId)
                        voucherImageURL = newURL
                        
                        // 标记图片部分加载完成
                        if iconImage != nil {
                            hasLoadedImages = true
                        }
                    }
                } else {
                    // 无图片ID时使用标准API
                    let dessertId = record.dessert.id
                    voucherImageURL = APIService.shared.getDessertImageURL(dessertId: dessertId, type: "voucher")
                    
                    // 标记图片部分加载完成
                    if iconImage != nil {
                        hasLoadedImages = true
                    }
                }
            }
            
            // 2. 加载图标
            if iconImage == nil {
                let dessertId = record.dessert.id
                
                // 优先尝试从URL缓存获取图标
                if let cachedIconURL = ImageCacheService.shared.getCachedImageURL(forId: "icon_\(dessertId)") {
                    DRDebug("[DessertVoucherCard-\(instanceId.prefix(6))] 使用缓存的图标URL: \(cachedIconURL)")
                    
                    // 使用改进的ImageCacheService直接获取图片
                    ImageCacheService.shared.downloadAndCacheImage(url: cachedIconURL) { [self] image in
                        if let image = image {
                            DispatchQueue.main.async {
                                self.iconImage = image
                                self.hasLoadedImages = true
                                DRDebug("[DessertVoucherCard-\(instanceId.prefix(6))] 图标加载完成")
                            }
                        } else {
                            loadIconFallback(dessertId: dessertId)
                        }
                    }
                } else {
                    loadIconFallback(dessertId: dessertId)
                }
            } else {
                // 图标已存在，直接设置完成标志
                if voucherImageURL != nil {
                    hasLoadedImages = true
                    DRDebug("[DessertVoucherCard-\(instanceId.prefix(6))] 图标已存在，图片URL已设置，标记为已加载")
                }
            }
        } else {
            // 找不到关联美食券时使用简单加载方式
            let dessertId = record.dessert.id
            
            if voucherImageURL == nil {
                voucherImageURL = APIService.shared.getDessertImageURL(dessertId: dessertId, type: "voucher")
                
                // 标记图片部分加载完成
                if iconImage != nil {
                    hasLoadedImages = true
                }
            }
            
            if iconImage == nil {
                loadIconFallback(dessertId: dessertId)
            } else if voucherImageURL != nil {
                hasLoadedImages = true
                DRDebug("[DessertVoucherCard-\(instanceId.prefix(6))] 未找到关联美食券，但图片和图标已加载")
            }
        }
    }
    
    // 加载图标的备用方法
    private func loadIconFallback(dessertId: String) {
        // 从后端获取icon类型图片URL
        let iconURL = APIService.shared.getDessertImageURL(dessertId: dessertId, type: "icon")
        if let url = iconURL {
            // 使用改进的ImageCacheService直接获取图片
            ImageCacheService.shared.downloadAndCacheImage(url: url.absoluteString) { [self] image in
                if let image = image {
                    DispatchQueue.main.async {
                        self.iconImage = image
                        // 仅当同时有voucherImageURL时才标记为已完成
                        if self.voucherImageURL != nil {
                            self.hasLoadedImages = true
                            DRDebug("[DessertVoucherCard-\(instanceId.prefix(6))] 图标加载完成，美食券图片URL已存在，标记为已加载")
                        }
                    }
                } else {
                    // 图标加载失败，但仍需检查是否可以标记为已完成
                    DispatchQueue.main.async {
                        if self.voucherImageURL != nil {
                            self.hasLoadedImages = true
                            DRDebug("[DessertVoucherCard-\(instanceId.prefix(6))] 图标加载失败，但美食券图片URL已存在，标记为已加载")
                        }
                    }
                }
            }
        } else {
            // 获取图标URL失败，检查是否可以标记为已完成
            DispatchQueue.main.async {
                if self.voucherImageURL != nil {
                    self.hasLoadedImages = true
                    DRDebug("[DessertVoucherCard-\(instanceId.prefix(6))] 无法获取图标URL，但美食券图片URL已存在，标记为已加载")
                }
            }
        }
    }
    
    // MARK: - 卡片主体部分
    private var cardHeader: some View {
        GeometryReader { geometry in 
            ZStack(alignment: .leading) {
                // 1. 白色边框 - 只在上边加圆角
                // 注意：使用Path而不是clipShape以确保边框正确渲染
                Path { path in
                    // 上边的圆角边框路径
                    let _ = CGRect(x: 0, y: 0, width: geometry.size.width, height: geometry.size.height)
                    // 圆角大小
                    let cornerRadius: CGFloat = 20
                    
                    // 从左上角开始，顺时针绘制
                    path.move(to: CGPoint(x: 0, y: cornerRadius)) // 左上圆角起始点
                    
                    // 添加左上圆角
                    path.addArc(
                        center: CGPoint(x: cornerRadius, y: cornerRadius),
                        radius: cornerRadius,
                        startAngle: .degrees(180),
                        endAngle: .degrees(270),
                        clockwise: false
                    )
                    
                    // 上边
                    path.addLine(to: CGPoint(x: geometry.size.width - cornerRadius, y: 0))
                    
                    // 添加右上圆角
                    path.addArc(
                        center: CGPoint(x: geometry.size.width - cornerRadius, y: cornerRadius),
                        radius: cornerRadius,
                        startAngle: .degrees(270),
                        endAngle: .degrees(0),
                        clockwise: false
                    )
                    
                    // 右边
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                    
                    // 底部 - 无圆角
                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height))
                    
                    // 左边
                    path.addLine(to: CGPoint(x: 0, y: cornerRadius))
                }
                .stroke(Color.gray.opacity(0.2), lineWidth: 1) // 边框颜色调整为浅灰色
                
                // 3. 内容布局 - 三段式布局
                HStack(spacing: 0) {
                    // 左侧部分 - 固定宽度
                    VStack(alignment: .leading) {
                        if forceExpanded {
                            // 展开状态使用顶部对齐
                            HStack(spacing: 0) {
                                // 左侧美食及消耗美食数量的文本信息
                                VStack(alignment: .leading, spacing: 3) {
                                    // 添加标题"您已消耗："
                                    Text("您已消耗：")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(Color(hex: "757575"))
                                        .padding(.bottom, 12)
                                        .frame(height: 24) // 统一标题高度
                                        .opacity(animateExtraContent ? 1 : 0) // 第二阶段：额外文字内容
                                    
                                    // 美食数量和名称整合显示
                                    Text("\(String(format: "%.1f", record.equivalentDessertCount))个\(record.dessert.name)")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(Color.black)
                                        .lineLimit(3) // 最多3行
                                        .fixedSize(horizontal: false, vertical: true) // 确保文字完整显示
                                        .multilineTextAlignment(.leading)
                                        .frame(width: geometry.size.width * 0.35 - 20) // 设置固定宽度
                                        .opacity(animateBaseContent ? 1 : 0) // 第一阶段：基础文字内容
                                    
                                    // 移动workout_tag到左侧并修改颜色
                                    Text(record.displayWorkoutTag)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(hex: "#FF318D")) // 使用与核销按钮相同的粉色
                                        .fixedSize(horizontal: false, vertical: true)
                                        .multilineTextAlignment(.leading)
                                        .padding(.top, 6)
                                        .opacity(animateExtraContent ? 1 : 0) // 第二阶段：额外文字内容
                                        .frame(width: geometry.size.width * 0.35 - 20) // 设置与上面相同的宽度
                                }
                                .padding(.leading, forceExpanded ? 30 : 30) // 减少左侧内边距，从50/45减少到30
                                .offset(y: isAnimating ? -8 : -8) // 展开时向上对齐
                                .padding(.top, 12) // 展开时增加上边距
                            }
                            Spacer() // 添加Spacer使内容靠上对齐
                        } else {
                            // 收起状态使用居中对齐
                            Spacer() // 添加顶部Spacer确保内容居中
                            HStack(spacing: 5) {
                                // 左侧美食及消耗美食数量的文本信息
                                VStack(alignment: .leading, spacing: 3) {
                                    // 整合美食数量和名称显示
                                    Text("\(String(format: "%.1f", record.equivalentDessertCount))个\(record.dessert.name)")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color.black)
                                        .lineLimit(2) // 限制最多2行
                                        .fixedSize(horizontal: false, vertical: true) // 确保文字完整显示
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(.leading, 30) // 减少左侧内边距，从45减少到30
                            }
                            Spacer() // 添加底部Spacer确保内容居中
                        }
                    }
                    .frame(width: max(20, geometry.size.width * 0.4 - 20)) // 恢复为40%宽度
                    .zIndex(10) // 确保文字在图片上面
                    
                    // 中间分隔线
                    Rectangle()
                        .fill(Color(hex: "#D7B8BE"))
                        .frame(width: 1, height: forceExpanded ? 180 : 55)
                        .padding(.horizontal, 15)
                        .opacity(forceExpanded ? (animateExtraContent ? 1 : 0) : 1) // 第二阶段：额外文字内容
                    
                    // 右侧信息区
                    VStack(alignment: .leading, spacing: forceExpanded ? 6 : 2) {
                        if forceExpanded {
                            // 展开状态使用顶部对齐
                            // 添加标题"您已打卡："
                            Text("您已打卡：")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(Color(hex: "757575"))
                                .padding(.bottom, 4)
                                .frame(height: 24) // 统一标题高度
                                .opacity(animateExtraContent ? 1 : 0) // 第二阶段：额外文字内容
                                
                            Text(record.exerciseType.name)
                                .font(.system(size: 24, weight: .semibold)) 
                                .lineLimit(2) // 限制最多2行
                                .fixedSize(horizontal: false, vertical: true) // 确保文字完整显示
                                .offset(y: 0) // 删除向上偏移，保持与左侧文本对齐
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading) // 修改为可扩展最大宽度
                                .opacity(animateBaseContent ? 1 : 0) // 第一阶段：基础文字内容
                            
                            // 展开时显示运动详情
                            VStack(alignment: .leading, spacing: 8) {
                                // 只展示有效数据（不为0的数据）
                                
                                // 运动时长 - 如果有效则显示
                                if let duration = record.duration, duration > 0 {
                                    HStack(spacing: 6) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hex: "#FF7B15"))
                                        
                                        // 后端返回的是分钟数，而不是秒数
                                        Text(formatDuration(minutes: Int(duration)))
                                            .font(.system(size: 14))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .opacity(animateExtraContent ? 1 : 0) // 第二阶段：额外文字内容
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                }
                                
                                // 运动距离 - 如果有效则显示
                                if let distance = record.distance, distance > 0 {
                                    HStack(spacing: 6) {
                                        Image(systemName: "figure.walk")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(hex: "#FF7B15"))
                                        
                                        // 后端返回的单位已经是公里
                                        Text(String(format: "%.1f公里", distance))
                                            .font(.system(size: 14))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .opacity(animateExtraContent ? 1 : 0) // 第二阶段：额外文字内容
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                }
                                
                                // 消耗热量 - 所有类型都显示
                                HStack(spacing: 6) {
                                    Image(systemName: "flame.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.red)
                                    
                                    Text("\(Int(record.caloriesBurned))卡路里")
                                        .font(.system(size: 14))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .opacity(animateExtraContent ? 1 : 0) // 第二阶段：额外文字内容
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                
                                // 日期放在这里与其他信息对齐 - 去掉icon
                                Text(formattedDateTime(record.date))
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "#919191"))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .opacity(animateExtraContent ? 1 : 0) // 第二阶段：额外文字内容
                                    .padding(.top, 2)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading) // 修改为可扩展最大宽度
                            }
                            .padding(.top, 6)
                            
                            Spacer() // 添加底部Spacer确保内容靠上对齐
                        } else {
                            // 收起状态使用居中对齐
                            Spacer() // 添加顶部Spacer确保内容居中
                            Text(record.exerciseType.name)
                                .font(.system(size: 16, weight: .semibold))
                                .lineLimit(2) // 限制最多2行
                                .fixedSize(horizontal: false, vertical: true) // 确保文字完整显示
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading) // 修改为可扩展最大宽度
                            Spacer() // 添加底部Spacer确保内容居中
                        }
                    }
                    .padding(.trailing, 55) // 为右侧图片留出空间
                    .zIndex(10) // 确保文字在最上层
                    
                    Spacer(minLength: 0)
                }
                .padding(.leading, 16) // 左侧留出空间
                .padding(.top, forceExpanded ? 24 : 10) // 增加顶部间距，使内容下移
            }
            .frame(height: forceExpanded ? 220 : 75)
            .background(Color.clear) // 确保背景透明
        }
        .frame(height: forceExpanded ? 220 : 75)
    }
    
    // 格式化时长的辅助函数 - 修改单位为分钟
    private func formatDuration(minutes: Int) -> String {
        // 如果分钟数为0，返回默认时长
        if minutes <= 0 {
            return "未记录时间"
        }
        
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 {
            return "\(hours)小时\(mins)分钟"
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
        }
        
        // 默认30天过期期限
        let calendar = Calendar.current
        if let expiryDate = calendar.date(byAdding: .day, value: 30, to: record.date) {
            return dateFormatter.string(from: expiryDate)
        }
        
        return "未知"
    }
    
    // MARK: - 卡片底部部分
    private var cardFooter: some View {
        // 底部核销区域 - 不使用GeometryReader，简化结构
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                if forceExpanded {
                    Text("美食券")
                        .font(.system(size: 14, weight: .medium))
                }
                
                // 使用美食券的剩余天数
                let daysRemaining = associatedVoucher?.remainingDays ?? calculateRemainingDays()
                // 剩余天数
                Text("剩余\(daysRemaining)天")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 核销按钮
            Button(action: {
                showRedeemConfirm = true
            }) {
                Text("立即核销")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 14)
                    .background(Color(hex: "#FE2D55"))
                    .cornerRadius(8)
            }
            .disabled(isRedeeming)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8) // 垂直内边距
        .frame(height: 40) // 固定高度
        .background(
            CustomShape(radius: 10, corners: [.bottomLeft, .bottomRight])
                .fill(Color.white)
        )
        .overlay(
            // 只添加顶部的虚线分隔线
            GeometryReader { geo in
                Rectangle()
                    .frame(width: geo.size.width, height: 1)
                    .foregroundColor(Color.gray.opacity(0.5))
                    .position(x: geo.size.width/2, y: 0.5) // 放置在顶部
                    .overlay(
                        Rectangle()
                            .frame(width: geo.size.width, height: 1)
                            .foregroundColor(.white)
                            .mask(
                                HStack(spacing: 2.5) {
                                    ForEach(0..<Int(geo.size.width/5), id: \.self) { _ in
                                        Rectangle().frame(width: 2.5, height: 1)
                                        Spacer().frame(width: 2.5)
                                    }
                                }
                            )
                            .position(x: geo.size.width/2, y: 0.5) // 放置在顶部
                    )
            }
        )
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

// 自定义形状，用于创建只有指定角为圆角的形状
struct CustomShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        // 创建贝塞尔路径
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// 添加一个完整卡片形状的结构体，用于勾边效果
struct FullCardShape: Shape {
    var topRadius: CGFloat
    var bottomRadius: CGFloat
    var topHeight: CGFloat
    var bottomHeight: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let totalHeight = topHeight + bottomHeight
        let width = rect.width
        
        // 从左上角开始，顺时针绘制
        path.move(to: CGPoint(x: 0, y: topRadius))
        
        // 左上角圆弧
        path.addArc(
            center: CGPoint(x: topRadius, y: topRadius),
            radius: topRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        
        // 上边
        path.addLine(to: CGPoint(x: width - topRadius, y: 0))
        
        // 右上角圆弧
        path.addArc(
            center: CGPoint(x: width - topRadius, y: topRadius),
            radius: topRadius,
            startAngle: .degrees(270),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        // 右边到底部副券部分
        path.addLine(to: CGPoint(x: width, y: topHeight))
        
        // 右边副券部分
        path.addLine(to: CGPoint(x: width, y: totalHeight - bottomRadius))
        
        // 右下角圆弧
        path.addArc(
            center: CGPoint(x: width - bottomRadius, y: totalHeight - bottomRadius),
            radius: bottomRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        
        // 底边
        path.addLine(to: CGPoint(x: bottomRadius, y: totalHeight))
        
        // 左下角圆弧
        path.addArc(
            center: CGPoint(x: bottomRadius, y: totalHeight - bottomRadius),
            radius: bottomRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        
        // 左边副券部分
        path.addLine(to: CGPoint(x: 0, y: topHeight))
        
        // 左边回到起点
        path.addLine(to: CGPoint(x: 0, y: topRadius))
        
        return path
    }
}

// 添加一个用于对角线渐显效果的遮罩结构体
struct DiagonalGradientMask: View {
    var progress: CGFloat // 0到1表示显示进度
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let diagonal = sqrt(width * width + height * height)
            
            // 计算圆形的半径，根据进度从0增长到对角线长度
            let radius = diagonal * progress
            
            // 创建以左上角为中心的圆形，用于实现扩散效果
            Circle()
                .frame(width: radius * 2, height: radius * 2)
                .position(x: 0, y: 0) // 圆心位于左上角
                .foregroundColor(.white) // 在遮罩中颜色不重要，只使用alpha值
        }
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
