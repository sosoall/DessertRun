//
//  NotificationExtension.swift
//  DessertRun
//
//  Created by Claude on 2025/4/3.
//

import Foundation
import UserNotifications

// MARK: - 通知中心扩展

extension UNUserNotificationCenter {
    /// 请求通知权限
    /// - Returns: 权限授予状态（true=授予，false=拒绝或受限）
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("通知权限请求失败: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 发送本地通知
    /// - Parameters:
    ///   - title: 通知标题
    ///   - body: 通知内容
    ///   - identifier: 通知唯一标识符
    ///   - delay: 延迟时间（秒）
    ///   - sound: 是否有声音
    ///   - badge: 应用图标显示的数字
    static func scheduleLocalNotification(
        title: String,
        body: String,
        identifier: String = UUID().uuidString,
        delay: TimeInterval = 0,
        sound: Bool = true,
        badge: NSNumber? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        if sound {
            content.sound = .default
        }
        
        if let badge = badge {
            content.badge = badge
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("通知添加失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 取消所有待处理的通知
    static func cancelAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// 取消指定标识符的通知
    /// - Parameter identifiers: 通知标识符数组
    static func cancelNotifications(withIdentifiers identifiers: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
} 