import SwiftUI
import UIKit
import ConfettiSwiftUI

/// 挑战详情页面
struct ChallengeDetailView: View {
    // 环境对象
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode
    
    // 视图模型 - 接受外部传入的共享实例
    @ObservedObject var viewModel: ChallengeViewModel
    
    // 视图状态
    @State private var showingEnrollConfirmation = false
    @State private var showingEnrollmentForm = false
    @State private var showProgress = false
    @State private var progress: ChallengeProgressResponse?
    @State private var showGiftStatus = false
    @State private var voucherSheetHeight: CGFloat = UIScreen.main.bounds.height * 0.5
    @State private var showConfetti = false
    @State private var confettiCounter = 0
    @State private var isEnrolled = false
    
    // 展开美食券根级弹窗
    @State private var showExpandedVoucher = false
    @State private var selectedVoucherForPopup: DessertVoucher? = nil
    @State private var reopenVoucherSheetAfterFullScreen = false
    
    // 挑战ID
    let challengeId: String
    
    // 计算属性：获取当前挑战的报名信息
    private var currentEnrollment: EnrollmentWithChallengeDetail? {
        return viewModel.enrolledChallenges.first { $0.challenge.id == challengeId }
    }
    
    // 初始化 - 接受共享的viewModel
    init(challengeId: String, viewModel: ChallengeViewModel) {
        self.challengeId = challengeId
        self.viewModel = viewModel
    }
    
    var body: some View {
        mainContent
            .navigationBarHidden(true)
            .background(Color(UIColor.systemGray6))
            // 背景缩放
            .scaleEffect(showProgress ? 0.90 : 1)
            // 额外黑色遮罩而非简单降低不透明度
            .overlay(
                Color.black
                    .opacity(showProgress ? 0.55 : 0)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: 0.25), value: showProgress)
            )
            .animation(.easeInOut(duration: 0.25), value: showProgress)
            .onAppear {
                loadInitialData()
            }
            .onChange(of: viewModel.enrolledChallenges) { _, newValue in
                updateEnrollmentStatus(newValue)
            }
            .onChange(of: viewModel.progressResponse) { _, newProgressResponse in
                updateEnrollmentStatusFromProgress(newProgressResponse)
            }
            .onChange(of: appState.showWorkoutView) { _, showingWorkout in
                // 当开始运动打卡会话时，自动收起美食券列表
                if showingWorkout && showProgress {
                    DRInfo("[ChallengeDetailView] 检测到运动打卡会话开始，收起美食券列表")
                    showProgress = false
                }
                // 移除运动打卡会话结束后自动展开美食券列表的逻辑
                // 现在改为监听WorkoutFlowCoordinator的通知来控制
            }
            .alert("确认报名", isPresented: $showingEnrollConfirmation) {
                enrollmentAlert
            } message: {
                alertMessage
            }
            .sheet(isPresented: $showGiftStatus) {
                giftStatusSheet
            }
            .onDisappear {
                showTabBar()
            }
            .overlay(backButton, alignment: .topLeading)
            // 系统 sheet 显示进度面板
            .sheet(isPresented: $showProgress) {
                if let enrollment = currentEnrollment {
                    // 使用最新的progressResponse数据，如果没有则回退到enrollment数据
                    let latestCompletedCheckins: Int = {
                        if let progressResponse = viewModel.progressResponse {
                            return progressResponse.enrollment.completedCheckins
                        } else {
                            return enrollment.enrollment.completedCheckins
                        }
                    }()
                    
                    let latestStatus: String = {
                        if let progressResponse = viewModel.progressResponse {
                            return progressResponse.enrollment.status.rawValue
                        } else {
                            return enrollment.enrollment.status
                        }
                    }()
                    
                    VStack(spacing: 16) {
                        BasicEnrollmentVoucherListView(
                            sheetHeight: $voucherSheetHeight, 
                            enrollmentId: enrollment.enrollment.id,
                            challengeStatus: latestStatus,
                            completedCheckins: latestCompletedCheckins
                        )
                            .environmentObject(appState)

                        Button("关闭") { showProgress = false }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "FE2D55"))
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.white)
                            )
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                    }
                    .background(Color(UIColor.systemBackground))
                    .presentationDetents([.height(voucherSheetHeight)])
                    .presentationCornerRadius(25)
                }
            }
            // 展开美食券 - 全屏覆盖
            .fullScreenCover(isPresented: $showExpandedVoucher, onDismiss: {
                if reopenVoucherSheetAfterFullScreen {
                    reopenVoucherSheetAfterFullScreen = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        showProgress = true
                    }
                }
            }) {
                if let voucher = selectedVoucherForPopup {
                    ExpandedVoucherFullScreenView(voucher: voucher)
                        .environmentObject(appState)
                }
            }
            // 监听卡片展开通知
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowExpandedCard"))) { notification in
                if let voucher = notification.object as? DessertVoucher {
                    reopenVoucherSheetAfterFullScreen = showProgress
                    if showProgress {
                        showProgress = false
                    }
                    self.selectedVoucherForPopup = voucher
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.showExpandedVoucher = true
                    }
                }
            }
            // 监听WorkoutFlowCoordinator发送的显示美食券面板通知
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowVoucherPanel"))) { _ in
                DRInfo("[ChallengeDetailView] 收到ShowVoucherPanel通知，先更新进度数据再展开美食券面板")
                
                // 先更新挑战进度数据，确保获取到激活美食券后的最新状态
                viewModel.loadProgressByChallengeId(challengeId: challengeId)
                
                // 延迟展开美食券面板，等待API调用完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // 只有当用户已报名且状态为进行中时才展开
                    if self.isEnrolled,
                       let progressResponse = self.viewModel.progressResponse,
                       progressResponse.enrollment.status.rawValue == "ongoing" {
                        DRInfo("[ChallengeDetailView] 执行展开美食券面板")
                        self.showProgress = true
                    } else {
                        DRInfo("[ChallengeDetailView] 不展开美食券面板：未报名或状态不符合")
                    }
                }
            }
            // 监听挑战进度更新通知 - 移除自动进度更新逻辑
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChallengeProgressUpdated"))) { notification in
                if let progressInfo = notification.object as? ChallengeProgressInfo,
                   progressInfo.challengeId == challengeId {
                    DRInfo("[ChallengeDetailView] 收到挑战进度更新通知: \(progressInfo.challengeName ?? "挑战") \(progressInfo.completedCheckins)/\(progressInfo.requiredCheckins), 是否完成: \(progressInfo.isCompleted)")
                    
                    // 移除自动更新进度数据的逻辑，改为由WorkoutFlowCoordinator控制更新时机
                    // 这样避免在运动流程进行中触发美食券面板的自动展开
                    DRInfo("[ChallengeDetailView] 跳过自动进度更新，等待WorkoutFlowCoordinator控制更新时机")
                }
            }
    }
    
    // 主要内容区域
    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            scrollContent
            actionButtonArea
        }
    }
    
    // 滚动内容
    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 顶部背景图
                headerImage
                
                // 挑战内容区域
                challengeContentArea
                
                // 底部间距（移除或极小化）
                Spacer(minLength: 0)
            }
            .padding(.bottom, 86) // 16 基础间距 + 70 按钮高度
        }
    }
    
    // 挑战内容区域
    private var challengeContentArea: some View {
        VStack(spacing: 16) {
            // 挑战标题和基本信息
            challengeHeader
            
            // 进度信息（常驻显示，根据状态不同显示不同内容）
            if let challenge = viewModel.selectedChallenge {
                ChallengeProgressView(
                    isEnrolled: isEnrolled,
                    progressResponse: viewModel.progressResponse,
                    selectedChallenge: challenge,
                    currentEnrollment: currentEnrollment
                )
            }

            // 奖励信息
            rewardSection

            // 挑战要求和详细信息（去掉挑战描述部分）
            challengeRequirements
        }
        .padding(.horizontal, 20)
    }
    
    // 操作按钮区域
    private var actionButtonArea: some View {
        VStack(spacing: 0) {
            actionButton
                .padding(.horizontal, 20)
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.6)
                .blur(radius: 6)
        )
        .confettiCannon(trigger: $confettiCounter, num: 40, colors: [.red, .yellow, .green, .blue], radius: 400)
    }
    
    // 初始数据加载
    private func loadInitialData() {
        DRInfo("ChallengeDetailView loadInitialData: 开始加载挑战详情和相关数据")
        
        // 先清理之前的状态，避免显示错误的进度信息
        viewModel.progressResponse = nil
        viewModel.selectedEnrollment = nil
        appState.selectedEnrollmentId = nil
        isEnrolled = false
        showProgress = false
        
        // 加载挑战详情
        viewModel.loadChallengeDetail(id: challengeId)
        
        // // 先确保已报名挑战数据是最新的
        // DRInfo("加载已报名挑战列表以确保状态同步")
        // viewModel.loadEnrollments()
        
        // 先用已有数据同步 isEnrolled
        updateEnrollmentStatusFromProgress(viewModel.progressResponse)
        // 再发网络请求刷新
        viewModel.loadProgressByChallengeId(challengeId: challengeId)
        
        // 隐藏底部TabBar
        withAnimation(.easeInOut(duration: 0.25)) {
            appState.hideTabBarForDrag = true
        }
    }
    
    // 更新报名状态
    private func updateEnrollmentStatus(_ newValue: [EnrollmentWithChallengeDetail]) {
        // 更新报名状态
        DRInfo("enrollments.count=\(newValue.count)")
        for e in newValue {
            DRInfo("   enrollment.activityId=\(e.enrollment.activityId) | challenge.id=\(e.challenge.id)")
        }
        DRInfo("Current challengeId=\(challengeId)")
        let enrollment = newValue.first {
            $0.enrollment.activityId == challengeId ||
            $0.challenge.id == challengeId    // 有则再比
        }
        isEnrolled = enrollment != nil
        
        DRInfo("updateEnrollmentStatus: 挑战ID=\(challengeId.suffix(6)), 是否已报名=\(isEnrolled)")
        
        if let enrollment = enrollment {
            DRInfo("报名详情: 状态=\(enrollment.enrollment.enrollmentStatus), ID=\(enrollment.enrollment.id.suffix(6))")
        }
        
        // 进度百分比直接显示100%
        // 如果用户已报名且状态为进行中，默认展开美食券面板
        // 优先使用progressResponse中的状态，如果没有则使用enrolledChallenges中的状态
        // 但是需要避免在运动完成流程进行中时自动展开
        let shouldAutoExpand: Bool = {
            // 检查是否正在显示运动相关页面
            let isWorkoutFlowActive = appState.showWorkoutView
            
            if let progressResponse = viewModel.progressResponse {
                let shouldExpand = progressResponse.enrollment.status.rawValue == "ongoing" && !isWorkoutFlowActive
                DRInfo("基于progressResponse判断自动展开: 状态=\(progressResponse.enrollment.status.rawValue), 运动流程活跃=\(isWorkoutFlowActive), 展开=\(shouldExpand)")
                return shouldExpand
            } else if let enrollment = enrollment {
                let shouldExpand = enrollment.enrollment.enrollmentStatus == .ongoing && !isWorkoutFlowActive
                DRInfo("基于enrolledChallenges判断自动展开: 状态=\(enrollment.enrollment.enrollmentStatus), 运动流程活跃=\(isWorkoutFlowActive), 展开=\(shouldExpand)")
                return shouldExpand
            } else {
                DRInfo("无报名数据，不自动展开")
                return false
            }
        }()
        
        if shouldAutoExpand {
            DRInfo("延迟0.5秒后自动展开美食券面板")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                DRInfo("执行自动展开美食券面板")
                showProgress = true
            }
        } else if isEnrolled {
            DRInfo("跳过自动展开：运动流程正在进行中或状态不符合条件")
        }
    }
    
    // 更新报名状态从progressResponse
    private func updateEnrollmentStatusFromProgress(_ newProgressResponse: ChallengeProgressResponse?) {
        DRInfo("[ChallengeDetailView] updateEnrollmentStatusFromProgress: 开始更新报名状态")
        
        if let progressResponse = newProgressResponse {
            DRInfo("[ChallengeDetailView] updateEnrollmentStatusFromProgress: 收到进度数据 - 状态=\(progressResponse.enrollment.status.rawValue), 完成度=\(progressResponse.enrollment.completedCheckins)/\(progressResponse.challenge.requiredCheckins)")
        } else {
            DRInfo("[ChallengeDetailView] updateEnrollmentStatusFromProgress: 收到空的进度数据")
        }
        
        // 更新报名状态
        isEnrolled = newProgressResponse != nil

        // 恢复自动展开逻辑：如果用户已报名且状态为进行中，自动展开美食券面板
        // 但需要避免在运动流程进行中时自动展开
        if let progressResponse = newProgressResponse {
            let isWorkoutFlowActive = appState.showWorkoutView
            let shouldAutoExpand = progressResponse.enrollment.status.rawValue == "ongoing" && !isWorkoutFlowActive
            
            DRInfo("[ChallengeDetailView] updateEnrollmentStatusFromProgress: 状态=\(progressResponse.enrollment.status.rawValue), 运动流程活跃=\(isWorkoutFlowActive), 是否自动展开=\(shouldAutoExpand)")
            
            if shouldAutoExpand {
                DRInfo("[ChallengeDetailView] updateEnrollmentStatusFromProgress: 延迟0.5秒后自动展开美食券面板")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    DRInfo("[ChallengeDetailView] updateEnrollmentStatusFromProgress: 执行自动展开美食券面板")
                    self.showProgress = true
                }
            } else if isEnrolled {
                DRInfo("[ChallengeDetailView] updateEnrollmentStatusFromProgress: 跳过自动展开：运动流程正在进行中或状态不符合条件")
            }
        }
    }
    
    // 报名确认弹窗
    private var enrollmentAlert: some View {
        Group {
            Button("取消", role: .cancel) {}
            Button("确认") {
                // 执行报名操作
                enrollAction()
            }
        }
    }
    
    // 弹窗消息
    private var alertMessage: some View {
        Group {
            if let challenge = viewModel.selectedChallenge {
                Text("您确定要报名参加\"\(challenge.name)\"吗？")
            } else {
                Text("您确定要报名参加此挑战吗？")
            }
        }
    }
    
    // 查看礼物状态页面
    private var giftStatusSheet: some View {
        VStack(spacing: 20) {
            Text("礼物邮寄状态")
                .font(.system(size: 20, weight: .bold))
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundColor(Color(hex: "FE2D55"))
                    Text("礼物状态：准备中")
                        .font(.system(size: 16))
                }
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(Color(hex: "FE2D55"))
                    Text("邮寄地址：北京市朝阳区...")
                        .font(.system(size: 16))
                }
                
                Button("修改地址") {
                    // TODO: 实现修改地址功能
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "FE2D55"))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color(hex: "FE2D55").opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
            
            Button("关闭") {
                showGiftStatus = false
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(hex: "FE2D55"))
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.white)
        .presentationDetents([.medium, .large])
    }
    
    // 隐藏TabBar的辅助函数
    private func hideTabBar() {
        appState.hideTabBarForDrag = true
    }
    
    // 显示TabBar的辅助函数
    private func showTabBar() {
        appState.hideTabBarForDrag = false
    }
    
    // 顶部背景图
    private var headerImage: some View {
        Group {
            if let challenge = viewModel.selectedChallenge, let bannerURL = challenge.bannerURL, !bannerURL.isEmpty {
                // 从远程加载背景图
                AsyncImage(url: URL(string: bannerURL)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 180)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 180)
                            .clipped()
                    case .failure:
                        defaultHeaderBackground
                    @unknown default:
                        defaultHeaderBackground
                    }
                }
            } else {
                // 默认背景
                defaultHeaderBackground
            }
        }
        .cornerRadius(0)
    }
    
    // 默认头部背景
    private var defaultHeaderBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(hex: "FE2D55"), Color(hex: "FE2D55").opacity(0.7)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: 180)
        .overlay(
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
        )
    }
    
    // 挑战标题和基本信息
    private var challengeHeader: some View {
        Group {
            if let challenge = viewModel.selectedChallenge {
                // 基本信息卡片
                VStack(alignment: .leading, spacing: 16) {
                    // 标题
                    Text(challenge.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(2)
                    
                    HStack(alignment: .center, spacing: 12) {
                        // 左侧：状态标签
                        HStack(spacing: 4) {
                            // 为已报名状态添加花边对勾icon
                            if isEnrolled && getDisplayStatusText(challenge: challenge) == "已报名" {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                            // 为已完成状态添加奖杯图标
                            else if isEnrolled && getDisplayStatusText(challenge: challenge) == "已完成" {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                            
                            Text(getDisplayStatusText(challenge: challenge))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(getStatusColor(status: getDisplayStatusText(challenge: challenge)))
                        )
                        
                        Spacer()
                        
                        // 右侧：根据状态显示不同信息
                        HStack(spacing: 8) {
                            // 已报名或已完成状态：显示截止时间
                            if isEnrolled && !["已失败", "火热报名中"].contains(getDisplayStatusText(challenge: challenge)) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                
                                Text("截止：\(formatDate(currentEnrollment?.enrollment.deadline ?? challenge.endDate))")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            // 未报名或失败状态：显示价格信息
                            else if !isEnrolled || getDisplayStatusText(challenge: challenge) == "已失败" {
                                Image(systemName: challenge.activityType == .free ? "star.fill" : "dollarsign.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(challenge.activityType == .free ? Color(hex: "4CAF50") : Color(hex: "FF6B6B"))
                                
                                if challenge.activityType == .free {
                                    Text("免费")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gray)
                                } else if let price = challenge.price {
                                    Text("\(price)元")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(hex: "FF6B6B"))
                                } else {
                                    Text("付费")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    
                    // 分割线
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                        .padding(.vertical, 4)
                    
                    // 挑战描述
                    Text(challenge.description)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            } else {
                // 加载中状态
                VStack(spacing: 16) {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("加载中...")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    // 奖励信息部分
    private var rewardSection: some View {
        Group {
            if let challenge = viewModel.selectedChallenge {
                // 奖励信息卡片
                VStack(alignment: .leading, spacing: 16) {
                    Text("挑战奖励")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                    
                    HStack(spacing: 16) {
                        // 奖励图标
                        ZStack {
                            Circle()
                                .fill(Color(hex: "FE2D55").opacity(0.1))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: getRewardIcon(for: challenge.rewardType))
                                .font(.system(size: 24))
                                .foregroundColor(Color(hex: "FE2D55"))
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            // 奖励名称
                            Text(challenge.formattedReward)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                            
                            // 奖励描述
                            Text(challenge.rewardDescription)
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            } else {
                // 加载中状态
                VStack(spacing: 16) {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("加载中...")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    // 挑战要求部分（去掉挑战描述，添加说明文案）
    private var challengeRequirements: some View {
        Group {
            if let challenge = viewModel.selectedChallenge {
                // 挑战要求
                VStack(alignment: .leading, spacing: 16) {
                    Text("挑战要求")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(challenge.requirement)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // 分割线
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                        .padding(.vertical, 8)
                    
                    // 基础要求信息
                    VStack(alignment: .leading, spacing: 12) {
                        // 完成挑战天数限制
                        if let daysLimit = challenge.completionDaysLimit {
                            // 获取格式化的截止日期文本
                            let deadlineText = getFormattedDeadlineText(for: challenge, daysLimit: daysLimit)
                            
                            HStack(alignment: .center, spacing: 12) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "FE2D55"))
                                    .frame(width: 20)
                                
                                Text(deadlineText)
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                                
                                Spacer()
                            }
                        }
                        
                        // 运动次数要求
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "FE2D55"))
                                .frame(width: 20)
                            
                            Text("\(challenge.requiredCheckins)次有效运动打卡")
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                            
                            Spacer()
                        }
                    }
                    
                    // 单次运动要求
                    let hasPerCheckinRequirements = challenge.minDistancePerCheckin != nil || 
                                                  challenge.minDurationPerCheckin != nil || 
                                                  challenge.minEquivalentDessertPerCheckin != nil || 
                                                  challenge.requiredExerciseTypeId != nil && !challenge.requiredExerciseTypeId!.isEmpty ||
                                                  challenge.requiredDifferentExerciseTypes ||
                                                  challenge.foodRestrictionType != "none"
                    
                    if hasPerCheckinRequirements {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("有效运动打卡要求")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.top, 8)
                            
                            // 运动要求卡片
                            VStack(alignment: .leading, spacing: 12) {
                                // 最小距离要求
                                if let minDistance = challenge.minDistancePerCheckin {
                                    HStack(alignment: .center, spacing: 12) {
                                        Image(systemName: "figure.walk")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(hex: "FE2D55"))
                                            .frame(width: 20)
                                        
                                        Text("\(String(format: "%.1f", minDistance))公里")
                                            .font(.system(size: 16))
                                            .foregroundColor(.black)
                                        
                                        Spacer()
                                    }
                                }
                                
                                // 最小时长要求
                                if let minDuration = challenge.minDurationPerCheckin {
                                    HStack(alignment: .center, spacing: 12) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(hex: "FE2D55"))
                                            .frame(width: 20)
                                        
                                        Text("\(minDuration)分钟")
                                            .font(.system(size: 16))
                                            .foregroundColor(.black)
                                        
                                        Spacer()
                                    }
                                }
                                
                                // 最小消耗美食数量
                                if let minDessert = challenge.minEquivalentDessertPerCheckin {
                                    HStack(alignment: .center, spacing: 12) {
                                        Image(systemName: "fork.knife")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(hex: "FE2D55"))
                                            .frame(width: 20)
                                        
                                        Text("运动量 > \(String(format: "%.1f", minDessert))个美食")
                                            .font(.system(size: 16))
                                            .foregroundColor(.black)
                                        
                                        Spacer()
                                    }
                                }
                                
                                // 特定运动类型要求
                                if let exerciseTypeId = challenge.requiredExerciseTypeId, !exerciseTypeId.isEmpty {
                                    HStack(alignment: .center, spacing: 12) {
                                        Image(systemName: "figure.run")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(hex: "FE2D55"))
                                            .frame(width: 20)
                                        
                                        Text("\(challenge.requiredExerciseTypeName ?? "未知")")
                                            .font(.system(size: 16))
                                            .foregroundColor(.black)
                                        
                                        Spacer()
                                    }
                                }
                                
                                // 不同运动类型要求
                                if challenge.requiredDifferentExerciseTypes {
                                    HStack(alignment: .center, spacing: 12) {
                                        Image(systemName: "figure.run")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(hex: "FE2D55"))
                                            .frame(width: 20)
                                        
                                        Text("三种不同运动类型")
                                            .font(.system(size: 16))
                                            .foregroundColor(.black)
                                        
                                        Spacer()
                                    }
                                }
                                
                                // 美食限制
                                if challenge.foodRestrictionType != "none" {
                                    HStack(alignment: .center, spacing: 12) {
                                        Image(systemName: "fork.knife")
                                            .font(.system(size: 16))
                                            .foregroundColor(Color(hex: "FE2D55"))
                                            .frame(width: 20)
                                        
                                        if challenge.foodRestrictionType == "category", let categoryIds = challenge.requiredFoodCategoryIds, !categoryIds.isEmpty {
                                            // 预先计算分类名称字符串
                                            let categoryNames: String = {
                                                if let serverNames = challenge.requiredFoodCategoryNames, !serverNames.isEmpty {
                                                    return serverNames.joined(separator: "、")
                                                } else {
                                                    return "未知分类"
                                                }
                                            }()
                                            
                                            Text("美食种类：\(categoryNames)")
                                                .font(.system(size: 16))
                                                .foregroundColor(.black)
                                        } else if challenge.foodRestrictionType == "specific", let foodIds = challenge.requiredFoodIds, !foodIds.isEmpty {
                                            // 预先计算食物名称字符串
                                            let foodNames: String = {
                                                if let serverNames = challenge.requiredFoodNames, !serverNames.isEmpty {
                                                    return serverNames.joined(separator: "、")
                                                } else {
                                                    return "未知美食"
                                                }
                                            }()
                                            
                                            Text("美食种类：\(foodNames)")
                                                .font(.system(size: 16))
                                                .foregroundColor(.black)
                                        } else if challenge.requiredDifferentFoodTypes {
                                            Text("三种不同美食")
                                                .font(.system(size: 16))
                                                .foregroundColor(.black)
                                        } else {
                                            Text("特定美食")
                                                .font(.system(size: 16))
                                                .foregroundColor(.black)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color(UIColor.systemGray6).opacity(0.5))
                            .cornerRadius(12)
                        }
                    }
                    
                    // 活动说明文案
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 1)
                        .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "FE2D55"))
                                .frame(width: 20)
                            
                            Text("什么是有效运动打卡")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Spacer()
                        }
                        
                        Text("报名活动后，您会收到\(challenge.requiredCheckins)张任务卡，按照任务卡上的要求完成运动，即视为一次有效运动打卡；如打卡成功，任务卡会变为精美的美食券")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                            .padding(.leading, 32)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(Color(hex: "FE2D55").opacity(0.05))
                    .cornerRadius(12)
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            } else {
                // 加载中状态
                VStack(spacing: 16) {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("加载中...")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    // 底部操作按钮
    private var actionButton: some View {
        VStack {
            if let challenge = viewModel.selectedChallenge {
                if isEnrolled {
                    // 已报名 - 根据状态显示不同按钮
                    enrolledActionButtons
                } else if challenge.isInProgress {
                    // 未报名且活动进行中 - 显示报名按钮
                    Button(action: {
                        showingEnrollmentForm = true
                    }) {
                        Text(challenge.activityType == .free ? "免费报名" : "付费报名")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color(hex: "FE2D55"))
                            )
                    }
                    .sheet(isPresented: $showingEnrollmentForm) {
                        ChallengeEnrollmentFormView(challenge: challenge)
                    }
                } else if challenge.statusText == "即将开始" {
                    // 活动未开始 - 显示不可报名状态
                    Text("挑战未开始")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.gray)
                        )
                } else {
                    // 活动已结束 - 显示不可报名状态
                    Text("挑战已结束")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.gray)
                        )
                }
            } else {
                // 加载中状态
                ProgressView()
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.gray.opacity(0.2))
                    )
            }
        }
    }
    
    // 已报名状态的按钮组合
    @ViewBuilder
    private var enrolledActionButtons: some View {
        // 优先使用从progress API获取到的状态，如果没有则回退到enrolledChallenges中的状态
        let statusString: String = {
            if let progressResponse = viewModel.progressResponse {
                return progressResponse.enrollment.status.rawValue
            } else if let enrollment = currentEnrollment {
                switch enrollment.enrollment.enrollmentStatus {
                case .ongoing:
                    return "ongoing"
                case .completed:
                    return "completed"
                case .failed:
                    return "failed"
                }
            } else {
                return "ongoing" // 默认状态
            }
        }()
        
        switch statusString {
        case "ongoing":
            // 进行中 - 显示"去运动"按钮
            Button(action: {
                showProgress = true
            }) {
                Text("去运动")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(hex: "FE2D55"))
                    )
            }
            
        case "completed":
            // 已完成 - 显示"查看美食券"和"查看礼物"两个按钮
            HStack(spacing: 12) {
                Button(action: {
                    showProgress = true
                }) {
                    Text("查看美食券")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(hex: "FE2D55"))
                        )
                }
                
                Button(action: {
                    showGiftStatus = true
                }) {
                    Text("查看礼物")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "FE2D55"))
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color(hex: "FE2D55"), lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                }
            }
            
        case "failed":
            // 已失败 - 只显示"查看美食券"按钮
            Button(action: {
                showProgress = true
            }) {
                Text("查看美食券")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(hex: "FE2D55"))
                    )
            }
            
        default:
            // 默认情况：显示"去运动"按钮
            Button(action: {
                showProgress = true
            }) {
                Text("去运动")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(hex: "FE2D55"))
                    )
            }
        }
    }
    
    // 根据状态文本获取颜色
    private func getStatusColor(status: String) -> Color {
        switch status {
        case "未上线":
            return Color.gray
        case "即将开始":
            return Color.blue
        case "进行中", "火热报名中":
            return Color(hex: "FE2D55") // 粉色，与未报名时的挑战进度图标统一
        case "已报名":
            return Color(hex: "4CAF50") // 绿色
        case "已完成":
            return Color(hex: "FF9500") // 橙色，更清楚可见
        case "已失败":
            return Color(hex: "FF6B6B") // 红色
        case "已结束":
            return Color.gray
        default:
            return Color.gray
        }
    }
    
    // 根据奖励类型获取图标名称
    private func getRewardIcon(for rewardType: RewardType) -> String {
        switch rewardType {
        case .dessertBox:
            return "gift.fill"
        case .coupon:
            return "ticket.fill"
        case .badge:
            return "medal.fill"
        case .stars:
            return "star.fill"
        }
    }
    
    // 获取格式化的截止日期文本
    private func getFormattedDeadlineText(for challenge: ChallengeActivity, daysLimit: Int?) -> String {
        guard let daysLimit = daysLimit else { return "" }
        
        if daysLimit == 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月dd日"
            return "期限：\(formatter.string(from: challenge.endDate))"
        } else {
            return "期限：\(daysLimit)天内"
        }
    }
    
    // 日期格式化辅助方法
    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
    
    // 根据挑战状态获取显示状态文本
    private func getDisplayStatusText(challenge: ChallengeActivity) -> String {
        // 如果已报名，显示报名状态
        if isEnrolled {
            // 优先使用progressResponse中的状态
            if let progressResponse = viewModel.progressResponse {
                switch progressResponse.enrollment.status.rawValue {
                case "ongoing":
                    return "已报名"
                case "completed":
                    return "已完成"
                case "failed":
                    return "已失败"
                default:
                    return "已报名"
                }
            }
            // 如果没有progressResponse，使用enrolledChallenges中的状态
            else if let enrollment = currentEnrollment {
                switch enrollment.enrollment.enrollmentStatus {
                case .ongoing:
                    return "已报名"
                case .completed:
                    return "已完成"
                case .failed:
                    return "已失败"
                }
            }
            else {
                return "已报名"
            }
        }
        // 如果未报名，根据挑战活动状态显示
        else {
            switch challenge.statusText {
            case "未上线":
                return "未上线"
            case "即将开始":
                return "即将开始"
            case "进行中":
                return "火热报名中"
            case "已结束":
                return "已结束"
            default:
                return challenge.statusText
            }
        }
    }
    
    // 报名按钮点击事件
    private func enrollAction() {
        viewModel.enrollChallenge(id: challengeId) { success in
            if success {
                // 报名成功后触发彩带动画
                showConfetti = true
                confettiCounter += 1
                // 可选：自动滚动到进度区或弹窗提示
            }
        }
    }
    
    // 格式化日期显示
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - 自定义返回按钮

extension ChallengeDetailView {
    private var backButton: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
                .padding(12)
                .background(Color.white.opacity(0.2))
                .clipShape(Circle())
        }
        .padding(.leading, 16)
        .padding(.top, (UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?.safeAreaInsets.top ?? 0) + 8)
        .zIndex(100)
    }
}

#Preview {
    NavigationView {
        ChallengeDetailView(challengeId: "1", viewModel: ChallengeViewModel(appState: AppState.shared))
            .environmentObject(AppState.shared)
    }
} 