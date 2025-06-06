import SwiftUI
import UIKit

/// 统一的美食券分享管理器
class VoucherShareManager: ObservableObject {
    @Published var isGenerating = false
    @Published var showSharePreview = false
    @Published var sharePreviewImage: UIImage? = nil
    @Published var shareError: String?
    
    /// 分享美食券
    /// - Parameters:
    ///   - voucher: 要分享的美食券
    ///   - completion: 完成回调
    func shareVoucher(_ voucher: DessertVoucher, completion: @escaping (Bool) -> Void = { _ in }) {
        // 获取当前用户ID用于邀请链接
        guard let currentUser = AuthService.shared.currentUser else {
            shareError = "用户未登录，无法分享"
            completion(false)
            return
        }
        
        isGenerating = true
        shareError = nil
        
        Task {
            // 生成分享图片
            if let shareImage = await ShareService.shared.generateVoucherShareImage(
                voucher: voucher,
                userId: currentUser.id.uuidString
            ) {
                await MainActor.run {
                    isGenerating = false
                    sharePreviewImage = shareImage
                    showSharePreview = true
                    completion(true)
                    DRInfo("美食券分享图片生成成功，美食券ID: \(voucher.id)")
                }
            } else {
                await MainActor.run {
                    isGenerating = false
                    shareError = "图片生成失败"
                    completion(false)
                    DRError("美食券分享图片生成失败")
                }
            }
        }
    }
    
    /// 执行分享
    /// - Parameter voucher: 美食券
    func executeShare(voucher: DessertVoucher) {
        guard let image = sharePreviewImage else { return }
        
        let dessertName = voucher.dessertName ?? "美食"
        let shareText = "我刚刚通过运动获得了\(dessertName)美食券！一起来体验该吃吃吧~ #该吃吃 #运动换美食"
        ShareService.shared.shareImage(image, text: shareText, from: nil)
        closePreview()
    }
    
    /// 保存到相册
    func saveToPhotos() {
        guard let image = sharePreviewImage else { return }
        
        ShareService.shared.saveImageToPhotos(image) { success, message in
            DispatchQueue.main.async {
                if success {
                    DRInfo("图片保存成功")
                } else {
                    DRError("图片保存失败: \(message ?? "")")
                }
            }
        }
        closePreview()
    }
    
    /// 关闭预览
    func closePreview() {
        showSharePreview = false
        sharePreviewImage = nil
    }
    
    /// 重置状态
    func reset() {
        isGenerating = false
        showSharePreview = false
        sharePreviewImage = nil
        shareError = nil
    }
}

/// 统一的分享预览界面
struct UnifiedSharePreviewView: View {
    let voucher: DessertVoucher
    @ObservedObject var shareManager: VoucherShareManager
    
    @State private var dragOffset: CGFloat = 0
    @State private var imageScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 半透明背景
                Color.black.opacity(0.9)
                    .ignoresSafeArea()
                    .onTapGesture {
                        shareManager.closePreview()
                    }
                
                VStack(spacing: 0) {
                    // 顶部标题栏
                    HStack {
                        Text("分享预览")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            shareManager.closePreview()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                    
                    // 分享图片
                    ScrollView {
                        VStack {
                            if let image = shareManager.sharePreviewImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .scaleEffect(imageScale)
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                    .padding(.horizontal, 20)
                                    .onTapGesture(count: 2) {
                                        // 双击缩放
                                        withAnimation(.spring()) {
                                            imageScale = imageScale > 1.0 ? 1.0 : 1.5
                                        }
                                    }
                            }
                        }
                    }
                    .frame(maxHeight: geometry.size.height * 0.7)
                    
                    Spacer()
                    
                    // 底部操作按钮
                    HStack(spacing: 16) {
                        // 保存到相册按钮 - 改为灰色
                        Button(action: {
                            shareManager.saveToPhotos()
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 16))
                                
                                Text("保存")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(width: 70, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.gray.opacity(0.8),
                                                Color.gray
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                        }
                        
                        // 分享到微信按钮
                        Button(action: {
                            shareManager.executeShare(voucher: voucher)
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16))
                                
                                Text("分享到微信")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(width: 80, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.green.opacity(0.8),
                                                Color.green
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                        }
                        
                        // 关闭按钮
                        Button(action: {
                            shareManager.closePreview()
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16))
                                
                                Text("关闭")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(width: 70, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.gray.opacity(0.8),
                                                Color.gray
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                        }
                    }
                    .padding(.bottom, 40)
                }
                .offset(y: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // 只允许向下拖拽
                            if value.translation.height > 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            // 如果拖拽距离超过阈值则关闭
                            if value.translation.height > 150 {
                                shareManager.closePreview()
                            } else {
                                // 否则回弹
                                withAnimation(.spring()) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
} 