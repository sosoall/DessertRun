import SwiftUI

/// 挑战详情页面
struct ChallengeDetailView: View {
    // 环境对象
    @EnvironmentObject var appState: AppState
    
    // 视图模型
    @StateObject private var viewModel: ChallengeViewModel
    
    // 视图状态
    @State private var showingEnrollConfirmation = false
    @State private var isEnrolled = false
    @State private var showProgress = false
    @State private var progress: ChallengeProgressResponse?
    
    // 挑战ID
    let challengeId: String
    
    // 初始化
    init(challengeId: String) {
        self.challengeId = challengeId
        self._viewModel = StateObject(wrappedValue: ChallengeViewModel(appState: AppState.shared))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 顶部背景图
                    headerImage
                    
                    // 挑战内容区域
                    VStack(spacing: 16) {
                        // 挑战标题和基本信息
                        challengeHeader
                        
                        // 挑战要求和详细信息
                        challengeDetails
                        
                        // 奖励信息
                        rewardSection
                    }
                    .padding(.horizontal, 20)
                    
                    // 底部间距
                    Spacer(minLength: 80)
                }
                .padding(.bottom, 16)
            }
            
            // 报名按钮
            actionButton
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .background(Color(UIColor.systemGray6))
        .onAppear {
            // 加载挑战详情
            viewModel.loadChallengeDetail(id: challengeId)
            // 检查是否已报名
            viewModel.loadEnrollments()
            
            // 如果已报名，获取进度信息
            if let enrollment = viewModel.getEnrollment(for: challengeId) {
                isEnrolled = true
                viewModel.loadProgress(enrollmentId: enrollment.id)
            }
        }
        .onChange(of: viewModel.enrolledChallenges) { _, newValue in
            // 更新报名状态
            isEnrolled = newValue.contains { $0.challenge.id == challengeId }
            
            // 如果已报名，获取进度信息
            if isEnrolled, let enrollment = viewModel.getEnrollment(for: challengeId) {
                viewModel.loadProgress(enrollmentId: enrollment.id)
            }
        }
        .alert("确认报名", isPresented: $showingEnrollConfirmation) {
            Button("取消", role: .cancel) {}
            Button("确认") {
                // 执行报名操作
                viewModel.enrollChallenge(id: challengeId) { success in
                    if success {
                        isEnrolled = true
                    }
                }
            }
        } message: {
            if let challenge = viewModel.selectedChallenge {
                Text("您确定要报名参加\"\(challenge.name)\"吗？")
            } else {
                Text("您确定要报名参加此挑战吗？")
            }
        }
        .sheet(isPresented: $showProgress) {
            if let progress = viewModel.progressResponse {
                // 显示挑战进度详情
                VStack(spacing: 16) {
                    // 标题
                    Text("挑战进度")
                        .font(.system(size: 20, weight: .semibold))
                        .padding(.top, 20)
                    
                    // 进度卡片
                    VStack(spacing: 12) {
                        // 进度条
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("完成进度")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                                
                                Spacer()
                                
                                Text("\(Int(progress.completionPercent))%")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            ProgressView(value: progress.completionPercent / 100)
                                .accentColor(Color(hex: "FE2D55"))
                                .frame(height: 8)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 16)
                        
                        Divider()
                        
                        // 进度信息
                        HStack(spacing: 16) {
                            // 打卡进度
                            VStack(spacing: 4) {
                                Text("已完成")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                
                                Text("\(progress.enrollment.completedCheckins)/\(progress.challenge.requiredCheckins)")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(Color(hex: "FE2D55"))
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                                .frame(height: 30)
                            
                            // 剩余天数
                            VStack(spacing: 4) {
                                Text("剩余天数")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                
                                Text("\(progress.remainingDays)天")
                                    .font(.system(size: 20, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        
                        Divider()
                        
                        // 截止日期
                        HStack {
                            Text("截止日期")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            // 使用已格式化的日期字符串
                            Text(formattedDate(date: progress.enrollment.deadline))
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // 关闭按钮
                    Button("关闭") {
                        showProgress = false
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
                .background(Color(UIColor.systemGray6))
                .presentationDetents([.medium])
            }
        }
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
                VStack(alignment: .leading, spacing: 12) {
                    // 标题
                    Text(challenge.name)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                    
                    HStack {
                        // 活动类型
                        HStack(spacing: 8) {
                            Image(systemName: challenge.activityType == .free ? "star" : "dollarsign.circle")
                                .font(.system(size: 16))
                                .foregroundColor(challenge.activityType == .free ? Color(hex: "4CAF50") : Color(hex: "FF6B6B"))
                            
                            if challenge.activityType == .free {
                                Text("免费")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            } else if let price = challenge.price {
                                Text("\(price)元")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color(hex: "FF6B6B"))
                            } else {
                                Text("付费")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        // 状态标签
                        Text(challenge.statusText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(getStatusColor(status: challenge.statusText))
                            )
                    }
                    
                    Divider()
                    
                    // 活动时间
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "FE2D55"))
                        
                        Text(challenge.formattedDuration)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            } else {
                // 加载中状态
                VStack {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    
                    Text("加载中...")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    // 挑战详情部分
    private var challengeDetails: some View {
        Group {
            if let challenge = viewModel.selectedChallenge {
                // 挑战描述
                VStack(alignment: .leading, spacing: 12) {
                    Text("挑战描述")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(challenge.description)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .lineSpacing(5)
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                // 挑战要求
                VStack(alignment: .leading, spacing: 12) {
                    Text("挑战要求")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(challenge.requirement)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .lineSpacing(5)
                    
                    Divider()
                        .padding(.vertical, 6)
                    
                    // 完成挑战天数限制
                    if let daysLimit = challenge.completionDaysLimit {
                        // 获取格式化的截止日期文本
                        let deadlineText = getFormattedDeadlineText(for: challenge, daysLimit: daysLimit)
                        
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(Color(hex: "FE2D55"))
                            
                            // 使用准备好的文本内容
                            Text(deadlineText)
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // 打卡次数要求
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color(hex: "FE2D55"))
                        
                        Text("打卡次数：\(challenge.requiredCheckins)次")
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                    }
                    .padding(.vertical, 4)
                    
                    // 单次打卡要求
                    let hasPerCheckinRequirements = challenge.minDistancePerCheckin != nil || 
                                                  challenge.minDurationPerCheckin != nil || 
                                                  challenge.minEquivalentDessertPerCheckin != nil || 
                                                  challenge.requiredExerciseTypeId != nil && !challenge.requiredExerciseTypeId!.isEmpty ||
                                                  challenge.requiredDifferentExerciseTypes ||
                                                  challenge.foodRestrictionType != "none"
                    
                    if hasPerCheckinRequirements {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("单次打卡要求")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.top, 8)
                            
                            // 打卡要求卡片
                            VStack(alignment: .leading, spacing: 10) {
                                // 最小距离要求
                                if let minDistance = challenge.minDistancePerCheckin {
                                    HStack(spacing: 10) {
                                        Image(systemName: "figure.walk")
                                            .foregroundColor(Color(hex: "FE2D55"))
                                            .frame(width: 24)
                                        
                                        Text("运动量：\(String(format: "%.1f", minDistance))公里")
                                            .font(.system(size: 16))
                                            .foregroundColor(.black)
                                    }
                                }
                                
                                // 最小时长要求
                                if let minDuration = challenge.minDurationPerCheckin {
                                    HStack(spacing: 10) {
                                        Image(systemName: "clock")
                                            .foregroundColor(Color(hex: "FE2D55"))
                                            .frame(width: 24)
                                        
                                        Text("运动时长：\(minDuration)分钟")
                                            .font(.system(size: 16))
                                            .foregroundColor(.black)
                                    }
                                }
                                
                                // 最小消耗美食数量
                                if let minDessert = challenge.minEquivalentDessertPerCheckin {
                                    HStack(spacing: 10) {
                                        Image(systemName: "fork.knife")
                                            .foregroundColor(Color(hex: "FE2D55"))
                                            .frame(width: 24)
                                        
                                        Text("消耗美食：\(String(format: "%.1f", minDessert))个")
                                            .font(.system(size: 16))
                                            .foregroundColor(.black)
                                    }
                                }
                                
                                // 特定运动类型要求
                                if let exerciseTypeId = challenge.requiredExerciseTypeId, !exerciseTypeId.isEmpty {
                                    HStack(spacing: 10) {
                                        Image(systemName: "figure.run")
                                            .foregroundColor(Color(hex: "FE2D55"))
                                            .frame(width: 24)
                                        
                                        Text("运动类型：\(challenge.requiredExerciseTypeName ?? "未知")")
                                            .font(.system(size: 16))
                                            .foregroundColor(.black)
                                    }
                                }
                                
                                // 不同运动类型要求
                                if challenge.requiredDifferentExerciseTypes {
                                    HStack(spacing: 10) {
                                        Image(systemName: "figure.run")
                                            .foregroundColor(Color(hex: "FE2D55"))
                                            .frame(width: 24)
                                        
                                        Text("要求：三种不同运动类型")
                                            .font(.system(size: 16))
                                            .foregroundColor(.black)
                                    }
                                }
                                
                                // 美食限制
                                if challenge.foodRestrictionType != "none" {
                                    HStack(spacing: 10) {
                                        Image(systemName: "fork.knife")
                                            .foregroundColor(Color(hex: "FE2D55"))
                                            .frame(width: 24)
                                        
                                        if challenge.foodRestrictionType == "category", let categoryIds = challenge.requiredFoodCategoryIds, !categoryIds.isEmpty {
                                            // 预先计算分类名称字符串
                                            let categoryNames: String = {
                                                if let serverNames = challenge.requiredFoodCategoryNames, !serverNames.isEmpty {
                                                    return serverNames.joined(separator: "、")
                                                } else {
                                                    return "未知分类"
                                                }
                                            }()
                                            
                                            Text("美食分类：\(categoryNames)")
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
                                            Text("要求：三种不同美食")
                                                .font(.system(size: 16))
                                                .foregroundColor(.black)
                                        } else {
                                            Text("特定美食要求")
                                                .font(.system(size: 16))
                                                .foregroundColor(.black)
                                        }
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color(UIColor.systemGray6).opacity(0.5))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            } else {
                // 加载中状态
                VStack {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    
                    Text("加载中...")
                        .font(.system(size: 14))
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
                VStack(alignment: .leading, spacing: 12) {
                    Text("挑战奖励")
                        .font(.system(size: 18, weight: .semibold))
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
                                .lineSpacing(5)
                        }
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            } else {
                // 加载中状态
                VStack {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                    
                    Text("加载中...")
                        .font(.system(size: 14))
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
                    // 已报名 - 显示查看进度按钮
                    Button(action: {
                        showProgress = true
                    }) {
                        Text("查看进度")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color(hex: "FE2D55"))
                            )
                    }
                } else if challenge.isInProgress {
                    // 未报名且活动进行中 - 显示报名按钮
                    Button(action: {
                        showingEnrollConfirmation = true
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
        .background(Color.white)
        .cornerRadius(25)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // 根据状态文本获取颜色
    private func getStatusColor(status: String) -> Color {
        switch status {
        case "未上线":
            return Color.gray
        case "即将开始":
            return Color.blue
        case "进行中":
            return Color(hex: "4CAF50") // 绿色
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
            return "完成期限：\(formatter.string(from: challenge.endDate))"
        } else {
            return "完成期限：\(daysLimit)天内"
        }
    }
    
    // 日期格式化辅助方法
    private func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        ChallengeDetailView(challengeId: "1")
            .environmentObject(AppState.shared)
    }
} 