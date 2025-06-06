import SwiftUI
import Combine

/// 美食券卡片视图（简化版本）
struct DessertVoucherCardSimple: View {
    /// 美食券
    let voucher: DessertVoucher
    
    /// 运动记录（可选，仅在展开详情时加载）
    @State private var workoutRecord: WorkoutRecord?
    
    /// 是否正在加载运动记录
    @State private var isLoadingRecord: Bool = false
    
    /// 是否正在核销
    @State private var isRedeeming: Bool = false
    
    /// 核销相关错误
    @State private var redeemError: String? = nil
    
    /// 显示核销确认
    @State private var showRedeemConfirm: Bool = false
    
    /// 强制展开状态（用于弹窗展示）
    var forceExpanded: Bool = false
    
    /// 是否用于分享（跳过动画）
    var isForSharing: Bool = false
    
    /// 分享模式下的数据加载状态
    @State private var sharingDataReady: Bool = false
    
    /// 分享模式下的图片加载状态
    @State private var sharingImagesReady: Bool = false
    
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
    
    /// 使用voucher.id作为唯一ID，保证切换其他视图时不重新生成，避免闪动
    private var stableId: String { voucher.id }
    
    /// 提供一个环境变量，用于触发弹窗展示
    @Environment(\.presentationMode) var presentationMode
    
    /// 添加环境对象，用于获取美食券信息
    @EnvironmentObject var appState: AppState
    
    /// ViewModel引用，用于加载运动记录
    @ObservedObject private var viewModel = FoodCheckInViewModel.shared
    
    /// 添加状态变量存储图标图片
    @State private var iconImage: UIImage? = nil
    
    /// 添加状态变量存储美食券大图片
    @State private var voucherImage: UIImage? = nil
    
    /// 添加状态便捷属性
    private var status: VoucherStatus { voucher.voucherStatus }
    private var isInactive: Bool { status == .inactive }
    private var isActive: Bool { status == .active }
    
    /// 添加Combine cancellables
    @State private var cancellables: Set<AnyCancellable> = []
    
    /// 分享模式下的图片加载状态跟踪
    @State private var voucherImageLoaded: Bool = false
    @State private var iconImageLoaded: Bool = false
    @State private var imagesNotificationSent: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // 背景层
                backgroundLayer
                
                // 图片层
                imageLayer(geometry: geometry)
                
                // 文字内容层
                VStack(spacing: 0) {
                    cardHeader
                }
                .zIndex(10)
                
                // 底部操作层
                if !forceExpanded && isInactive {
                    cardFooter
                        .frame(width: geometry.size.width)
                        .offset(y: 75)
                        .zIndex(10)
                }
            }
            .frame(width: geometry.size.width)
        }
        .padding(0)
        .frame(height: forceExpanded ? 220 : (75 + (isInactive ? 40 : 0)))
        .id("card-\(stableId)")
        .grayscale(isInactive ? 1.0 : 0.0)
        .onAppear {
            loadImages()
            
            if forceExpanded {
                loadWorkoutRecordIfNeeded()
                
                if isForSharing {
                    checkSharingReadiness()
                } else {
                    animateSequence()
                }
            } else {
                resetAnimations(true)
            }
        }
        .onChange(of: forceExpanded) { _, newValue in
            if newValue {
                loadWorkoutRecordIfNeeded()
                
                if isForSharing {
                    resetAnimations(true)
                    isAnimating = true
                } else {
                    animateSequence()
                }
            } else {
                reverseAnimateSequence()
            }
        }
        .onTapGesture {
            guard !forceExpanded else { return }
            if isInactive {
                NotificationCenter.default.post(name: NSNotification.Name("GoWorkoutFromTaskCard"), object: voucher)
            } else {
                var userInfo: [String: Any] = [
                    "preloadedImages": hasLoadedImages,
                    "instanceId": stableId,
                    "voucherId": voucher.id
                ]
                if let imageURL = voucherImageURL {
                    userInfo["imageURL"] = imageURL.absoluteString
                }
                if iconImage != nil {
                    userInfo["iconLoaded"] = true
                }
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowExpandedCard"),
                    object: voucher,
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
    
    // MARK: - 加载运动记录
    private func loadWorkoutRecordIfNeeded() {
        // 检查是否有运动记录ID
        guard let recordId = voucher.workoutRecordId, !recordId.isEmpty else {
            DRWarning("[DessertVoucherCard] 没有运动记录ID，跳过加载")
            return
        }
        
        // 如果已经有记录且非强制刷新，跳过
        guard workoutRecord == nil else {
            if isForSharing {
            }
            return
        }
        
        isLoadingRecord = true
        
        // 使用APIService直接调用
        APIService.shared.loadSingleWorkoutRecord(id: recordId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoadingRecord = false
                    
                    if case .failure(let error) = completion {
                        DRError("[DessertVoucherCard] 加载运动记录失败: \(error)")
                        
                        if isForSharing {
                            DRError("🎯 分享模式 - 运动记录加载失败，这可能导致分享内容不完整")
                        }
                    }
                },
                receiveValue: { record in
                    if let record = record {
                        workoutRecord = record
                        
                        if isForSharing {
                            
                            // 通知分享模式运动记录已加载完成
                            onWorkoutRecordLoaded()
                            
                            // 发送运动记录加载完成通知
                            NotificationCenter.default.post(name: NSNotification.Name("ShareVoucherWorkoutRecordLoaded"), object: nil)
                        }
                    } else {
                        DRError("[DessertVoucherCard] 运动记录为空")
                        
                        if isForSharing {
                            DRError("🎯 分享模式 - 运动记录为空，这可能导致分享内容不完整")
                            
                            // 即使运动记录为空，也通知分享模式继续
                            onWorkoutRecordLoaded()
                            
                            // 发送运动记录加载完成通知（即使为空）
                            NotificationCenter.default.post(name: NSNotification.Name("ShareVoucherWorkoutRecordLoaded"), object: nil)
                        }
                    }
                }
            )
            .store(in: &cancellables)
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
        // 已不再使用自定义下载逻辑，全部改为系统 AsyncImage + URLCache
        // 仅保留占位逻辑，直接标记为已加载并返回
        hasLoadedImages = true
        return
        // 下面原先的实现被保留以备回退，但不会再执行
        // ... existing code ...
    }
    
    // MARK: - 卡片主体部分
    private var cardHeader: some View {
        GeometryReader { geometry in 
            ZStack(alignment: .leading) {
                // 重新使用完整圆角矩形描边
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                
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
                                    Text("\(String(format: "%.1f", voucher.equivalentDessertCount))个\(voucher.dessertName ?? "未知美食")")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(Color.black)
                                        .lineLimit(3) // 最多3行
                                        .fixedSize(horizontal: false, vertical: true) // 确保文字完整显示
                                        .multilineTextAlignment(.leading)
                                        .frame(width: geometry.size.width * 0.35 - 20) // 设置固定宽度
                                        .opacity(animateBaseContent ? 1 : 0) // 第一阶段：基础文字内容
                                    
                                    // 如果已加载运动记录，显示workout_tag
                                    if let record = workoutRecord {
                                        Text(record.displayWorkoutTag)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(hex: "#FF318D")) // 使用与核销按钮相同的粉色
                                            .fixedSize(horizontal: false, vertical: true)
                                            .multilineTextAlignment(.leading)
                                            .padding(.top, 6)
                                            .opacity(animateExtraContent ? 1 : 0) // 第二阶段：额外文字内容
                                            .frame(width: geometry.size.width * 0.35 - 20) // 设置与上面相同的宽度
                                    }
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
                                    Text("\(String(format: "%.1f", voucher.equivalentDessertCount))个\(voucher.dessertName ?? "未知美食")")
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
                                
                            Text(voucher.exerciseName ?? "未知运动")
                                .font(.system(size: 24, weight: .semibold)) 
                                .lineLimit(2) // 限制最多2行
                                .fixedSize(horizontal: false, vertical: true) // 确保文字完整显示
                                .offset(y: 0) // 删除向上偏移，保持与左侧文本对齐
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading) // 修改为可扩展最大宽度
                                .opacity(animateBaseContent ? 1 : 0) // 第一阶段：基础文字内容
                            
                            // 展开时显示运动详情
                            VStack(alignment: .leading, spacing: 8) {
                                if isLoadingRecord {
                                    // 正在加载时显示加载状态 - 使用纯SwiftUI旋转指示器
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                                .frame(width: 16, height: 16)
                                            
                                            Circle()
                                                .trim(from: 0, to: 0.8)
                                                .stroke(Color.gray, lineWidth: 2)
                                                .frame(width: 16, height: 16)
                                                .rotationEffect(.degrees(isLoadingRecord ? 360 : 0))
                                                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isLoadingRecord)
                                        }
                                        .scaleEffect(0.8)
                                        
                                        Text("加载详情...")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                            .padding(.leading, 4)
                                    }
                                    .opacity(animateExtraContent ? 1 : 0)
                                } else if let record = workoutRecord {
                                    // 已加载运动记录，显示详情
                                    
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
                                    
                                    // 添加券号显示
                                    HStack(spacing: 6) {
                                        Image(systemName: "ticket")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(hex: "#FF7B15"))
                                        
                                        Text("券号: #\(String(voucher.id.prefix(8)))")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(hex: "#919191"))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .opacity(animateExtraContent ? 1 : 0) // 第二阶段：额外文字内容
                                    .padding(.top, 4)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                } else {
                                    // 运动记录加载失败，显示基本信息
                                    
                                    // 消耗热量 - 显示美食券中的热量值
                                    HStack(spacing: 6) {
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(.red)
                                        
                                        Text("\(Int(voucher.caloriesValue))卡路里")
                                            .font(.system(size: 14))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .opacity(animateExtraContent ? 1 : 0) // 第二阶段：额外文字内容
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                    
                                    // 日期使用美食券的创建日期
                                    Text(formattedDateTime(voucher.createdAt))
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#919191"))
                                        .fixedSize(horizontal: false, vertical: true)
                                        .opacity(animateExtraContent ? 1 : 0) // 第二阶段：额外文字内容
                                        .padding(.top, 2)
                                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading) // 修改为可扩展最大宽度
                                    
                                    // 添加券号显示
                                    HStack(spacing: 6) {
                                        Image(systemName: "ticket")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(hex: "#FF7B15"))
                                        
                                        Text("券号: #\(String(voucher.id.prefix(8)))")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(hex: "#919191"))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .opacity(animateExtraContent ? 1 : 0) // 第二阶段：额外文字内容
                                    .padding(.top, 4)
                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.top, 6)
                            
                            Spacer() // 添加底部Spacer确保内容靠上对齐
                        } else {
                            // 收起状态使用居中对齐
                            Spacer() // 添加顶部Spacer确保内容居中
                            Text(voucher.exerciseName ?? "未知运动")
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
                .padding(.top, forceExpanded ? 12 : 10) // 顶部间距
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
        
        if let expireDate = voucher.expireAt {
            return dateFormatter.string(from: expireDate)
        }
        
        // 默认30天过期期限
        let calendar = Calendar.current
        if let expiryDate = calendar.date(byAdding: .day, value: 30, to: voucher.createdAt) {
            return dateFormatter.string(from: expiryDate)
        }
        
        return "未知"
    }
    
    // MARK: - 卡片底部部分
    private var cardFooter: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                // 标签：任务卡/美食券
                Text(isInactive ? "任务卡" : "美食券")
                    .font(.system(size: 14, weight: .medium))
                // 剩余天数
                Text("剩余\(voucher.remainingDays)天")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            Spacer()
            // 根据状态显示按钮或占位
            if isInactive {
                // 去运动按钮
                Button(action: {
                    // 发送通知，外部可导航去运动
                    NotificationCenter.default.post(name: NSNotification.Name("GoWorkoutFromTaskCard"), object: voucher)
                }) {
                    Text("去运动")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 14)
                        .background(Color(hex: "#9E9E9E"))
                        .cornerRadius(8)
                }
            } else if status == .used {
                Text("已使用")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            } else if status == .expired {
                Text("已过期")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(height: 40)
        .background(
            CustomShape(radius: 10, corners: [.bottomLeft, .bottomRight])
                .fill(Color.white)
        )
        .overlay(
            GeometryReader { geo in
                Rectangle()
                    .frame(width: geo.size.width, height: 1)
                    .foregroundColor(Color.gray.opacity(0.5))
                    .position(x: geo.size.width/2, y: 0.5)
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
                            .position(x: geo.size.width/2, y: 0.5)
                    )
            }
        )
    }
    
    // MARK: - 核销操作
    private func redeemVoucher() {
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
    
    // MARK: - 分享模式逻辑
    private func checkSharingReadiness() {
        
        // 分享模式下立即显示所有内容，不等待网络数据
        sharingDataReady = true
        
        // ✅ 关键修复：立即显示图片
        animateVisuals = true
        
        // 检查是否有有效的图片URL
        let hasVoucherImage = !(voucher.displayVoucherImageURL?.isEmpty ?? true)
        let hasIconImage = !(voucher.displayDessertIconURL?.isEmpty ?? true)
        
        // 如果没有任何图片需要加载，立即标记图片为就绪
        if !hasVoucherImage && !hasIconImage {
            voucherImageLoaded = true
            iconImageLoaded = true
            sharingImagesReady = true
        } else {
            // 根据实际需要加载的图片设置初始状态
            if !hasVoucherImage {
                voucherImageLoaded = true
            }
            if !hasIconImage {
                iconImageLoaded = true
            }
            
            // 如果实际上都不需要加载，标记为就绪
            if voucherImageLoaded && iconImageLoaded {
                sharingImagesReady = true
            }
        }
        
        // 立即显示内容
        resetAnimations(true)
        isAnimating = true
        
        // 如果需要运动记录，在后台加载但不阻塞显示
        let needsWorkoutRecord = voucher.workoutRecordId != nil && !voucher.workoutRecordId!.isEmpty
        if needsWorkoutRecord && workoutRecord == nil {
            loadWorkoutRecordIfNeeded()
        } else {
            // 运动记录也不需要加载，检查是否可以立即发送通知
            if sharingDataReady && sharingImagesReady {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let notificationName = "ShareContentReady_\(voucher.id)"
                    NotificationCenter.default.post(name: NSNotification.Name(notificationName), object: nil)
                }
            }
        }
    }
    
    // 监听运动记录加载完成
    private func onWorkoutRecordLoaded() {
        if isForSharing {
            sharingDataReady = true
            
            if sharingDataReady && sharingImagesReady {
                
                // 稍微延迟一点确保UI完全渲染完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let notificationName = "ShareContentReady_\(voucher.id)"
                    NotificationCenter.default.post(name: NSNotification.Name(notificationName), object: nil)
                }
            } else {
                
                // 如果图片都加载完了但sharingImagesReady还是false，手动触发检查
                if voucherImageLoaded && iconImageLoaded && !sharingImagesReady {
                    checkAllImagesLoaded()
                }
            }
        }
    }
    
    /// 检查并通知图片加载完成
    private func checkAndNotifyImagesLoaded() {
        guard isForSharing && !imagesNotificationSent else { return }
        
        // 检查调用来源并更新对应状态
        if Thread.callStackSymbols.contains(where: { $0.contains("voucher") || $0.contains("displayVoucherImageURL") }) {
            voucherImageLoaded = true
        } else if Thread.callStackSymbols.contains(where: { $0.contains("icon") || $0.contains("displayDessertIconURL") }) {
            iconImageLoaded = true
        }
        
        // 检查是否两个图片都已加载完成
        if voucherImageLoaded && iconImageLoaded {
            imagesNotificationSent = true
            sharingImagesReady = true
            
            // 如果是分享模式且所有数据都准备好了，立即发送完整的内容准备通知
            if isForSharing && sharingDataReady && sharingImagesReady {
                
                // 稍微延迟一点确保UI完全渲染完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let notificationName = "ShareContentReady_\(voucher.id)"
                    NotificationCenter.default.post(name: NSNotification.Name(notificationName), object: nil)
                }
            }
            
            // 原有的通知保持不变（用于其他用途）
            NotificationCenter.default.post(name: NSNotification.Name("ShareVoucherImagesLoaded"), object: nil)
        }
    }
    
    /// 标记美食券大图加载完成
    private func markVoucherImageLoaded() {
        guard isForSharing && !imagesNotificationSent else { return }
        
        voucherImageLoaded = true
        checkAllImagesLoaded()
    }
    
    /// 标记图标加载完成
    private func markIconImageLoaded() {
        guard isForSharing && !imagesNotificationSent else { return }
        
        iconImageLoaded = true
        checkAllImagesLoaded()
    }
    
    /// 检查所有图片是否加载完成
    private func checkAllImagesLoaded() {
        if voucherImageLoaded && iconImageLoaded {
            imagesNotificationSent = true
            sharingImagesReady = true
            
            // 如果是分享模式且所有数据都准备好了，立即发送完整的内容准备通知
            if isForSharing && sharingDataReady && sharingImagesReady {
                
                // 稍微延迟一点确保UI完全渲染完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let notificationName = "ShareContentReady_\(voucher.id)"
                    NotificationCenter.default.post(name: NSNotification.Name(notificationName), object: nil)
                }
            }
            
            // 原有的通知保持不变（用于其他用途）
            NotificationCenter.default.post(name: NSNotification.Name("ShareVoucherImagesLoaded"), object: nil)
        }
    }
    
    // MARK: - 拆分的视图组件
    
    /// 背景层组件
    private var backgroundLayer: some View {
        Group {
            if forceExpanded {
                // 展开状态的渐变背景
                ZStack {
                    // 渐变背景
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color(hex: "#FF9D0B"), location: 0),
                            .init(color: Color(hex: "#FFEAC5"), location: 0.59),
                            .init(color: Color(hex: "#FFE5EC"), location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .frame(height: 220)
                    .opacity(animateGradientBackground ? 1 : 0)
                    .animation(.easeIn(duration: 0.3), value: animateGradientBackground)
                    
                    // 边缘高亮描边
                    borderHighlight
                    
                    // 光韵效果
                    shineEffect
                }
            } else {
                // 收起状态的白色背景
                Color.white
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }
    
    /// 边缘高亮描边组件
    private var borderHighlight: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.white.opacity(1), location: 0),
                        .init(color: Color.white.opacity(0.8), location: 0.3),
                        .init(color: Color.white.opacity(0.6), location: 0.7),
                        .init(color: Color.white.opacity(0.4), location: 1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), lineWidth: 2
            )
            .opacity(animateEdgeHighlight ? 1 : 0)
    }
    
    /// 光韵效果组件
    private var shineEffect: some View {
        ZStack {
            Color.clear
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
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
                    .opacity(animateBackgroundShine ? 1 : 0)
                )
                .mask(RoundedRectangle(cornerRadius: 20).fill(Color.black))
        }
        .frame(height: 220)
    }
    
    /// 图片层组件
    private func imageLayer(geometry: GeometryProxy) -> some View {
        Group {
            if forceExpanded {
                // 展开状态的图片
                expandedImages(geometry: geometry)
            } else {
                // 收起状态的图片
                collapsedImages(geometry: geometry)
            }
        }
    }
    
    /// 展开状态的图片组件
    private func expandedImages(geometry: GeometryProxy) -> some View {
        Group {
            // 美食券大图
            voucherImageView(size: 90)
                .position(x: max(30, geometry.size.width - 60), y: 170)
                .scaleEffect(animateVisuals ? 1 : 0.6)
                .opacity(animateVisuals ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateVisuals)
                .zIndex(1)
                .onAppear {
                    if isForSharing {
                    }
                }
            
            // 美食图标
            iconImageView(size: 42)
                .position(x: 22, y: 190)
                .scaleEffect(animateVisuals ? 1 : 0.6)
                .opacity(animateVisuals ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animateVisuals)
                .zIndex(5)
                .onAppear {
                    if isForSharing {
                    }
                }
        }
    }
    
    /// 收起状态的图片组件
    private func collapsedImages(geometry: GeometryProxy) -> some View {
        Group {
            // 美食券图片
            voucherImageView(size: 65)
                .position(x: max(30, geometry.size.width - 40), y: 38)
                .zIndex(1)
            
            // 美食图标
            iconImageView(size: 36)
                .position(x: 22, y: 56)
                .zIndex(5)
        }
    }
    
    /// 美食券图片视图
    private func voucherImageView(size: CGFloat) -> some View {
        Group {
            let imgURL = voucher.displayVoucherImageURL
            
            if isForSharing {
                // 分享模式 - 优先使用缓存中的图片
                if let urlString = imgURL, 
                   let url = URL(string: urlString),
                   let cachedResponse = URLCache.shared.cachedResponse(for: URLRequest(url: url)),
                   let image = UIImage(data: cachedResponse.data) {
                    
                    // 直接显示缓存的图片
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .onAppear {
                            markVoucherImageLoaded()
                        }
                } else {
                    // 缓存中没有图片，使用AsyncImage
                    AsyncImage(url: URL(string: imgURL ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable()
                                 .scaledToFit()
                                 .frame(width: size, height: size)
                                 .onAppear {
                                     markVoucherImageLoaded()
                                 }
                        case .failure(let error):
                            PlaceholderImageView(size: size)
                                .onAppear {
                                    DRError("🎯 分享模式 - 美食券图片AsyncImage加载失败: \(error)")
                                    markVoucherImageLoaded()
                                }
                        case .empty:
                            PlaceholderImageView(size: size)
                                .onAppear {
                                    markVoucherImageLoaded()
                                }
                        @unknown default:
                            PlaceholderImageView(size: size)
                                .onAppear {
                                    markVoucherImageLoaded()
                                }
                        }
                    }
                }
            } else {
                // 正常模式
                AsyncImage(url: URL(string: imgURL ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable()
                             .scaledToFit()
                             .frame(width: size, height: size)
                    } else {
                        PlaceholderImageView(size: size)
                    }
                }
            }
        }
    }
    
    /// 图标视图
    private func iconImageView(size: CGFloat) -> some View {
        Group {
            if isForSharing {
                // 分享模式 - 优先使用缓存中的图片
                if let urlString = voucher.displayDessertIconURL,
                   let url = URL(string: urlString),
                   let cachedResponse = URLCache.shared.cachedResponse(for: URLRequest(url: url)),
                   let image = UIImage(data: cachedResponse.data) {
                    
                    // 直接显示缓存的图片
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .onAppear {
                            markIconImageLoaded()
                        }
                } else {
                    // 缓存中没有图片，使用AsyncImage
                    AsyncImage(url: URL(string: voucher.displayDessertIconURL ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable()
                                 .scaledToFit()
                                 .frame(width: size, height: size)
                                 .onAppear {
                                     markIconImageLoaded()
                                 }
                        case .failure(let error):
                            PlaceholderImageView(size: size)
                                .onAppear {
                                    markIconImageLoaded()
                                }
                        case .empty:
                            PlaceholderImageView(size: size)
                                .onAppear {
                                    markIconImageLoaded()
                                }
                        @unknown default:
                            PlaceholderImageView(size: size)
                                .onAppear {
                                    markIconImageLoaded()
                                }
                        }
                    }
                }
            } else {
                // 正常模式
                AsyncImage(url: URL(string: voucher.displayDessertIconURL ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable()
                             .scaledToFit()
                             .frame(width: size, height: size)
                    } else {
                        PlaceholderImageView(size: size)
                    }
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
        DessertVoucherCardSimple(voucher: DessertVoucher.sample)
            .environmentObject(AppState.shared) // 使用单例而不是初始化新实例
            .frame(width: 350)
            .padding()
            .background(Color.gray.opacity(0.1))
    }
}
