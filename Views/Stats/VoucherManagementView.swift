//
//  VoucherManagementView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/11.
//

import SwiftUI

struct VoucherManagementView: View {
    // 全局应用状态
    @EnvironmentObject var appState: AppState
    
    // 当前选中的日期
    @State private var selectedDate = Date()
    
    // 当前筛选状态
    @State private var selectedStatus = "全部"
    
    // 可选的状态筛选项
    private let statusOptions = ["全部", "有效", "已使用", "已过期"]
    
    // 当前月份的美食券
    @State private var monthVouchers: [DessertRun.DessertVoucher] = []
    
    // 选中查看的美食券
    @State private var selectedVoucher: DessertRun.DessertVoucher?
    
    // 列数（用于瀑布流布局）
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                // 月份选择器
                MonthPicker(selectedDate: $selectedDate, onMonthChange: {
                    loadMonthVouchers()
                })
                
                // 状态筛选
                StatusFilter(selectedStatus: $selectedStatus, options: statusOptions)
                    .padding(.top, 5)
                
                // 美食券列表（瀑布流布局）
                if filteredVouchers.isEmpty {
                    emptyStateView
                } else {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(filteredVouchers, id: \.id) { voucher in
                            VoucherCard(voucher: voucher)
                                .onTapGesture {
                                    selectedVoucher = voucher
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
            }
            .padding(.bottom, 20)
        }
        .sheet(item: $selectedVoucher) { voucher in
            SimpleVoucherDetailView(voucher: voucher)
        }
        .onAppear {
            loadMonthVouchers()
        }
    }
    
    // 筛选后的美食券
    private var filteredVouchers: [DessertRun.DessertVoucher] {
        if selectedStatus == "全部" {
            return monthVouchers
        } else {
            return monthVouchers.filter { voucher in
                let statusString: String
                switch voucher.status {
                case .active: statusString = "有效"
                case .used: statusString = "已使用"
                case .expired: statusString = "已过期"
                }
                return statusString == selectedStatus
            }
        }
    }
    
    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "ticket")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "FE2D55").opacity(0.3))
                .padding(.top, 50)
            
            Text("没有找到美食券")
                .font(.headline)
                .foregroundColor(Color(hex: "61462C"))
            
            Text("完成更多运动，获取美食券奖励！")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                // 跳转到运动页面
                appState.selectedTabIndex = 0
            }) {
                Text("去运动")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color(hex: "FE2D55"))
                    .cornerRadius(25)
            }
            .padding(.top, 15)
            .padding(.bottom, 50)
        }
    }
    
    // 加载月份美食券
    private func loadMonthVouchers() {
        // 目前使用模拟数据，之后会替换为真实API调用
        monthVouchers = MockDataProvider.generateMockVouchers(for: selectedDate)
    }
}

// 美食券卡片组件
struct VoucherCard: View {
    var voucher: DessertRun.DessertVoucher
    
    var body: some View {
        VStack(spacing: 10) {
            // 美食图片
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "FF5E62").opacity(0.8),
                                Color(hex: "FF9966").opacity(0.9)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                // 美食图片
                if !voucher.dessert.imageName.isEmpty {
                    Image(voucher.dessert.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                } else {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                }
                
                // 完成度环形进度
                if voucher.isPartial {
                    Circle()
                        .trim(from: 0, to: 1 - voucher.completionPercentage / 100)
                        .rotation(.degrees(-90))
                        .stroke(Color.black.opacity(0.3), lineWidth: 8)
                        .frame(width: 80, height: 80)
                }
            }
            
            // 美食名称
            Text(voucher.dessert.name)
                .font(.headline)
                .foregroundColor(Color(hex: "61462C"))
                .lineLimit(1)
            
            // 状态标签
            HStack {
                if voucher.isPartial {
                    Text("\(Int(voucher.completionPercentage))%")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "FF5E62"))
                        .cornerRadius(4)
                }
                
                Text(voucher.status.rawValue)
                    .font(.caption)
                    .foregroundColor(statusColor(for: voucher.status))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(statusColor(for: voucher.status).opacity(0.2))
                    .cornerRadius(4)
            }
            
            // 有效期
            Text("有效期至: \(DateHelper.formatDate(voucher.expiryDate))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 10)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        // 状态特殊效果
        .saturation(voucher.status == .used || voucher.status == .expired ? 0.5 : 1.0)
        .opacity(voucher.status == .used || voucher.status == .expired ? 0.8 : 1.0)
    }
    
    // 状态颜色
    private func statusColor(for status: VoucherStatus) -> Color {
        switch status {
        case .active:
            return Color.green
        case .used:
            return Color.gray
        case .expired:
            return Color.red
        }
    }
}

// 简易版券详情视图
struct SimpleVoucherDetailView: View {
    var voucher: DessertRun.DessertVoucher
    
    // 环境变量用于关闭sheet
    @Environment(\.dismiss) private var dismiss
    
    // 可撕券相关状态
    @State private var voucherRedeemed: Bool
    @State private var tearProgress: CGFloat = 0
    @State private var tornBottomPart = false
    @State private var showRedeemAlert = false
    
    // 初始化
    init(voucher: DessertRun.DessertVoucher) {
        self.voucher = voucher
        _voucherRedeemed = State(initialValue: voucher.status == .used)
    }
    
    var body: some View {
        VStack {
            // 顶部关闭按钮
            HStack {
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(Color.gray.opacity(0.7))
                }
                .padding()
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    // 标题
                    Text("美食券详情")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "61462C"))
                    
                    // 甜品券视图
                    FoodVoucherView(
                        voucher: voucher,
                        voucherRedeemed: $voucherRedeemed,
                        tearProgress: $tearProgress,
                        tornBottomPart: $tornBottomPart,
                        showRedeemAlert: $showRedeemAlert
                    )
                    .padding(.top, 10)
                    
                    // 详情信息
                    VStack(alignment: .leading, spacing: 16) {
                        Text("详细信息")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "61462C"))
                        
                        // 美食详情
                        VStack(alignment: .leading, spacing: 6) {
                            Text("美食名称:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text(voucher.dessert.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        // 热量详情
                        VStack(alignment: .leading, spacing: 6) {
                            Text("热量:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text(voucher.dessert.calories)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        // 完成度
                        VStack(alignment: .leading, spacing: 6) {
                            Text("运动完成度:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text("\(Int(voucher.completionPercentage))%")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        // 状态
                        VStack(alignment: .leading, spacing: 6) {
                            Text("券状态:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(statusColor(for: voucher.status))
                                    .frame(width: 10, height: 10)
                                
                                Text(voucher.status.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        // 有效期
                        VStack(alignment: .leading, spacing: 6) {
                            Text("有效期至:")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text(formatDate(voucher.expiryDate))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.bottom, 30)
            }
        }
        .background(Color(hex: "F8F8F8").ignoresSafeArea())
    }
    
    // 状态颜色
    private func statusColor(for status: VoucherStatus) -> Color {
        switch status {
        case .active:
            return Color.green
        case .used:
            return Color.gray
        case .expired:
            return Color.red
        }
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter.string(from: date)
    }
}

#Preview {
    VoucherManagementView()
        .environmentObject(AppState.shared)
} 