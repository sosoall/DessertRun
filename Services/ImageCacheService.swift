import Foundation
import UIKit
import WebKit

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
        guard let _ = URL(string: url) else {
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
            DRError("[ImageCacheService] 无效的URL格式: \(url)")
            completion(nil)
            return
        }
        
        DRInfo("[ImageCacheService] 开始从网络下载图片: \(url)")
        
        // 检查是否是SVG格式的图片（通过URL后缀或类型参数）
        let isSVG = url.lowercased().contains(".svg") || url.lowercased().contains("type=icon") && !url.lowercased().contains(".png")
        if isSVG {
            DRInfo("[ImageCacheService] 检测到SVG图片: \(url)")
        }
        
        // 创建URL请求
        var request = URLRequest(url: imageUrl)
        request.httpMethod = "GET"
        
        // 创建URLSession配置
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpMaximumConnectionsPerHost = 5
        
        // 创建URLSession
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: request) { data, response, error in
            // 检查是否有错误
            if let error = error {
                DRError("[ImageCacheService] 图片下载失败: \(url), 错误: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // 检查是否有数据
            guard let data = data else {
                DRError("[ImageCacheService] 图片下载失败: \(url), 错误: 没有数据")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // 检查响应类型
            var mimeType: String?
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                mimeType = httpResponse.mimeType
                
                // 日志记录响应信息，帮助调试
                if let mimeType = mimeType {
                    DRInfo("[ImageCacheService] 收到图片响应: \(url), 状态码: \(statusCode), MIME类型: \(mimeType), 数据大小: \(data.count)字节")
                }
                
                // 处理不同的响应状态码
                if statusCode < 200 || statusCode >= 300 {
                    DRError("[ImageCacheService] 服务器错误: \(url), 状态码: \(statusCode)")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
            }
            
            // 判断图片格式
            let isPNG = mimeType == "image/png" || url.lowercased().contains(".png")
            let isSVGResponse = mimeType == "image/svg+xml" || (isSVG && !isPNG)
            
            DRInfo("[ImageCacheService] 图片格式: \(isPNG ? "PNG" : isSVGResponse ? "SVG" : "其他格式")")
            
            // 尝试从数据创建图像
            if isSVGResponse {
                // 处理SVG图片
                DRInfo("[ImageCacheService] 处理SVG图片数据: \(url), 大小: \(data.count)字节")
                
                // 使用WebKit渲染SVG
                self.renderSVG(svgData: data, url: url) { renderedImage in
                    if let finalImage = renderedImage {
                        // 缓存图像
                        self.saveImageToCache(finalImage, forKey: cacheKey)
                        
                        DRInfo("[ImageCacheService] 成功渲染和缓存SVG图片: \(url)")
                        completion(finalImage)
                    } else {
                        DRError("[ImageCacheService] SVG渲染失败: \(url)")
                        // 创建备用图标
                        let fallbackImage = self.createFallbackImage()
                        completion(fallbackImage)
                    }
                }
            } else {
                // 处理标准图像格式（包括PNG）
                if let standardImage = UIImage(data: data) {
                    // 缓存图像
                    self.saveImageToCache(standardImage, forKey: cacheKey)
                    
                    DRInfo("[ImageCacheService] 成功下载和缓存\(isPNG ? "PNG" : "标准")图片: \(url)")
                    DispatchQueue.main.async {
                        completion(standardImage)
                    }
                } else {
                    DRError("[ImageCacheService] 无法创建\(isPNG ? "PNG" : "标准")图像: \(url), 数据大小: \(data.count)字节")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }
        }
        
        task.resume()
    }
    
    /// 使用WebKit渲染SVG为图像
    private func renderSVG(svgData: Data, url: String, completion: @escaping (UIImage?) -> Void) {
        // 确保在主线程创建WKWebView
        DispatchQueue.main.async {
            // 使用WKWebView渲染SVG
            let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            webView.isOpaque = false
            webView.backgroundColor = UIColor.clear
            webView.scrollView.isScrollEnabled = false
            
            // 创建SVG内容
            if let svgString = String(data: svgData, encoding: .utf8) {
                DRInfo("[ImageCacheService] SVG内容: \(svgString.prefix(100))...")
                
                // 构建HTML页面，确保SVG缩放适应容器
                let html = """
                <!DOCTYPE html>
                <html>
                <head>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
                    <style>
                        body, html { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; background-color: transparent; }
                        svg { width: 100%; height: 100%; }
                    </style>
                </head>
                <body>
                    \(svgString)
                </body>
                </html>
                """
                
                webView.loadHTMLString(html, baseURL: nil)
                
                // 等待渲染完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // 截取WebView内容
                    UIGraphicsBeginImageContextWithOptions(webView.bounds.size, false, UIScreen.main.scale)
                    webView.drawHierarchy(in: webView.bounds, afterScreenUpdates: true)
                    let image = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    if let finalImage = image {
                        DRInfo("[ImageCacheService] SVG渲染成功: \(url)")
                        completion(finalImage)
                    } else {
                        DRError("[ImageCacheService] SVG渲染失败，无法截取图像: \(url)")
                        completion(nil)
                    }
                }
            } else {
                DRError("[ImageCacheService] 无法将SVG数据转换为字符串: \(url)")
                completion(nil)
            }
        }
    }
    
    /// 创建备用图标
    private func createFallbackImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { ctx in
            // 绘制透明背景
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // 绘制简单的图标
            UIColor.orange.setStroke()
            let rect = CGRect(x: 10, y: 10, width: 80, height: 80)
            ctx.cgContext.setLineWidth(2)
            ctx.cgContext.stroke(rect)
            
            // 显示文本
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.orange,
                .paragraphStyle: paragraphStyle
            ]
            
            "图标加载失败".draw(with: CGRect(x: 0, y: 40, width: 100, height: 20), 
                             options: .usesLineFragmentOrigin, 
                             attributes: attrs, 
                             context: nil)
        }
    }
    
    /// 保存图像到缓存（同时保存到内存和磁盘）
    private func saveImageToCache(_ image: UIImage, forKey key: String) {
        // 保存到内存缓存
        memoryCache.setObject(image, forKey: key as NSString)
        
        // 保存到磁盘缓存
        saveToDisk(image: image, forKey: key)
        
        DRInfo("[ImageCacheService] 图像已缓存, key: \(key)")
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