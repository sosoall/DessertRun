import SwiftUI

/// 简化版美食券列表视图（无筛选，平铺展示）
struct BasicEnrollmentVoucherListView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = EnrollmentVoucherViewModel()
    
    // 绑定到上层的面板高度
    @Binding var sheetHeight: CGFloat
    
    let enrollmentId: String
    
    // 添加展开卡片相关状态
    @State private var showExpandedCard: Bool = false
    @State private var selectedVoucher: DessertVoucher? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer().frame(height: 20)
            // 引导语
            Text("请用运动去激活下列美食券，完成挑战吧！")
                .font(.headline)
                .foregroundColor(Color.DessertRun.accent)
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
            
            // 监听美食券展开通知
            NotificationCenter.default.addObserver(forName: NSNotification.Name("ShowExpandedCard"), object: nil, queue: .main) { notification in
                if let voucher = notification.object as? DessertVoucher {
                    selectedVoucher = voucher
                    showExpandedCard = true
                }
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ShowExpandedCard"), object: nil)
        }
        .sheet(isPresented: $showExpandedCard) {
            if let voucher = selectedVoucher {
                ExpandedCardView(voucher: voucher, isShowing: $showExpandedCard, preloadedImageInfo: nil)
                    .environmentObject(appState)
            }
        }
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

#Preview {
    BasicEnrollmentVoucherListView(sheetHeight: .constant(400), enrollmentId: "demo-id")
        .environmentObject(AppState.shared)
} 