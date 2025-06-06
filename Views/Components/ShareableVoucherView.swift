import SwiftUI
import CoreImage.CIFilterBuiltins

/// 可分享的美食券视图 - 用于生成分享图片
struct ShareableVoucherView: View {
    let voucher: DessertVoucher
    let qrCodeData: String
    let shareMessage: String
    
    @State private var qrCodeImage: UIImage?
    
    /// 初始化函数
    init(voucher: DessertVoucher, qrCodeData: String, shareMessage: String) {
        self.voucher = voucher
        self.qrCodeData = qrCodeData
        self.shareMessage = shareMessage
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "F8F9FA"),
                    Color(hex: "E9ECEF")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 0) {
                // 顶部品牌区域
                VStack(spacing: 8) {
                    // App Logo 和名称
                    HStack(spacing: 12) {
                        // 使用真实的App图标
                        if let appIcon = UIImage(named: "AppIcon") ?? 
                                          UIImage(named: "ckt_1747105656798") ??
                                          Bundle.main.icon {
                            Image(uiImage: appIcon)
                                .resizable()
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            // 备用图标
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.DessertRun.accent, Color(hex: "FF2D55")]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Text("🏃")
                                        .font(.system(size: 24))
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("该吃吃")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text("运动换美食，健康新生活")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // 分享标题
                    Text(shareMessage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                }
                
                // 使用原来的DessertVoucherCardSimple组件（已修复渲染问题）
                VStack(spacing: 0) {
                    DessertVoucherCardSimple(voucher: voucher, forceExpanded: true, isForSharing: true)
                        .environmentObject(AppState.shared)
                        .scaleEffect(0.85) // 略微缩小以适应分享图片布局
                        .padding(.horizontal, 10)
                    
                    // 券状态和券号信息
                    VStack(spacing: 4) {
                        HStack {
                            Text("券状态")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text(voucherStatusText)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(voucherStatusColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(voucherStatusColor.opacity(0.1))
                                )
                        }
                        
                        HStack {
                            Text("券号")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("#\(voucher.id.prefix(8))")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .padding(.vertical, 20)
                
                Spacer()
            }
            
            // 右下角二维码区域 - 调整布局
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    HStack(spacing: 8) {
                        // 文字放在二维码左边
                        VStack(spacing: 2) {
                            Text("扫码体验")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.black)
                            
                            Text("该吃吃")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                        }
                        
                        // 二维码
                        if let qrImage = qrCodeImage {
                            Image(uiImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .frame(width: 60, height: 60)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text("QR")
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(width: 340, height: 500)
        .onAppear {
            generateQRCode()
        }
    }
    
    /// 券状态文本
    private var voucherStatusText: String {
        switch voucher.voucherStatus {
        case .active:
            return "已激活"
        case .inactive:
            return "未激活"
        case .used:
            return "已使用"
        case .expired:
            return "已过期"
        }
    }
    
    /// 券状态颜色
    private var voucherStatusColor: Color {
        switch voucher.voucherStatus {
        case .active:
            return .green
        case .inactive:
            return .orange
        case .used:
            return .gray
        case .expired:
            return .red
        }
    }
    
    /// 生成二维码
    private func generateQRCode() {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(qrCodeData.utf8)
        
        if let outputImage = filter.outputImage {
            // 放大二维码图像以提高清晰度
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrCodeImage = UIImage(cgImage: cgImage)
            }
        }
    }
    
    /// 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

/// Bundle扩展，用于获取App图标
extension Bundle {
    var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
} 