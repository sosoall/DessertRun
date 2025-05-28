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
        return NavigationView {
            ZStack {
                Color(hex: "F5F5F5")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    filterHeader
                    challengeContent
                }

                // 加载中指示器
                if viewModel.isLoading {
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
            .navigationTitle("我的挑战")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.loadDetailedEnrollments()
            }
        }
    }
    
    // MARK: - View Builders
    @ViewBuilder
    private var filterHeader: some View {
        HStack {
            Text("筛选:")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)

            Picker("状态筛选", selection: $selectedStatus) {
                Text("进行中").tag(EnrollmentStatus.ongoing)
                Text("已完成").tag(EnrollmentStatus.completed)
                Text("已失败").tag(EnrollmentStatus.failed)
            }
            .pickerStyle(SegmentedPickerStyle())

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var challengeContent: some View {
        if viewModel.enrolledChallenges.isEmpty {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
            } else {
                // 空状态
                VStack(spacing: 16) {
                    Image(systemName: "trophy")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)

                    Text("暂无已报名的挑战")
                        .font(.headline)
                        .foregroundColor(.gray)

                    Button("去报名") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.DessertRun.accent)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                .padding(.top, 100)
            }
        } else if filteredEnrollments.isEmpty {
            VStack {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
                    .padding(.bottom, 16)

                Text("暂无\(getStatusText(selectedStatus))的挑战")
                    .font(.headline)
                    .padding(.bottom, 4)

                Text("参加挑战，开始你的甜品运动之旅吧！")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemGray6))
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredEnrollments, id: \.enrollment.id) { enrollment in
                        NavigationLink(destination: ChallengeDetailView(challengeId: enrollment.challenge.id, viewModel: viewModel)) {
                            EnrollmentCard(enrollment: enrollment)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Private Methods
    
    // 根据选择的状态筛选挑战
    private var filteredEnrollments: [EnrollmentWithChallengeDetail] {
        return viewModel.enrolledChallenges.filter { enrollment in
            enrollment.enrollment.enrollmentStatus == selectedStatus
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

/// 报名挑战卡片
struct EnrollmentCard: View {
    let enrollment: EnrollmentWithChallengeDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 挑战标题和状态
            HStack {
                Text(enrollment.challenge.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Spacer()
                
                // 状态标签
                Text(getStatusText(enrollment.enrollment.enrollmentStatus))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(getStatusColor(enrollment.enrollment.enrollmentStatus))
                    )
            }
            
            // 进度信息
            VStack(alignment: .leading, spacing: 4) {
                // 进度条
                ProgressView(value: getProgress())
                    .accentColor(Color.DessertRun.accent)
                
                // 进度文本
                HStack {
                    Text("进度：\(enrollment.enrollment.completedCheckins)/\(enrollment.challenge.requiredCheckins)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // 活动时间
                    Text(enrollment.challenge.formattedDuration)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            // 奖励信息
            HStack {
                Image(systemName: "gift")
                    .font(.system(size: 12))
                    .foregroundColor(Color.DessertRun.accent)
                
                Text(enrollment.challenge.formattedReward)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Spacer()
                
                // 报名时间
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text(formatDate(enrollment.enrollment.enrolledAt))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            // 完成信息（如果已完成）
            if enrollment.enrollment.isCompleted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color.DessertRun.accent)
                    
                    if let completionDate = enrollment.enrollment.completionDate {
                        Text("完成于：\(formatDate(completionDate))")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    } else {
                        Text("已完成")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // 奖励领取信息
                    if enrollment.enrollment.redemptionDate != nil {
                        Text("已领取奖励")
                            .font(.system(size: 12))
                            .foregroundColor(Color.DessertRun.accent)
                    } else {
                        Text("未领取奖励")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
    }
    
    // 获取进度百分比
    private func getProgress() -> Double {
        let completed = Double(enrollment.enrollment.completedCheckins)
        let required = Double(enrollment.challenge.requiredCheckins)
        return required > 0 ? min(completed / required, 1.0) : 0.0
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
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
            return Color(hex: "4CAF50") // 绿色
        case .completed:
            return Color.DessertRun.accent
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
