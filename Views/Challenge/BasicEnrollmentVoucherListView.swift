import SwiftUI

/// 简化版美食券列表视图（无筛选，平铺展示）
struct BasicEnrollmentVoucherListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = EnrollmentVoucherViewModel()
    
    // 绑定到上层的面板高度
    @Binding var sheetHeight: CGFloat
    
    let enrollmentId: String
    
    // MARK: - 主视图
    var body: some View {
        ZStack {
            // 主列表内容
            VStack(alignment: .leading, spacing: 16) {
                Spacer().frame(height: 20)
                // 引导语
                Text("请完成任务卡上的运动吧！")
                    .font(.headline)
                    .foregroundColor(.black)
                    .bold()
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 20)
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // 数据分段
                            let tasks = viewModel.vouchers.filter { $0.voucherStatus == .inactive }
                            let coupons = viewModel.vouchers.filter { $0.voucherStatus != .inactive }

                            if !tasks.isEmpty {
                                SectionHeaderView(title: "任务卡")
                                    .padding(.horizontal, 20)
                                ForEach(tasks, id: \.id) { voucher in
                                    TaskCardView(voucher: voucher)
                                        .environmentObject(appState)
                                        .padding(.horizontal, 16)
                                }
                            }

                            if !coupons.isEmpty {
                                SectionHeaderView(title: "已解锁美食券")
                                    .padding(.top, tasks.isEmpty ? 0 : 12)
                                    .padding(.horizontal, 20)
                                ForEach(coupons, id: \.id) { voucher in
                                    DessertVoucherCardSimple(voucher: voucher)
                                        .environmentObject(appState)
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                }
            }
            // 无需局部 blur，交由上层弹窗处理
        }
        .onAppear {
            viewModel.loadVouchers(enrollmentId: enrollmentId)
        }
        .onDisappear {}
        .onChange(of: viewModel.vouchers) { _, _ in
            recalcHeight()
        }
    }
    
    // MARK: - 动态高度计算
    private func recalcHeight() {
        // 估算：卡片高度≈120，间距12；引导语 & 安全余量 100
        let perCard: CGFloat = 160  // 增加单个卡片的估算高度
        let base: CGFloat = 100     // 增加基础高度
        let total = CGFloat(viewModel.vouchers.count) * perCard + base
        let screen = UIScreen.main.bounds.height
        let clamped = min(max(total, screen * 0.4), screen * 0.8)  // 调整最小和最大比例
        DispatchQueue.main.async {
            sheetHeight = clamped
        }
    }
}

// MARK: - Inactive 任务卡视图
struct TaskCardView: View {
    let voucher: DessertVoucher
    @EnvironmentObject var appState: AppState

    private func goWorkout() {
        NotificationCenter.default.post(name: NSNotification.Name("GoWorkoutFromTaskCard"), object: voucher)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            Text("任务卡")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.gray)

            // 任务要求（简单占位语句）
            Text("根据任务要求完成一次运动打卡后即可解锁美食券")
                .font(.system(size: 14))
                .foregroundColor(.gray)

            HStack {
                Text("剩余\(voucher.remainingDays)天")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                Spacer()
                Button(action: goWorkout) {
                    Text("去运动")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 22)
                        .background(Color(hex: "FE2D55"))
                        .cornerRadius(20)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .contentShape(Rectangle())
        .onTapGesture { goWorkout() }
    }
}

// MARK: - Section Header
struct SectionHeaderView: View {
    let title: String
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.gray)
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
        }
    }
}

#Preview {
    BasicEnrollmentVoucherListView(sheetHeight: .constant(400), enrollmentId: "demo-id")
        .environmentObject(AppState.shared)
} 