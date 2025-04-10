//
//  StatsHomeView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

// 引用美食券相关组件

/// 统计模块主页面
struct StatsHomeView: View {
    // 全局应用状态
    @EnvironmentObject var appState: AppState
    
    // 统计管理器
    private let statsManager = WorkoutStatsManager()
    
    // 当前月份的记录
    @State private var currentMonthRecords: [DailyWorkoutRecord] = []
    
    // 当前日期
    @State private var currentDate = Date()
    
    // 添加选择的美食券状态
    @State private var selectedVoucher: DessertRun.DessertVoucher?
    
    var body: some View {
        VStack(spacing: 0) {
            // 页面标题
            Text("运动统计")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "61462C"))
                .padding(.top, 16)
            
            // 分段控制器
            Picker("视图选择", selection: $appState.statsSelectedSegment) {
                Text("运动日历").tag(0)
                Text("美食券").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // 根据选中的分段显示不同内容
            if appState.statsSelectedSegment == 0 {
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
                // 美食券列表占位视图
                VStack {
                    Text("我的美食券")
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
                    
                    // 美食券列表
                    ScrollView {
                        VStack(spacing: 15) {
                            // 使用获得的美食券
                            ForEach(appState.dessertVouchers, id: \.id) { voucher in
                                foodVoucherCard(voucher: voucher)
                            }
                            
                            // 如果没有美食券，显示示例券
                            if appState.dessertVouchers.isEmpty {
                                // 示例券
                                if let sampleVouchers = DessertVoucherData.getSampleVouchers().first {
                                    foodVoucherCard(voucher: sampleVouchers)
                                }
                                
                                Text("完成更多运动，获得更多美食券！")
                                    .foregroundColor(.gray)
                                    .padding(.top, 30)
                            }
                        }
                        .padding(.top)
                    }
                }
                .padding()
                .sheet(item: $selectedVoucher) { voucher in
                    VoucherDetailView(voucher: voucher)
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
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
                
                // 美食券
                VStack(alignment: .leading) {
                    Text("\(stats.vouchersEarned)")
                        .font(.title3)
                        .bold()
                    Text("获得美食券")
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
    
    // 美食券卡片 - 精简版
    func foodVoucherCard(voucher: DessertRun.DessertVoucher) -> some View {
        HStack {
            // 左侧：美食图片
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
                    .frame(width: 60, height: 60)
                
                // 美食图片
                ZStack {
                    // 尝试加载美食图片，如果失败则显示系统图标
                    if !voucher.dessert.imageName.isEmpty {
                        Image(voucher.dessert.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    } else {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    
                    // 如果是部分完成，添加遮罩效果
                    if voucher.isPartial {
                        Circle()
                            .trim(from: 0, to: 1 - voucher.completionPercentage / 100)
                            .rotation(.degrees(-90))
                            .stroke(Color.black.opacity(0.5), lineWidth: 40)
                            .frame(width: 40, height: 40)
                    }
                }
            }
            
            // 中间：美食名称和状态
            VStack(alignment: .leading, spacing: 4) {
                Text(voucher.dessert.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
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
                    
                    Text("有效期:\(formattedDate(voucher.expiryDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 右侧：查看按钮
            Button(action: {
                selectedVoucher = voucher
            }) {
                Text("查看")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "FF5E62"))
                    .cornerRadius(12)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
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
            return Color.gray
        case .expired:
            return Color.red
        }
    }
    
    // 格式化日期
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        StatsHomeView()
            .environmentObject(AppState.shared)
    }
} 