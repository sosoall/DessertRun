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
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 顶部背景图
                headerImage
                
                // 挑战标题和基本信息
                challengeHeader
                
                // 活动要求和详细信息
                challengeDetails
                
                // 奖励信息
                rewardSection
                
                // 报名按钮
                actionButton
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .background(Color(hex: "F5F5F5"))
        .onAppear {
            // 加载挑战详情
            viewModel.loadChallengeDetail(id: challengeId)
            // 检查是否已报名
            viewModel.loadEnrollments()
            
            // 如果已报名，获取进度信息
            if let enrollment = viewModel.getEnrollment(for: challengeId) {
                isEnrolled = true
                viewModel.loadProgress(id: challengeId)
            }
        }
        .onChange(of: viewModel.enrolledChallenges) { _, newValue in
            // 更新报名状态
            isEnrolled = newValue.contains { $0.challenge.id == challengeId }
            
            // 如果已报名，获取进度信息
            if isEnrolled {
                viewModel.loadProgress(id: challengeId)
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
                VStack {
                    Text("挑战进度")
                        .font(.headline)
                        .padding()
                    
                    // 进度条
                    ProgressView(value: progress.completionPercent)
                        .accentColor(Color.DessertRun.accent)
                        .padding(.horizontal)
                    
                    // 进度信息
                    HStack {
                        Text("已完成")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("\(progress.enrollment.completedCheckins)/\(progress.challenge.requiredCheckins)")
                            .font(.subheadline)
                            .bold()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // 剩余天数
                    HStack {
                        Text("剩余天数")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("\(progress.remainingDays)天")
                            .font(.subheadline)
                            .bold()
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    Spacer()
                    
                    // 关闭按钮
                    Button("关闭") {
                        showProgress = false
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.DessertRun.accent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding()
                }
                .frame(height: 300)
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
                            .frame(height: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
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
    }
    
    // 默认头部背景
    private var defaultHeaderBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.DessertRun.accent, Color.DessertRun.accent.opacity(0.7)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .frame(height: 200)
        .overlay(
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
        )
    }
    
    // 挑战标题和基本信息
    private var challengeHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let challenge = viewModel.selectedChallenge {
                // 标题
                Text(challenge.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
                
                // 基本信息卡片
                HStack(spacing: 12) {
                    // 活动类型
                    VStack {
                        Image(systemName: challenge.activityType == .free ? "star" : "dollarsign.circle")
                            .font(.system(size: 24))
                            .foregroundColor(challenge.activityType == .free ? Color(hex: "4CAF50") : Color(hex: "FF6B6B"))
                        
                        Text(challenge.activityType == .free ? "免费" : "付费")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 60)
                    
                    Divider()
                        .frame(height: 40)
                    
                    // 活动时间
                    VStack(alignment: .leading) {
                        Text("活动时间")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        Text(challenge.formattedDuration)
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    // 状态标签
                    Text(challenge.statusText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(getStatusColor(status: challenge.statusText))
                        )
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4)
            } else {
                // 加载中状态
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding(16)
        .background(Color.white)
        .offset(y: -30)
        .zIndex(1)
    }
    
    // 挑战详情部分
    private var challengeDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let challenge = viewModel.selectedChallenge {
                // 活动描述
                VStack(alignment: .leading, spacing: 8) {
                    Text("活动描述")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(challenge.description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineSpacing(4)
                }
                
                Divider()
                
                // 活动要求
                VStack(alignment: .leading, spacing: 8) {
                    Text("活动要求")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(challenge.requirement)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineSpacing(4)
                    
                    // 打卡次数要求
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.DessertRun.accent)
                        
                        Text("需完成 \(challenge.requiredCheckins) 次打卡")
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                    }
                    .padding(.top, 4)
                    
                    // 特定要求
                    if let exerciseTypeId = challenge.requiredExerciseTypeId, !exerciseTypeId.isEmpty {
                        HStack {
                            Image(systemName: "figure.run")
                                .foregroundColor(Color.DessertRun.accent)
                            
                            Text("指定运动类型要求")
                                .font(.system(size: 14))
                                .foregroundColor(.black)
                        }
                        .padding(.top, 2)
                    }
                    
                    if challenge.foodRestrictionType != "none" {
                        HStack {
                            Image(systemName: "birthday.cake")
                                .foregroundColor(Color.DessertRun.accent)
                            
                            Text("特定美食限制")
                                .font(.system(size: 14))
                                .foregroundColor(.black)
                        }
                        .padding(.top, 2)
                    }
                }
            } else {
                // 加载中状态
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
        .padding(.horizontal, 16)
        .padding(.top, -10)
    }
    
    // 奖励信息部分
    private var rewardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let challenge = viewModel.selectedChallenge {
                Text("活动奖励")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                HStack(spacing: 16) {
                    // 奖励图标
                    Image(systemName: getRewardIcon(for: challenge.rewardType))
                        .font(.system(size: 32))
                        .foregroundColor(Color.DessertRun.accent)
                        .frame(width: 60, height: 60)
                        .background(Color.DessertRun.accent.opacity(0.1))
                        .cornerRadius(30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // 奖励名称
                        Text(challenge.formattedReward)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                        
                        // 奖励描述
                        Text(challenge.rewardDescription)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 4)
            } else {
                // 加载中状态
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
        .padding(.horizontal, 16)
        .padding(.top, 16)
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
                                    .fill(Color.DessertRun.accent)
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
                                    .fill(Color.DessertRun.accent)
                            )
                    }
                } else if challenge.statusText == "即将开始" {
                    // 活动未开始 - 显示不可报名状态
                    Text("活动未开始")
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
                    Text("活动已结束")
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
        .padding(16)
        .background(Color.white)
        .cornerRadiusExt(12, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        .padding(.top, 24)
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
}

#Preview {
    NavigationView {
        ChallengeDetailView(challengeId: "1")
            .environmentObject(AppState.shared)
    }
} 