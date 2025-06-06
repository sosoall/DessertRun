import SwiftUI

/// 全屏展开美食券视图（简化版）
struct ExpandedVoucherFullScreenView: View {
    let voucher: DessertVoucher
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    
    // 分享相关状态
    @StateObject private var shareManager = VoucherShareManager()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.8).ignoresSafeArea()
            
            VStack(spacing: 16) {
                Spacer()
                
                DessertVoucherCardSimple(voucher: voucher, forceExpanded: true)
                    .environmentObject(appState)
                    .padding()
                
                // 分享按钮
                if voucher.voucherStatus == .active {
                    Button(action: {
                        shareManager.shareVoucher(voucher)
                    }) {
                        HStack(spacing: 12) {
                            if shareManager.isGenerating {
                                // 替换UIKit的ProgressView为纯SwiftUI动画
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                        .frame(width: 18, height: 18)
                                    
                                    Circle()
                                        .trim(from: 0, to: 0.8)
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 18, height: 18)
                                        .rotationEffect(.degrees(shareManager.isGenerating ? 360 : 0))
                                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: shareManager.isGenerating)
                                }
                                .scaleEffect(0.8)
                                
                                Text("生成中...")
                                    .font(.system(size: 16, weight: .medium))
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18))
                                
                                Text("分享美食券")
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 32)
                        .frame(minWidth: 280)
                        .background(
                            LinearGradient(
                                gradient: Gradient(
                                    colors: [
                                        Color(hex: "#FE2D55"),
                                        Color(hex: "#FF896E")
                                    ]
                                ),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                    }
                    .disabled(shareManager.isGenerating)
                    .padding(.top, 8)
                }
                
                Spacer()
            }
            
            // 关闭按钮
            Button(action: {
                NotificationCenter.default.post(name: NSNotification.Name("ExpandedCardDismissed"), object: voucher)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .padding()
            }
            
            // 统一的分享图片预览界面
            if shareManager.showSharePreview {
                UnifiedSharePreviewView(voucher: voucher, shareManager: shareManager)
                    .zIndex(1000) // 确保在最上层
            }
        }
        // 分享错误提示
        .alert("分享失败", isPresented: Binding<Bool>(
            get: { shareManager.shareError != nil },
            set: { if !$0 { shareManager.shareError = nil } }
        )) {
            Button("确定", role: .cancel) {
                shareManager.shareError = nil
            }
        } message: {
            Text(shareManager.shareError ?? "未知错误")
        }
        .onAppear {
            // 展开美食券时隐藏TabBar
            appState.hideTabBarForExpandedVoucher = true
        }
        .onDisappear {
            // 关闭美食券时恢复TabBar
            appState.hideTabBarForExpandedVoucher = false
        }
    }
}

#Preview {
    ExpandedVoucherFullScreenView(voucher: DessertVoucher.sample)
        .environmentObject(AppState.shared)
} 