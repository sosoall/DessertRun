import SwiftUI

/// 简化版美食券列表视图（无筛选，平铺展示）
struct BasicEnrollmentVoucherListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = EnrollmentVoucherViewModel()
    
    // 绑定到上层的面板高度
    @Binding var sheetHeight: CGFloat
    
    let enrollmentId: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 引导语
            Text("请用运动去激活下列美食券，完成挑战吧！")
                .font(.system(size: 16))
                .foregroundColor(.gray)
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
                        ForEach(viewModel.vouchers, id: \.id) { voucher in
                            DessertVoucherCardSimple(voucher: voucher)
                                .environmentObject(appState)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadVouchers(enrollmentId: enrollmentId)
        }
        .onChange(of: viewModel.vouchers) { _, _ in
            recalcHeight()
        }
    }
    
    // MARK: - 动态高度计算
    private func recalcHeight() {
        // 估算：卡片高度≈120，间距12；引导语 & 安全余量 70
        let perCard: CGFloat = 140
        let base: CGFloat = 70
        let total = CGFloat(viewModel.vouchers.count) * perCard + base
        let screen = UIScreen.main.bounds.height
        let clamped = min(max(total, screen * 0.3), screen * 0.9)
        DispatchQueue.main.async {
            sheetHeight = clamped
        }
    }
}

#Preview {
    BasicEnrollmentVoucherListView(sheetHeight: .constant(400), enrollmentId: "demo-id")
        .environmentObject(AppState.shared)
} 