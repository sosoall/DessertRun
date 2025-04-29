import Foundation
import UIKit

/// 图片缓存服务，用于下载、缓存和管理图片
class ImageCacheService {
    static let shared = ImageCacheService()
    
    // 内存缓存
    private let memoryCache = NSCache<NSString, UIImage>()
    // 文件管理器
    private let fileManager = FileManager.default
    // 操作队列
    private let downloadQueue = DispatchQueue(label: "com.dessertrun.imagecache", qos: .utility, attributes: .concurrent)
    
    private init() {
        // 设置内存缓存限制
        memoryCache.countLimit = 100 // 最多缓存100张图片
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // 创建缓存目录
        createCacheDirectoryIfNeeded()
        
        // 添加内存警告通知
        NotificationCenter.default.addObserver(self, selector: #selector(clearMemoryCache), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        
        DRInfo("[ImageCacheService] 初始化完成")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    /// 下载并缓存图片
    /// - Parameters:
    ///   - url: 图片URL字符串
    ///   - completion: 完成回调，返回下载的图片
    func downloadAndCacheImage(url: String, completion: @escaping (UIImage?) -> Void) {
        guard let imageUrl = URL(string: url) else {
            DRError("[ImageCacheService] 无效的图片URL: \(url)")
            completion(nil)
            return
        }
        
        let cacheKey = getCacheKey(from: url)
        
        // 1. 检查内存缓存
        if let cachedImage = memoryCache.object(forKey: cacheKey as NSString) {
            DRDebug("[ImageCacheService] 从内存缓存中获取图片: \(url)")
            completion(cachedImage)
            return
        }
        
        // 2. 检查磁盘缓存
        let diskCachePath = getCachePath(for: cacheKey)
        if fileManager.fileExists(atPath: diskCachePath.path) {
            downloadQueue.async {
                if let diskCachedImage = UIImage(contentsOfFile: diskCachePath.path) {
                    DRDebug("[ImageCacheService] 从磁盘缓存中获取图片: \(url)")
                    // 保存到内存缓存
                    self.memoryCache.setObject(diskCachedImage, forKey: cacheKey as NSString)
                    
                    DispatchQueue.main.async {
                        completion(diskCachedImage)
                    }
                } else {
                    DRWarning("[ImageCacheService] 磁盘缓存的图片无法加载: \(url)")
                    self.downloadImageFromNetwork(url: url, cacheKey: cacheKey, completion: completion)
                }
            }
            return
        }
        
        // 3. 从网络下载
        downloadImageFromNetwork(url: url, cacheKey: cacheKey, completion: completion)
    }
    
    /// 从网络下载图片
    private func downloadImageFromNetwork(url: String, cacheKey: String, completion: @escaping (UIImage?) -> Void) {
        guard let imageUrl = URL(string: url) else {
            completion(nil)
            return
        }
        
        DRInfo("[ImageCacheService] 开始从网络下载图片: \(url)")
        
        URLSession.shared.dataTask(with: imageUrl) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let image = UIImage(data: data),
                  error == nil else {
                DispatchQueue.main.async {
                    DRError("[ImageCacheService] 图片下载失败: \(url), 错误: \(error?.localizedDescription ?? "未知错误")")
                    completion(nil)
                }
                return
            }
            
            DRDebug("[ImageCacheService] 图片下载成功: \(url)")
            
            // 保存到内存缓存
            self.memoryCache.setObject(image, forKey: cacheKey as NSString)
            
            // 保存到磁盘缓存
            self.saveToDisk(image: image, forKey: cacheKey)
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
    /// 保存图片到磁盘
    private func saveToDisk(image: UIImage, forKey key: String) {
        let diskCachePath = getCachePath(for: key)
        downloadQueue.async {
            if let data = image.jpegData(compressionQuality: 0.8) {
                do {
                    try data.write(to: diskCachePath)
                    DRDebug("[ImageCacheService] 图片保存到磁盘: \(key)")
                } catch {
                    DRError("[ImageCacheService] 图片保存到磁盘失败: \(key), 错误: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// 清除内存缓存
    @objc func clearMemoryCache() {
        DRInfo("[ImageCacheService] 清除内存缓存")
        memoryCache.removeAllObjects()
    }
    
    /// 清除磁盘缓存
    func clearDiskCache(completion: (() -> Void)? = nil) {
        downloadQueue.async {
            guard let cacheURL = self.cacheDirectoryURL() else {
                DispatchQueue.main.async {
                    completion?()
                }
                return
            }
            
            do {
                let fileURLs = try self.fileManager.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil, options: [])
                for fileURL in fileURLs {
                    try self.fileManager.removeItem(at: fileURL)
                }
                DRInfo("[ImageCacheService] 清除磁盘缓存成功")
            } catch {
                DRError("[ImageCacheService] 清除磁盘缓存失败: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    /// 清除所有缓存
    func clearAllCache(completion: (() -> Void)? = nil) {
        clearMemoryCache()
        clearDiskCache(completion: completion)
    }
    
    /// 创建缓存目录
    private func createCacheDirectoryIfNeeded() {
        guard let cacheURL = cacheDirectoryURL() else { return }
        
        if !fileManager.fileExists(atPath: cacheURL.path) {
            do {
                try fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true, attributes: nil)
                DRInfo("[ImageCacheService] 创建缓存目录: \(cacheURL.path)")
            } catch {
                DRError("[ImageCacheService] 创建缓存目录失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 获取缓存目录URL
    private func cacheDirectoryURL() -> URL? {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent("ImageCache")
    }
    
    /// 获取图片缓存路径
    private func getCachePath(for key: String) -> URL {
        guard let cacheURL = cacheDirectoryURL() else {
            // 如果无法获取缓存目录，使用临时目录
            return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(key)
        }
        return cacheURL.appendingPathComponent(key)
    }
    
    /// 从URL获取缓存键
    private func getCacheKey(from url: String) -> String {
        // 将URL哈希为一个文件名安全的字符串
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var result = ""
        
        for char in url {
            if characters.contains(char) {
                result.append(char)
            }
        }
        
        if result.isEmpty {
            return url.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
        }
        
        // 如果转换后的字符串太长，使用哈希值
        if result.count > 50 {
            result = "\(result.prefix(15))_\(url.hashValue.magnitude)"
        }
        
        return result
    }
} 