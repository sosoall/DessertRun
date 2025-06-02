import SwiftUI

/// 已报名挑战列表视图
struct EnrolledChallengeView: View {
    // 环境对象
    @EnvironmentObject var appState: AppState
    
    // 视图模型 - 接受外部传入的共享实例
    @ObservedObject var viewModel: ChallengeViewModel
    
    // 状态
    @Environment(\.presentationMode) var presentationMode
    
    // 添加状态筛选
    @State private var selectedStatus: EnrollmentStatus = .ongoing
    
    // 初始化 - 接受共享的viewModel
    init(viewModel: ChallengeViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            // 背景渐变，更有活力
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "FFF8E1"), 
                    Color(hex: "F5F5F5")
                ]), 
                startPoint: .topLeading, 
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                greetingHeader
                
                // 常规展示，总是显示筛选器（合并了统计）
                VStack(spacing: 0) {
                    combinedFilterAndStats
                    
                    // 根据挑战数量决定展示方式
                    if viewModel.enrolledChallenges.isEmpty {
                        if viewModel.isLoading {
                            loadingView
                        } else {
                            emptyStateView
                        }
                    } else {
                        if filteredEnrollments.count == 1 && selectedStatus == .ongoing {
                            // 单个进行中挑战的特殊展示
                            singleChallengeView
                        } else {
                            // 多个挑战的常规展示
                            challengeContent
                        }
                    }
                }
            }

            // 加载中指示器
            if viewModel.isLoading && !viewModel.enrolledChallenges.isEmpty {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }

            // 错误提示
            if let errorMessage = viewModel.errorMessage {
                ErrorOverlay(message: errorMessage) {
                    viewModel.loadDetailedEnrollments()
                }
            }
        }
        .onAppear {
            viewModel.loadDetailedEnrollments()
        }
    }
    
    // MARK: - View Builders
    
    // 鼓舞性问候语头部
    @ViewBuilder
    private var greetingHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(getGreetingText())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // 动力图标
                Image(systemName: "flame.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
                    .modifier(BreathingModifier())
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // 今日进度卡片
            todayProgressCard
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    // 今日进度卡片
    @ViewBuilder
    private var todayProgressCard: some View {
        HStack(spacing: 16) {
            // 今日打卡状态图标 - 使用更合适的图标
            ZStack {
                Circle()
                    .fill(hasTodayWorkout() ? Color.green.opacity(0.2) : Color.orange.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                if hasTodayWorkout() {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "bolt.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(hasTodayWorkout() ? "今日已消灭热量！" : "该吃吃，该喝喝，热量别往肚里搁")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "FFE082").opacity(0.5), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // 合并的筛选器和统计
    @ViewBuilder
    private var combinedFilterAndStats: some View {
        HStack(spacing: 12) {
            // 筛选按钮，内含统计数据 - 单行布局，统一颜色方案
            FilterButtonWithStats(
                title: "进行中 \(ongoingCount)",
                icon: "flame.fill",
                color: .green,
                isSelected: selectedStatus == .ongoing,
                action: { selectedStatus = .ongoing }
            )
            .frame(maxWidth: .infinity)
            
            FilterButtonWithStats(
                title: "已完成 \(completedCount)",
                icon: "crown.fill",
                color: .orange,
                isSelected: selectedStatus == .completed,
                action: { selectedStatus = .completed }
            )
            .frame(maxWidth: .infinity)
            
            FilterButtonWithStats(
                title: "已失败 \(failedCount)",
                icon: "xmark.circle",
                color: .gray,
                isSelected: selectedStatus == .failed,
                action: { selectedStatus = .failed }
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // 单个挑战的特殊展示
    @ViewBuilder
    private var singleChallengeView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 当前挑战大卡片 - 修复导航问题
                if let enrollment = filteredEnrollments.first {
                    NavigationLink(destination: ChallengeDetailView(challengeId: enrollment.challenge.id, viewModel: viewModel)) {
                        FeaturedChallengeCard(enrollment: enrollment, viewModel: viewModel)
                            .padding(.horizontal, 20)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // 快速操作按钮
                quickActionButtons
                
                Spacer(minLength: 100)
            }
            .padding(.top, 20)
        }
    }
    
    // 快速操作按钮
    @ViewBuilder
    private var quickActionButtons: some View {
        VStack(spacing: 12) {
            // 主要行动按钮 - 去运动，使用NavigationLink实现真正的跳转
            if let enrollment = filteredEnrollments.first {
                NavigationLink(destination: ChallengeDetailView(challengeId: enrollment.challenge.id, viewModel: viewModel)) {
                    HStack {
                        Image(systemName: "figure.run")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("开始今天的运动")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.DessertRun.accent, Color.orange]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: Color.DessertRun.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var challengeContent: some View {
        if filteredEnrollments.isEmpty {
            // 筛选后的空状态
            VStack(spacing: 16) {
                Image(systemName: getEmptyStateIcon())
                    .font(.system(size: 50))
                    .foregroundColor(Color.DessertRun.accent.opacity(0.6))

                Text("暂无\(getStatusText(selectedStatus))的挑战")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(getEmptyStateMessage())
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)

                if selectedStatus == .ongoing {
                    // 进行中挑战为空时，显示去挑战中心的按钮
                    Button(action: {
                        // 通过通知切换到挑战中心 Tab
                        NotificationCenter.default.post(name: NSNotification.Name("SwitchToChallengeCenter"), object: nil)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            
                            Text("去挑战中心")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.DessertRun.accent, Color.orange]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: Color.DessertRun.accent.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                } else if selectedStatus != .ongoing {
                    Button("查看进行中的挑战") {
                        selectedStatus = .ongoing
                    }
                    .foregroundColor(Color.DessertRun.accent)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.DessertRun.accent, lineWidth: 1)
                    )
                }
            }
            .padding(.top, 60)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredEnrollments, id: \.enrollment.id) { enrollment in
                        NavigationLink(destination: ChallengeDetailView(challengeId: enrollment.challenge.id, viewModel: viewModel)) {
                            EnhancedEnrollmentCard(enrollment: enrollment, viewModel: viewModel)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // 动画图标
            ZStack {
                Circle()
                    .fill(Color.DessertRun.accent.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "trophy.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Color.DessertRun.accent)
                    .modifier(BreathingModifier())
            }
            
            VStack(spacing: 8) {
                Text("开启你的甜品运动之旅！")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("参与挑战，解锁美味奖励")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            
            // 吸引人的行动按钮
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    
                    Text("立即报名挑战")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.DessertRun.accent, Color.orange]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: Color.DessertRun.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            Spacer()
        }
        .padding(.top, 80)
        .padding(.horizontal, 32)
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("正在加载你的挑战...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Private Methods
    
    // 根据选择的状态筛选挑战
    private var filteredEnrollments: [EnrollmentWithChallengeDetail] {
        return viewModel.enrolledChallenges.filter { enrollment in
            enrollment.enrollment.enrollmentStatus == selectedStatus
        }
    }
    
    // 统计数据
    private var completedCount: Int {
        viewModel.enrolledChallenges.filter { $0.enrollment.enrollmentStatus == .completed }.count
    }
    
    private var ongoingCount: Int {
        viewModel.enrolledChallenges.filter { $0.enrollment.enrollmentStatus == .ongoing }.count
    }
    
    private var failedCount: Int {
        viewModel.enrolledChallenges.filter { $0.enrollment.enrollmentStatus == .failed }.count
    }
    
    // 检查今天是否有运动打卡
    private func hasTodayWorkout() -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 检查今天是否有任何挑战的打卡记录
        // TODO: 这里需要根据实际的运动记录API来实现
        // 目前简单地检查是否有进行中的挑战且完成次数大于0
        return viewModel.enrolledChallenges.contains { enrollment in
            enrollment.enrollment.enrollmentStatus == .ongoing && 
            enrollment.enrollment.completedCheckins > 0
        }
    }
    
    // 获取问候语
    private func getGreetingText() -> String {
        return "我的挑战"
    }
    
    // 获取空状态图标
    private func getEmptyStateIcon() -> String {
        switch selectedStatus {
        case .ongoing:
            return "timer"
        case .completed:
            return "checkmark.circle"
        case .failed:
            return "xmark.circle"
        }
    }
    
    // 获取空状态消息
    private func getEmptyStateMessage() -> String {
        switch selectedStatus {
        case .ongoing:
            return "还没有正在进行的挑战\n快去报名一个开始运动吧！"
        case .completed:
            return "还没有完成的挑战\n努力完成当前挑战获得奖励！"
        case .failed:
            return "太棒了！没有失败的挑战\n保持这个状态继续加油！"
        }
    }
    
    // 获取状态文本
    private func getStatusText(_ status: EnrollmentStatus) -> String {
        switch status {
        case .ongoing:
            return "进行中"
        case .completed:
            return "已完成"
        case .failed:
            return "已失败"
        }
    }
}

// MARK: - Supporting Views

/// 带统计数据的筛选按钮 - 重新设计为胶囊形状
struct FilterButtonWithStats: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(isSelected ? color : Color.gray)
                    
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? .primary : Color.gray)
                        .lineLimit(1)
                        .fixedSize()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                
                // 下划线指示器
                Rectangle()
                    .fill(isSelected ? color : Color.clear)
                    .frame(height: 2)
                    .frame(width: isSelected ? nil : 0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// 统计项目视图
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// 特色挑战卡片（单个挑战时使用）
struct FeaturedChallengeCard: View {
    let enrollment: EnrollmentWithChallengeDetail
    let viewModel: ChallengeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 挑战标题和状态
            HStack {
                Text(enrollment.challenge.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Spacer()
                
                // 状态标签
                Text("进行中")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.green)
                    )
            }
            
            // 大进度圆环
            HStack {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: getProgress())
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: getProgress())
                    
                    VStack(spacing: 2) {
                        Text("\(Int(getProgress() * 100))%")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("完成")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        
                        Text("剩余\(getRemainingDays())天")
                            .font(.system(size: 14, weight: .medium))
                    }
                    
                    HStack {
                        Image(systemName: "gift.fill")
                            .foregroundColor(.orange)
                        
                        Text(enrollment.challenge.formattedReward)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.green.opacity(0.3), Color.green.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    private func getProgress() -> Double {
        let completed = Double(enrollment.enrollment.completedCheckins)
        let required = Double(enrollment.challenge.requiredCheckins)
        return required > 0 ? min(completed / required, 1.0) : 0.0
    }
    
    private func getRemainingDays() -> Int {
        let endDate = enrollment.challenge.endDate
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: now, to: endDate)
        return max(components.day ?? 0, 0)
    }
}

/// 增强版报名挑战卡片
struct EnhancedEnrollmentCard: View {
    let enrollment: EnrollmentWithChallengeDetail
    let viewModel: ChallengeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 挑战标题和状态
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(enrollment.challenge.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // 进行中的挑战不显示描述，已完成的也不显示
                }
                
                Spacer()
                
                // 状态标签
                Text(getStatusText(enrollment.enrollment.enrollmentStatus))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(getStatusColor(enrollment.enrollment.enrollmentStatus))
                    )
            }
            
            // 根据状态显示不同内容
            if enrollment.enrollment.enrollmentStatus == .ongoing {
                ongoingChallengeContent
            } else if enrollment.enrollment.enrollmentStatus == .completed {
                completedChallengeContent
            } else {
                failedChallengeContent
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(getCardBorderColor(), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4)
    }
    
    // 进行中挑战的内容
    @ViewBuilder
    private var ongoingChallengeContent: some View {
        // 进度圆环 + 信息
        HStack(spacing: 16) {
            // 进度圆环
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: getProgress())
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: getProgress())
                
                Text("\(Int(getProgress() * 100))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                    
                    Text("剩余\(getRemainingDays())天")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                    
                    Text(enrollment.challenge.formattedReward)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        
        // 运动按钮
        NavigationLink(destination: ChallengeDetailView(challengeId: enrollment.challenge.id, viewModel: viewModel)) {
            HStack {
                Image(systemName: "figure.run")
                    .font(.system(size: 14))
                
                Text("去运动打卡")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(.green)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.green.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 已完成挑战的内容
    @ViewBuilder
    private var completedChallengeContent: some View {
        ZStack(alignment: .bottomTrailing) {
            // 主内容：Voucher 图片水平列表
            if !enrollment.voucherList.vouchers.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(enrollment.voucherList.vouchers, id: \.id) { (voucher: ChallengeVoucherDetail) in
                            VStack(spacing: 4) {
                                let imgURL = voucher.voucherImageURL
                                AsyncImage(url: URL(string: imgURL)) { image in
                                    image.resizable()
                                         .scaledToFit()
                                         .frame(height: 50)
                                         .cornerRadius(8)
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.orange.opacity(0.2))
                                        .frame(height: 50)
                                }
                                
                                Text(voucher.dessertName)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            // 右下角完成日期标识
            if let completionDate = enrollment.enrollment.completionDate {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("完成于：\(formatDate(completionDate))")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .padding(4)
            }
        }
    }
    
    // 失败挑战的内容
    @ViewBuilder
    private var failedChallengeContent: some View {
        HStack {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.gray)
            
            Text("挑战未完成")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // 计算剩余天数
    private func getRemainingDays() -> Int {
        let endDate = enrollment.challenge.endDate
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: now, to: endDate)
        return max(components.day ?? 0, 0)
    }
    
    // 获取进度百分比
    private func getProgress() -> Double {
        let completed = Double(enrollment.enrollment.completedCheckins)
        let required = Double(enrollment.challenge.requiredCheckins)
        return required > 0 ? min(completed / required, 1.0) : 0.0
    }
    
    // 获取卡片边框颜色
    private func getCardBorderColor() -> Color {
        switch enrollment.enrollment.enrollmentStatus {
        case .ongoing:
            return Color.green.opacity(0.3)
        case .completed:
            return Color.orange.opacity(0.3)
        case .failed:
            return Color.gray.opacity(0.3)
        }
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: date)
    }
    
    // 获取状态文本 - EnrollmentCard内部的独立函数
    private func getStatusText(_ status: EnrollmentStatus) -> String {
        switch status {
        case .ongoing:
            return "进行中"
        case .completed:
            return "已完成"
        case .failed:
            return "已失败"
        }
    }
    
    // 获取状态颜色
    private func getStatusColor(_ status: EnrollmentStatus) -> Color {
        switch status {
        case .ongoing:
            return Color.green
        case .completed:
            return Color.orange
        case .failed:
            return Color.gray
        }
    }
}

// 新增错误覆盖视图
struct ErrorOverlay: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack {
            Text("出错了")
                .font(.headline)
                .padding(.bottom, 4)

            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)

            Button("重试") {
                retryAction()
            }
            .padding(.top, 12)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.DessertRun.accent)
            .foregroundColor(.white)
            .cornerRadius(20)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.1))
    }
}

#Preview {
    EnrolledChallengeView(viewModel: ChallengeViewModel(appState: AppState.shared))
        .environmentObject(AppState.shared)
}

// MARK: - Custom Animation Modifiers

/// 自定义呼吸动画修饰符，兼容iOS低版本，避免初始跳动
struct BreathingModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .opacity(isAnimating ? 0.8 : 1.0)
            .onAppear {
                // 延迟启动动画，避免初始跳动
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true)
                    ) {
                        isAnimating = true
                    }
                }
            }
    }
} 
