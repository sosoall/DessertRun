import Foundation

struct Config {
    /// API配置
    struct API {
        // 环境设置的UserDefaults键
        static let environmentKey = "api_environment"
        
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
                    return "http://172.20.10.3:8080"
                case .production:
                    return "https://api.dessertrun.com/api/v1"
                }
            }
        }
        
        // 默认环境
        static var environment: ServerEnvironment {
            get {
                // 确保立即读取最新值
                UserDefaults.standard.synchronize()
                
                if let savedValue = UserDefaults.standard.string(forKey: environmentKey),
                   let env = ServerEnvironment(rawValue: savedValue) {
                    print("加载保存的环境设置: \(env.rawValue) - \(env.baseURL)")
                    return env
                }
                
                // 如果没有保存值，设置默认值
                #if DEBUG
                let defaultEnv = ServerEnvironment.device // 在手机设备上默认使用外部设备测试地址
                #else
                let defaultEnv = ServerEnvironment.production
                #endif
                
                // 保存默认值
                UserDefaults.standard.set(defaultEnv.rawValue, forKey: environmentKey)
                UserDefaults.standard.synchronize()
                print("设置默认环境: \(defaultEnv.rawValue) - \(defaultEnv.baseURL)")
                return defaultEnv
            }
            set {
                print("保存环境设置: \(newValue.rawValue) - \(newValue.baseURL)")
                UserDefaults.standard.set(newValue.rawValue, forKey: environmentKey)
                UserDefaults.standard.synchronize()
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