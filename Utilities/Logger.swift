import Foundation
import OSLog

/// 日志级别
enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
    
    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        case .critical:
            return .fault
        }
    }
}

/// 简单日志系统
class Logger {
    static let shared = Logger()
    
    private let log: OSLog
    private let fileLogger: FileLogger
    
    private init() {
        self.log = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.dessertrun.app", category: "DessertRun")
        self.fileLogger = FileLogger()
    }
    
    /// 写入日志
    /// - Parameters:
    ///   - message: 日志消息
    ///   - level: 日志级别
    ///   - file: 源文件
    ///   - function: 函数名
    ///   - line: 行号
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        // 构建完整日志消息
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(level.rawValue)] [\(fileName):\(line)] \(function): \(message)"
        
        // 输出到控制台
        os_log("%{public}@", log: log, type: level.osLogType, logMessage)
        
        // 写入文件
        fileLogger.log(logMessage)
    }
    
    /// 调试级别日志
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    /// 信息级别日志
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    /// 警告级别日志
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    /// 错误级别日志
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    /// 致命错误级别日志
    func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .critical, file: file, function: function, line: line)
    }
}

/// 文件日志记录器
class FileLogger {
    private let fileManager = FileManager.default
    private let logFileName = "dessertrun.log"
    private let dateFormatter: DateFormatter
    private let queue = DispatchQueue(label: "com.dessertrun.filelogger")
    
    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        // 确保日志目录存在
        createLogDirectoryIfNeeded()
    }
    
    /// 确保日志目录存在
    private func createLogDirectoryIfNeeded() {
        guard let logDirectoryURL = logDirectoryURL() else { return }
        
        if !fileManager.fileExists(atPath: logDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: logDirectoryURL, withIntermediateDirectories: true)
            } catch {
                print("创建日志目录失败: \(error)")
            }
        }
    }
    
    /// 获取日志文件URL
    private func logFileURL() -> URL? {
        guard let logDirectoryURL = logDirectoryURL() else { return nil }
        return logDirectoryURL.appendingPathComponent(logFileName)
    }
    
    /// 获取日志目录URL
    private func logDirectoryURL() -> URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent("Logs")
    }
    
    /// 写入日志到文件
    /// - Parameter message: 日志消息
    func log(_ message: String) {
        queue.async { [weak self] in
            guard let self = self, let fileURL = self.logFileURL() else { return }
            
            let timestamp = self.dateFormatter.string(from: Date())
            let logLine = "\(timestamp) \(message)\n"
            
            if self.fileManager.fileExists(atPath: fileURL.path) {
                // 追加到现有文件
                if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                    fileHandle.seekToEndOfFile()
                    if let data = logLine.data(using: .utf8) {
                        fileHandle.write(data)
                    }
                    fileHandle.closeFile()
                }
            } else {
                // 创建新文件
                try? logLine.data(using: .utf8)?.write(to: fileURL, options: .atomicWrite)
            }
        }
    }
}

// 便捷全局访问
func DRLog(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.log(message, level: level, file: file, function: function, line: line)
}

func DRDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.debug(message, file: file, function: function, line: line)
}

func DRInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.info(message, file: file, function: function, line: line)
}

func DRWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.warning(message, file: file, function: function, line: line)
}

func DRError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(message, file: file, function: function, line: line)
}

func DRCritical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.critical(message, file: file, function: function, line: line)
} 