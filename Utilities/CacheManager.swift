import Foundation
import UIKit

/// 全局缓存管理器
class CacheManager {
    static let shared = CacheManager()
    
    private init() {}
    
    /// 清除所有缓存
    /// - Parameter completion: 完成回调
    func clearAllCaches(completion: (() -> Void)? = nil) {
        DRInfo("[CacheManager] 开始清理所有缓存...")
        
        // 1. 清除美食数据缓存
        DessertData.clearCache()
        
        // 2. 清除图片缓存
        ImageCacheService.shared.clearAllCache {
            // 3. 清除URLCache
            URLCache.shared.removeAllCachedResponses()
            
            // 4. 清除UserDefaults中的临时数据（如果有的话）
            // 注意：这里只清除临时数据，不要清除用户数据和认证信息
            self.clearTemporaryUserDefaults()
            
            DRInfo("[CacheManager] 所有缓存已清除")
            completion?()
        }
    }
    
    /// 清除临时UserDefaults数据
    private func clearTemporaryUserDefaults() {
        // 定义需要保留的键
        let keysToKeep = [
            Config.UserData.tokenKey,
            Config.UserData.userIdKey,
            Config.API.environmentKey
            // 添加其他需要保留的键
        ]
        
        // 只清除不在保留列表中的键
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        
        for key in allKeys where !keysToKeep.contains(key) {
            // 检查键是否以特定前缀开头，表示临时数据
            if key.hasPrefix("temp_") || key.hasPrefix("cache_") {
                defaults.removeObject(forKey: key)
                DRDebug("[CacheManager] 清除UserDefaults键: \(key)")
            }
        }
        
        defaults.synchronize()
    }
    
    /// 获取缓存大小
    /// - Parameter completion: 完成回调，返回缓存大小(字节)
    func getCacheSize(completion: @escaping (UInt64) -> Void) {
        var totalSize: UInt64 = 0
        
        let group = DispatchGroup()
        
        // 计算图片缓存大小
        group.enter()
        let workItem = DispatchWorkItem {
            // 由于cacheDirectoryURL是私有的，直接使用已知的缓存路径
            if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let imageCacheURL = documentsURL.appendingPathComponent("ImageCache")
                if FileManager.default.fileExists(atPath: imageCacheURL.path) {
                    totalSize += self.calculateDirectorySize(url: imageCacheURL)
                    DRDebug("[CacheManager] 图片缓存大小: \(self.formatCacheSize(totalSize))")
                }
            }
            group.leave()
        }
        DispatchQueue.global(qos: .utility).async(execute: workItem)
        
        // 计算URLCache大小
        totalSize += UInt64(URLCache.shared.currentDiskUsage)
        
        group.notify(queue: .main) {
            completion(totalSize)
        }
    }
    
    /// 计算目录大小
    private func calculateDirectorySize(url: URL) -> UInt64 {
        let fileManager = FileManager.default
        var size: UInt64 = 0
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            for fileUrl in contents {
                let attributes = try fileManager.attributesOfItem(atPath: fileUrl.path)
                if let fileSize = attributes[.size] as? UInt64 {
                    size += fileSize
                }
            }
        } catch {
            DRError("[CacheManager] 计算目录大小失败: \(error.localizedDescription)")
        }
        
        return size
    }
    
    /// 格式化缓存大小
    /// - Parameter bytes: 字节大小
    /// - Returns: 格式化后的字符串
    func formatCacheSize(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - UIApplication扩展

extension UIApplication {
    /// 添加清除缓存功能到UIApplication
    static func clearAllCaches(completion: (() -> Void)? = nil) {
        CacheManager.shared.clearAllCaches(completion: completion)
    }
    
}

// MARK: - 开发模式扩展

#if DEBUG
extension UIViewController {
    // 添加摇一摇菜单
    override open var canBecomeFirstResponder: Bool {
        return true
    }
    
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            showDevMenu()
        }
        super.motionEnded(motion, with: event)
    }
    
    private func showDevMenu() {
        let alertController = UIAlertController(title: "开发者菜单", message: nil, preferredStyle: .actionSheet)
        
        // 清除缓存选项
        alertController.addAction(UIAlertAction(title: "清除所有缓存", style: .destructive) { _ in
            CacheManager.shared.clearAllCaches {
                let successAlert = UIAlertController(title: "成功", message: "所有缓存已清除", preferredStyle: .alert)
                successAlert.addAction(UIAlertAction(title: "确定", style: .default))
                self.present(successAlert, animated: true)
            }
        })
        
        // 显示缓存大小选项
        alertController.addAction(UIAlertAction(title: "显示缓存大小", style: .default) { _ in
            CacheManager.shared.getCacheSize { size in
                let sizeString = CacheManager.shared.formatCacheSize(size)
                let sizeAlert = UIAlertController(title: "缓存大小", message: "当前缓存大小: \(sizeString)", preferredStyle: .alert)
                sizeAlert.addAction(UIAlertAction(title: "确定", style: .default))
                self.present(sizeAlert, animated: true)
            }
        })
        
        // 切换API环境选项
        alertController.addAction(UIAlertAction(title: "切换API环境", style: .default) { _ in
            self.showEnvironmentSelector()
        })
        
        // 取消选项
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // 在iPad上设置弹出位置
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(alertController, animated: true)
    }
    
    private func showEnvironmentSelector() {
        let alertController = UIAlertController(title: "选择API环境", message: nil, preferredStyle: .actionSheet)
        
        for env in Config.API.ServerEnvironment.allCases {
            let isSelected = Config.API.environment == env
            let title = isSelected ? "✓ \(env.rawValue)" : env.rawValue
            
            alertController.addAction(UIAlertAction(title: title, style: .default) { _ in
                // 切换环境
                if !isSelected {
                    Config.API.environment = env
                    // 清除数据缓存
                    DessertData.clearCache()
                    
                    let successAlert = UIAlertController(title: "成功", message: "API环境已切换到: \(env.rawValue)", preferredStyle: .alert)
                    successAlert.addAction(UIAlertAction(title: "确定", style: .default))
                    self.present(successAlert, animated: true)
                }
            })
        }
        
        // 取消选项
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // 在iPad上设置弹出位置
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(alertController, animated: true)
    }
}
#endif 