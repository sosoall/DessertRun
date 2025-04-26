import Foundation

struct Config {
    /// API配置
    struct API {
        enum ServerEnvironment: String, CaseIterable {
            case local = "本地服务器"
            case device = "外部设备测试"
            case production = "生产环境"
            
            var baseURL: String {
                switch self {
                case .local:
                    return "http://localhost:8080"
                case .device:
                    // 这里应该设置为开发电脑的IP地址，比如192.168.1.100
                    // 注意：请替换为你的电脑的实际IP地址
                    return "http://192.168.1.100:8080"
                case .production:
                    return "https://api.dessertrun.com/api/v1"
                }
            }
        }
        
        // 默认环境
        static var environment: ServerEnvironment {
            get {
                if let savedValue = UserDefaults.standard.string(forKey: "api_environment"),
                   let env = ServerEnvironment(rawValue: savedValue) {
                    return env
                }
                #if DEBUG
                return .local
                #else
                return .production
                #endif
            }
            set {
                UserDefaults.standard.set(newValue.rawValue, forKey: "api_environment")
            }
        }
        
        // 动态获取baseURL，方便切换环境
        static var baseURL: String {
            return environment.baseURL
        }
        
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