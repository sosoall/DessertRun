//
//  VoucherDetailView.swift
//  DessertRun
//
//  Created by Claude on 2025/04/10
//

import SwiftUI

/// 美食券详情页
struct VoucherDetailView: View {
    let voucher: DessertRun.DessertVoucher
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 券详情
                    voucherDetailCard
                    
                    // 使用说明
                    usageInstructions
                    
                    // 按钮
                    actionButtons
                }
                .padding()
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("美食券详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    /// 券详情卡片
    private var voucherDetailCard: some View {
        VStack(spacing: 15) {
            // 美食图片
            ZStack {
                Circle()
                    .fill(voucher.dessert.backgroundColor ?? Color.gray)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "cup.and.saucer.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: 70, height: 70)
            }
            .padding(.top)
            
            // 美食名称
            Text(voucher.dessert.name)
                .font(.title)
                .fontWeight(.bold)
            
            // 券信息
            HStack {
                // 卡路里
                VStack {
                    Text("卡路里")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(voucher.dessert.calories)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                
                // 状态
                VStack {
                    Text("状态")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(voucher.status.rawValue)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(statusColor(voucher.status))
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            
            // 有效期
            HStack {
                Text("发放日期:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(formattedDate(voucher.earnedDate))
                    .font(.subheadline)
                
                Spacer()
                
                Text("有效期至:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(formattedDate(voucher.expiryDate))
                    .font(.subheadline)
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            // 完成度（如果是部分券）
            if voucher.isPartial {
                VStack(spacing: 5) {
                    HStack {
                        Text("完成度")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(voucher.completionPercentage))%")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    
                    // 进度条
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // 背景
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            // 进度
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "FE2D55"))
                                .frame(width: max(0, min(geometry.size.width, geometry.size.width * voucher.completionPercentage / 100)), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
    
    /// 使用说明
    private var usageInstructions: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("使用说明")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                instructionRow(number: "1", text: "到店出示此美食券")
                instructionRow(number: "2", text: "店员扫描二维码或输入券码核销")
                instructionRow(number: "3", text: "立即享用美味美食")
                if voucher.isPartial {
                    instructionRow(number: "4", text: "部分券仅可兑换\(Int(voucher.completionPercentage))%的美食份量")
                }
            }
            
            Text("注意：美食券有效期为30天，过期后将无法使用")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 5)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10)
    }
    
    /// 按钮区域
    private var actionButtons: some View {
        VStack(spacing: 15) {
            // 使用按钮
            Button(action: {}) {
                HStack {
                    Image(systemName: "qrcode")
                    Text("在店内使用")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "FE2D55"))
                .cornerRadius(16)
            }
            .disabled(voucher.status != .active)
            .opacity(voucher.status == .active ? 1.0 : 0.5)
            
            // 分享按钮
            Button(action: {}) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("分享美食券")
                }
                .font(.headline)
                .foregroundColor(Color(hex: "61462C"))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "61462C").opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    /// 说明行
    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Text(number)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color(hex: "FE2D55"))
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
            
            Spacer()
        }
    }
    
    /// 格式化日期
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    /// 状态颜色
    private func statusColor(_ status: VoucherStatus) -> Color {
        switch status {
        case .active:
            return .green
        case .used:
            return .gray
        case .expired:
            return .red
        }
    }
}