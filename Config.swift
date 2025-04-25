import Foundation

struct Config {
    /// API配置
    struct API {
        #if DEBUG
        // 设置为本地开发服务器地址
        static let baseURL = "http://localhost:8080"
        #else
        static let baseURL = "https://api.dessertrun.com/api/v1"
        #endif
        
        static let timeout: TimeInterval = 30.0
    }
    
    /// 用户数据键值
    struct UserData {
        static let tokenKey = "userToken"
        static let userIdKey = "userId"
    }
    
    /// 应用配置
    struct App {
        static let appName = "甜品跑"
        static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
} 