import SwiftUI
import UIKit
import Photos

/// 分享服务
class ShareService: ObservableObject {
    static let shared = ShareService()
    
    private init() {}
    
    // 这里将添加新的generateVoucherShareImage函数
    
    /// 预缓存图片到URLCache
    /// - Parameter urls: 需要缓存的图片URL列表
    /// - Returns: 是否全部缓存成功
    @MainActor
    private func precacheImages(_ urls: [String]) async -> Bool {
        var allSuccess = true
        
        for urlString in urls {
            guard let url = URL(string: urlString) else {
                allSuccess = false
                continue
            }
            
            do {
                // 检查缓存中是否已有该图片
                let request = URLRequest(url: url)
                if URLCache.shared.cachedResponse(for: request) != nil {
                    continue
                }
                
                // 下载图片数据
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // 验证是否为有效图片
                if UIImage(data: data) != nil {
                    // 手动缓存到URLCache
                    let cachedResponse = CachedURLResponse(response: response, data: data)
                    URLCache.shared.storeCachedResponse(cachedResponse, for: request)
                } else {
                    allSuccess = false
                }
            } catch {
                allSuccess = false
            }
        }
        
        return allSuccess
    }
    
    /// 生成美食券分享图片
    /// - Parameters:
    ///   - voucher: 美食券
    ///   - userId: 分享用户ID（用于邀请链接）
    /// - Returns: 生成的图片
    @MainActor
    func generateVoucherShareImage(voucher: DessertVoucher, userId: String) async -> UIImage? {
        // 预缓存所有图片
        var imagesToCache: [String] = []
        
        if let voucherImageURL = voucher.displayVoucherImageURL, !voucherImageURL.isEmpty {
            imagesToCache.append(voucherImageURL)
        }
        
        if let iconURL = voucher.displayDessertIconURL, !iconURL.isEmpty {
            imagesToCache.append(iconURL)
        }
        
        if !imagesToCache.isEmpty {
            await precacheImages(imagesToCache)
        }
        
        // 构建分享链接和消息
        let shareURL = buildShareURL(voucherId: voucher.id, inviteUserId: userId)
        let shareMessage = buildShareMessage(voucher: voucher)
        
        // 创建分享视图
        let shareView = ShareableVoucherView(
            voucher: voucher,
            qrCodeData: shareURL,
            shareMessage: shareMessage
        )
        
        // 创建ImageRenderer
        let renderer = ImageRenderer(content: shareView)
        renderer.scale = 3.0
        renderer.isOpaque = true
        
        // 触发视图初始化
        _ = renderer.uiImage
        
        // 给视图一点时间开始加载
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
        
        // 使用基于通知的等待机制
        return await withCheckedContinuation { continuation in
            let notificationName = "ShareContentReady_\(voucher.id)"
            var observer: NSObjectProtocol?
            var timeoutTimer: Timer?
            var isCompleted = false
            
            // 设置通知监听器
            observer = NotificationCenter.default.addObserver(
                forName: NSNotification.Name(notificationName),
                object: nil,
                queue: .main
            ) { _ in
                guard !isCompleted else { return }
                isCompleted = true
                
                // 移除观察者和计时器
                if let obs = observer {
                    NotificationCenter.default.removeObserver(obs)
                }
                timeoutTimer?.invalidate()
                
                // 执行截图
                let image = renderer.uiImage
                continuation.resume(returning: image)
            }
            
            // 设置超时计时器（5秒）
            timeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                guard !isCompleted else { return }
                isCompleted = true
                
                // 移除观察者
                if let obs = observer {
                    NotificationCenter.default.removeObserver(obs)
                }
                
                // 超时后直接截图
                let image = renderer.uiImage
                continuation.resume(returning: image)
            }
        }
    }
    
    /// 验证生成的图片是否有效（包含实际内容）
    /// - Parameter image: 生成的图片
    /// - Returns: 是否为有效的分享图片
    private func isValidShareImage(_ image: UIImage) -> Bool {
        // 检查图片尺寸
        let size = image.size
        let expectedSize = CGSize(width: 340, height: 500)
        
        // 允许一定的尺寸误差
        let sizeValid = abs(size.width - expectedSize.width) < 50 && 
                       abs(size.height - expectedSize.height) < 50
        
        if !sizeValid {
            return false
        }
        
        // 检查图片是否为纯色（可能是占位符）
        guard let cgImage = image.cgImage else {
            return false
        }
        
        return true
    }
    
    /// 构建分享URL
    /// - Parameters:
    ///   - voucherId: 美食券ID
    ///   - inviteUserId: 邀请用户ID
    /// - Returns: 分享链接
    private func buildShareURL(voucherId: String, inviteUserId: String) -> String {
        // 这里使用你的域名，如果还没有域名可以先用placeholder
        let baseURL = "https://dessertrun.app"
        return "\(baseURL)/share/voucher/\(voucherId)?invite=\(inviteUserId)&utm_source=share&utm_medium=voucher"
    }
    
    /// 构建分享消息
    /// - Parameter voucher: 美食券
    /// - Returns: 分享消息文本
    private func buildShareMessage(voucher: DessertVoucher) -> String {
        // 检查甜品信息
        guard let dessertName = voucher.dessertName else {
            DRError("美食券缺少甜品信息")
            return ""
        }
        return "我刚刚通过运动获得了\(dessertName)美食券！一起来体验该吃吃吧~ #该吃吃 #运动换美食"
    }
    
    /// 分享图片到系统分享面板
    /// - Parameters:
    ///   - image: 要分享的图片
    ///   - text: 分享文本
    ///   - sourceView: 分享按钮的视图（用于iPad的popover定位）
    func shareImage(_ image: UIImage, text: String, from sourceView: UIView?) {
        let activityVC = UIActivityViewController(
            activityItems: [image, text],
            applicationActivities: nil
        )
        
        // iPad适配
        if let popover = activityVC.popoverPresentationController {
            if let sourceView = sourceView {
                popover.sourceView = sourceView
                popover.sourceRect = sourceView.bounds
            } else {
                // 如果没有sourceView，使用屏幕中心
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    popover.sourceView = window
                    popover.sourceRect = CGRect(
                        x: window.bounds.midX,
                        y: window.bounds.midY,
                        width: 0,
                        height: 0
                    )
                }
            }
        }
        
        // 获取当前顶层视图控制器
        if let topVC = getTopViewController() {
            topVC.present(activityVC, animated: true)
        }
    }
    
    /// 保存图片到相册（带权限检查）
    /// - Parameter image: 要保存的图片
    func saveImageToPhotos(_ image: UIImage, completion: @escaping (Bool, String?) -> Void) {
        // 检查相册权限
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    // 有权限，保存图片
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }) { success, error in
                        DispatchQueue.main.async {
                            if success {
                                completion(true, "图片已保存到相册")
                            } else {
                                completion(false, "保存失败: \(error?.localizedDescription ?? "未知错误")")
                            }
                        }
                    }
                case .denied, .restricted:
                    completion(false, "需要相册权限才能保存图片，请在设置中开启")
                case .notDetermined:
                    completion(false, "权限未确定")
                @unknown default:
                    completion(false, "未知权限状态")
                }
            }
        }
    }
    
    /// 获取当前顶层视图控制器
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        var topVC = window.rootViewController
        while let presentedVC = topVC?.presentedViewController {
            topVC = presentedVC
        }
        
        return topVC
    }
}

/// 分享状态管理
class ShareState: ObservableObject {
    @Published var isGenerating = false
    @Published var generatedImage: UIImage?
    @Published var shareError: String?
    
    /// 重置状态
    func reset() {
        isGenerating = false
        generatedImage = nil
        shareError = nil
    }
} 