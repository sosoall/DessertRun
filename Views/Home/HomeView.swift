import SwiftUI
import Combine

/// 首页：问候语 + 美食券 + 运动统计
struct HomeView: View {
    // 复用外部传入的统计视图模型
    let viewModel: ExerciseRecordViewModel
    @EnvironmentObject var appState: AppState
    
    // 美食券数据（最近一天）
    @State private var vouchers: [DessertVoucher] = []
    @State private var showAllVouchers: Bool = false
    @State private var navigateToVoucherList: Bool = false
    @State private var errorMessage: String? = nil
    @State private var selectedVoucher: DessertVoucher? = nil
    @State private var hasLoadedVouchers: Bool = false
    @State private var startedInitialLoad: Bool = false
    
    // 引入VoucherService，实时监听加载状态
    @ObservedObject private var voucherService = VoucherService.shared
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                greetingSection
                voucherSection
                statisticsSection
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .onAppear {
                if !hasLoadedVouchers {
                    fetchVouchers()
                    hasLoadedVouchers = true
                    startedInitialLoad = true
                }
            }
        }
        // 使用overlay展示展开券，避免创建新Navigation栈
        .overlay(
            Group {
                if let voucher = selectedVoucher {
                    ExpandedVoucherFullScreenView(voucher: voucher)
                        .environmentObject(appState)
                        .transition(.opacity)
                        .zIndex(2)
                }
            }
        )
        // 监听通知
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowExpandedCard"))) { notification in
            if navigateToVoucherList {
                // 当前已在美食券列表页面，由其负责处理展开
                return
            }
            if let voucher = notification.object as? DessertVoucher {
                self.selectedVoucher = voucher
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ExpandedCardDismissed"))) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                self.selectedVoucher = nil
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        // 监听VoucherService加载完成后，如已有数据则确保不再显示骨架
        .onReceive(voucherService.$vouchers) { list in
            if startedInitialLoad {
                vouchers = Array(list.sorted { $0.createdAt > $1.createdAt }.prefix(3))
            }
        }
    }
    
    // MARK: - 子视图
    private var greetingSection: some View {
        let greeting = timeGreeting
        let displayName = appState.userProfile.nickname?.isEmpty == false ? appState.userProfile.nickname! : appState.userProfile.name
        return VStack(alignment: .leading, spacing: 4) {
            Text("\(greeting)，\(displayName)！")
                .font(.system(size: 28, weight: .bold))
            Text("保持运动，享受美食~")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
    }
    
    /// 根据当前时间返回问候语
    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12: return "早上好"
        case 12..<18: return "下午好"
        default: return "晚上好"
        }
    }
    
    private var voucherSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "我的美食券")
                Spacer()
                if !vouchers.isEmpty {
                    Button(action: { navigateToVoucherList = true }) {
                        Text("更多")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "FE2D55"))
                    }
                }
            }
            
            if voucherService.isLoading && vouchers.isEmpty {
                // Skeleton Placeholder
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        DessertVoucherCardSimple(voucher: .empty, forceExpanded: false)
                            .redacted(reason: .placeholder)
                            .shimmering()
                    }
                }
            } else if let error = errorMessage {
                Text(error).foregroundColor(.red)
            } else if vouchers.isEmpty && !voucherService.isLoading {
                // 数据加载完毕仍为空时才显示
                Text("暂无可用美食券")
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(vouchers) { voucher in
                        DessertVoucherCardSimple(voucher: voucher, forceExpanded: false)
                            .environmentObject(appState)
                    }
                }
            }
        }
        // 使用导航跳转到全部美食券列表
        .background(
            NavigationLink(destination: VoucherListView().environmentObject(appState), isActive: $navigateToVoucherList) {
                EmptyView()
            }
            .hidden()
        )
    }
    
    private var statisticsSection: some View {
        ExerciseRecordView(viewModel: viewModel)
            .environmentObject(appState)
    }
    
    // MARK: - 网络
    private func fetchVouchers() {
        let existing = VoucherService.shared.vouchers
        if !existing.isEmpty {
            vouchers = Array(existing.sorted { $0.createdAt > $1.createdAt }.prefix(3))
        } else {
            VoucherService.shared.loadVouchers(forceRefresh: true)
        }
    }
} 