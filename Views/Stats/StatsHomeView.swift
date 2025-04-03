//
//  StatsHomeView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

/// 统计模块主页面
struct StatsHomeView: View {
    // 全局应用状态
    @EnvironmentObject var appState: AppState
    
    // 当前选中的子页面（0: 运动日历, 1: 甜品券）
    @State private var selectedSegment = 0
    
    // 统计管理器
    private let statsManager = WorkoutStatsManager()
    
    // 当前月份的记录
    @State private var currentMonthRecords: [DailyWorkoutRecord] = []
    
    // 当前日期
    @State private var currentDate = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // 页面标题
            Text("运动统计")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "61462C"))
                .padding(.top, 16)
            
            // 分段控制器
            Picker("视图选择", selection: $selectedSegment) {
                Text("运动日历").tag(0)
                Text("甜品券").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // 根据选中的分段显示不同内容
            if selectedSegment == 0 {
                // 运动日历占位视图
                VStack {
                    Text("运动日历")
                        .font(.title2)
                        .padding(.bottom, 16)
                    
                    // 月度统计卡片
                    monthlyStatsCard
                    
                    Spacer()
                    
                    Text("这里将显示日历和运动记录")
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding()
            } else {
                // 甜品券列表占位视图
                VStack {
                    Text("我的甜品券")
                        .font(.title2)
                        .padding(.bottom, 16)
                    
                    // 券分类导航
                    HStack {
                        Text("全部")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(hex: "FE2D55"))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        
                        Text("有效")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.black)
                            .cornerRadius(16)
                        
                        Text("已使用")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.black)
                            .cornerRadius(16)
                        
                        Text("已过期")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.black)
                            .cornerRadius(16)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // 示例券
                    if let sampleVouchers = DessertVoucherData.getSampleVouchers().first {
                        voucherCard(voucher: sampleVouchers)
                    }
                    
                    Spacer()
                    
                    Text("这里将显示甜品券列表")
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding()
            }
        }
        .background(Color(hex: "fae8c8").ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            // 加载当前月份的记录
            loadCurrentMonthRecords()
        }
    }
    
    // 月度统计卡片
    var monthlyStatsCard: some View {
        let stats = statsManager.calculateStats(for: .month)
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("本月运动概览")
                .font(.headline)
                .foregroundColor(Color(hex: "61462C"))
            
            HStack(spacing: 20) {
                // 运动时长
                VStack(alignment: .leading) {
                    Text("\(stats.totalMinutes / 60)小时\(stats.totalMinutes % 60)分钟")
                        .font(.title3)
                        .bold()
                    Text("运动时长")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 运动距离
                VStack(alignment: .leading) {
                    Text(String(format: "%.1f", stats.totalDistance / 1000))
                        .font(.title3)
                        .bold()
                    Text("公里")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 甜品券
                VStack(alignment: .leading) {
                    Text("\(stats.vouchersEarned)")
                        .font(.title3)
                        .bold()
                    Text("获得甜品券")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // 甜品券卡片
    func voucherCard(voucher: DessertRun.DessertVoucher) -> some View {
        VStack(alignment: .leading) {
            HStack {
                // 甜品图片（使用占位图）
                Circle()
                    .fill(voucher.dessert.backgroundColor ?? Color.gray)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(voucher.dessert.name.prefix(1)))
                            .font(.title)
                            .foregroundColor(.white)
                    )
                    .padding(.trailing, 8)
                
                // 券信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(voucher.dessert.name)
                        .font(.headline)
                    
                    HStack {
                        Text(voucher.status.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor(for: voucher.status))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        
                        if voucher.isPartial {
                            Text("\(Int(voucher.completionPercentage))%完成")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    
                    Text("有效期至: \(formattedDate(voucher.expiryDate))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 使用按钮
                if voucher.status == .active {
                    Button(action: {
                        // 券使用逻辑
                    }) {
                        Text("使用")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(hex: "FE2D55"))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                }
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // 加载当前月份记录
    private func loadCurrentMonthRecords() {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)
        
        currentMonthRecords = statsManager.getRecordsForMonth(year: year, month: month)
    }
    
    // 根据状态获取颜色
    private func statusColor(for status: VoucherStatus) -> Color {
        switch status {
        case .active:
            return Color.green
        case .used:
            return Color.blue
        case .expired:
            return Color.gray
        }
    }
    
    // 格式化日期
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        StatsHomeView()
            .environmentObject(AppState.shared)
    }
} 