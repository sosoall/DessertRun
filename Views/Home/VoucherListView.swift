import SwiftUI
import Combine

/// 展示全部美食券的列表页
struct VoucherListView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var voucherService = VoucherService.shared
    
    @State private var selectedVoucher: DessertVoucher? = nil
    // 避免反复刷新
    @State private var hasLoadedOnce: Bool = false
    
    // 将美食券按日期(yyyy-MM-dd)分组并排序
    private var groupedVouchers: [(String, [DessertVoucher])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: voucherService.vouchers) { voucher -> String in
            let date = calendar.startOfDay(for: voucher.createdAt)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
        // 按日期倒序排序
        return groups.keys.sorted(by: >).map { key in
            (key, groups[key]!.sorted { $0.createdAt > $1.createdAt })
        }
    }
    
    // 格式化时间为24小时制（HH:mm）
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedVouchers, id: \.0) { dateString, vouchers in
                    Section(header: Text(dateString).font(.headline)) {
                        ForEach(vouchers) { voucher in
                            // 使用VStack将卡片和时间分开，时间显示在卡片外面
                            VStack(spacing: 0) {
                                // 美食券卡片
                                DessertVoucherCardSimple(voucher: voucher, forceExpanded: false)
                                    .environmentObject(appState)
                                    .padding(.vertical, 8)
                                
                                // 时间显示在卡片下方外面
                                HStack {
                                    Spacer()
                                    Text(formatTime(voucher.createdAt))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .padding(.trailing, 12)
                                        .padding(.top, 4)
                                }
                            }
                            .padding(.bottom, 12) // 增加每个券之间的间距
                        }
                    }
                }

                // 底部加载更多或进度
                if voucherService.isLoading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                } else if voucherService.hasMoreVouchers {
                    HStack {
                        Spacer()
                        Button("加载更多") {
                            voucherService.loadMoreVouchersIfNeeded()
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("我的美食券")
            // 使用overlay展示展开卡片，避免NavigationStack重建
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
            // 监听卡片展开通知
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowExpandedCard"))) { notification in
                if let voucher = notification.object as? DessertVoucher {
                    self.selectedVoucher = voucher
                }
            }
            // 清理已展开状态
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ExpandedCardDismissed"))) { _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    self.selectedVoucher = nil
                }
            }
            .onAppear {
                // 隐藏TabBar
                appState.hideTabBarForDrag = true
                if !hasLoadedOnce {
                    voucherService.loadVouchers(forceRefresh: voucherService.vouchers.isEmpty)
                    hasLoadedOnce = true
                }
            }
            .onDisappear {
                appState.hideTabBarForDrag = false
            }
        }
    }
}

#Preview {
    VoucherListView().environmentObject(AppState.shared)
} 