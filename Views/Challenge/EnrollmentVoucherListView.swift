import SwiftUI

/// 显示指定报名记录下美食券列表的视图
struct EnrollmentVoucherListView: View {
    let enrollmentId: String
    @StateObject private var viewModel = EnrollmentVoucherViewModel()
    @State private var selectedFilter: RecordFilter = .all
    @State private var showExpandedCard: Bool = false
    @State private var selectedVoucher: DessertVoucher? = nil
    @State private var preloadedInfo: [String: Any]? = nil
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 16) {
                // 筛选栏
                filterBar

                // 列表
                if viewModel.isLoading && viewModel.vouchers.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                        Spacer()
                    }
                } else if filteredVouchers.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.system(size: 28))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("暂无记录")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredVouchers, id: \.id) { voucher in
                                DessertVoucherCardSimple(voucher: voucher)
                                    .environmentObject(appState)
                                    .padding(.horizontal, 8)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .onAppear {
                if viewModel.vouchers.isEmpty {
                    viewModel.loadVouchers(enrollmentId: enrollmentId, filter: selectedFilter)
                }

                // 监听卡片点击通知
                NotificationCenter.default.addObserver(forName: NSNotification.Name("ShowExpandedCard"), object: nil, queue: .main) { notification in
                    if let voucher = notification.object as? DessertVoucher {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedVoucher = voucher
                            showExpandedCard = true
                        }
                        if let userInfo = notification.userInfo as? [String: Any] {
                            preloadedInfo = userInfo
                        }
                    }
                }
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ShowExpandedCard"), object: nil)
            }
            // 展开视图覆盖层
            if showExpandedCard, let voucher = selectedVoucher {
                ExpandedCardView(
                    voucher: voucher,
                    isShowing: $showExpandedCard,
                    preloadedImageInfo: preloadedInfo
                )
                .transition(.opacity)
            }
        }
    }

    // 筛选栏视图
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(RecordFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation {
                            if selectedFilter != filter {
                                selectedFilter = filter
                                viewModel.reset()
                                viewModel.loadVouchers(enrollmentId: enrollmentId, filter: selectedFilter)
                            }
                        }
                    }) {
                        Text(filter.rawValue)
                            .font(.system(size: 14))
                            .fontWeight(selectedFilter == filter ? .semibold : .regular)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 14)
                            .background(selectedFilter == filter ? Color.accentColor : Color(UIColor.secondarySystemBackground))
                            .foregroundColor(selectedFilter == filter ? .white : .primary)
                            .cornerRadius(16)
                    }
                }
            }
        }
    }

    // 根据筛选条件过滤
    private var filteredVouchers: [DessertVoucher] {
        switch selectedFilter {
        case .all:
            return viewModel.vouchers
        case .active:
            return viewModel.vouchers.filter { $0.status == "active" }
        case .used:
            return viewModel.vouchers.filter { $0.status == "used" }
        case .expired:
            return viewModel.vouchers.filter { $0.status == "expired" }
        }
    }
}

#Preview {
    EnrollmentVoucherListView(enrollmentId: "sample")
        .environmentObject(AppState.shared)
} 