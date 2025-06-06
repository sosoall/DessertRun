import Foundation
import UIKit
import Combine

/// Universal Link 处理器
class UniversalLinkHandler: ObservableObject {
    static let shared = UniversalLinkHandler()
    
    @Published var pendingInviteLink: InviteLinkData?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    /// 处理Universal Link
    /// - Parameter url: 传入的URL
    /// - Returns: 是否成功处理
    func handleUniversalLink(_ url: URL) -> Bool {
        DRInfo("处理Universal Link: \(url.absoluteString)")
        
        // 解析URL组件
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            DRError("无法解析URL组件")
            return false
        }
        
        // 检查路径
        let path = url.path
        
        if path.hasPrefix("/share/voucher/") {
            return handleVoucherShare(url: url, components: components)
        } else if path.hasPrefix("/invite/") {
            return handleInviteLink(url: url, components: components)
        }
        
        DRError("未知的Universal Link路径: \(path)")
        return false
    }
    
    /// 处理美食券分享链接
    /// - Parameters:
    ///   - url: 原始URL
    ///   - components: URL组件
    /// - Returns: 是否成功处理
    private func handleVoucherShare(url: URL, components: URLComponents) -> Bool {
        // 提取美食券ID
        let pathComponents = url.path.components(separatedBy: "/")
        guard pathComponents.count >= 4,
              pathComponents[1] == "share",
              pathComponents[2] == "voucher" else {
            DRError("美食券分享链接格式错误")
            return false
        }
        
        let voucherId = pathComponents[3]
        
        // 提取查询参数
        let queryItems = components.queryItems ?? []
        let inviteUserId = queryItems.first(where: { $0.name == "invite" })?.value
        let utmSource = queryItems.first(where: { $0.name == "utm_source" })?.value
        let utmMedium = queryItems.first(where: { $0.name == "utm_medium" })?.value
        
        DRInfo("处理美食券分享: voucherId=\(voucherId), inviteUserId=\(inviteUserId ?? "无")")
        
        // 创建邀请链接数据
        let inviteData = InviteLinkData(
            type: .voucherShare,
            voucherId: voucherId,
            inviteUserId: inviteUserId,
            utmSource: utmSource ?? "share",
            utmMedium: utmMedium ?? "voucher"
        )
        
        // 处理邀请逻辑
        processInviteLink(inviteData)
        
        return true
    }
    
    /// 处理邀请链接
    /// - Parameters:
    ///   - url: 原始URL
    ///   - components: URL组件
    /// - Returns: 是否成功处理
    private func handleInviteLink(url: URL, components: URLComponents) -> Bool {
        // 提取邀请码
        let pathComponents = url.path.components(separatedBy: "/")
        guard pathComponents.count >= 3,
              pathComponents[1] == "invite" else {
            DRError("邀请链接格式错误")
            return false
        }
        
        let inviteCode = pathComponents[2]
        
        // 提取查询参数
        let queryItems = components.queryItems ?? []
        let utmSource = queryItems.first(where: { $0.name == "utm_source" })?.value
        let utmMedium = queryItems.first(where: { $0.name == "utm_medium" })?.value
        
        DRInfo("处理邀请链接: inviteCode=\(inviteCode)")
        
        // 创建邀请链接数据
        let inviteData = InviteLinkData(
            type: .directInvite,
            inviteCode: inviteCode,
            utmSource: utmSource ?? "invite",
            utmMedium: utmMedium ?? "link"
        )
        
        // 处理邀请逻辑
        processInviteLink(inviteData)
        
        return true
    }
    
    /// 处理邀请链接逻辑
    /// - Parameter inviteData: 邀请数据
    private func processInviteLink(_ inviteData: InviteLinkData) {
        // 检查用户是否已登录
        if AuthService.shared.isLoggedIn {
            // 已登录用户，直接处理邀请关系
            processInviteForLoggedInUser(inviteData)
        } else {
            // 未登录用户，保存邀请信息，等待登录后处理
            pendingInviteLink = inviteData
            DRInfo("用户未登录，保存邀请信息等待登录后处理")
        }
        
        // 记录用户来源
        trackUserSource(inviteData)
    }
    
    /// 为已登录用户处理邀请
    /// - Parameter inviteData: 邀请数据
    private func processInviteForLoggedInUser(_ inviteData: InviteLinkData) {
        guard let currentUser = AuthService.shared.currentUser else {
            DRError("获取当前用户失败")
            return
        }
        
        // 检查是否为自己的邀请链接
        if let inviteUserId = inviteData.inviteUserId,
           inviteUserId == currentUser.id.uuidString {
            DRInfo("用户点击了自己的邀请链接，不处理")
            return
        }
        
        // 调用后端API建立邀请关系
        APIService.shared.processInviteLink(inviteData: inviteData)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        DRError("处理邀请链接失败: \(error.errorMessage)")
                    }
                },
                receiveValue: { response in
                    DRInfo("邀请关系建立成功: \(response)")
                    // 可以在这里显示邀请成功的提示
                    self.showInviteSuccessMessage(response)
                }
            )
            .store(in: &cancellables)
    }
    
    /// 处理待处理的邀请链接（用户登录后调用）
    func processPendingInviteLink() {
        guard let inviteData = pendingInviteLink else { return }
        
        DRInfo("处理用户登录后的待处理邀请链接")
        processInviteForLoggedInUser(inviteData)
        
        // 清除待处理的邀请信息
        pendingInviteLink = nil
    }
    
    /// 记录用户来源
    /// - Parameter inviteData: 邀请数据
    private func trackUserSource(_ inviteData: InviteLinkData) {
        // 构建来源信息
        let sourceInfo = UserSourceInfo(
            sourceType: inviteData.utmSource,
            referrerUserId: inviteData.inviteUserId,
            campaign: inviteData.utmMedium,
            timestamp: Date()
        )
        
        // 保存到本地，等待用户注册时上报
        UserDefaults.standard.set(try? JSONEncoder().encode(sourceInfo), forKey: "user_source_info")
        
        DRInfo("记录用户来源信息: \(sourceInfo)")
    }
    
    /// 显示邀请成功消息
    /// - Parameter response: 邀请响应
    private func showInviteSuccessMessage(_ response: InviteResponse) {
        // 这里可以显示一个Toast或Alert
        // 暂时使用日志输出
        DRInfo("邀请奖励获得：\(response.message)")
    }
}

/// 邀请链接数据
struct InviteLinkData {
    let type: InviteLinkType
    let voucherId: String?
    let inviteCode: String?
    let inviteUserId: String?
    let utmSource: String
    let utmMedium: String
    
    init(type: InviteLinkType, voucherId: String? = nil, inviteCode: String? = nil, inviteUserId: String? = nil, utmSource: String, utmMedium: String) {
        self.type = type
        self.voucherId = voucherId
        self.inviteCode = inviteCode
        self.inviteUserId = inviteUserId
        self.utmSource = utmSource
        self.utmMedium = utmMedium
    }
}

/// 邀请链接类型
enum InviteLinkType {
    case voucherShare  // 美食券分享
    case directInvite  // 直接邀请
}

/// 用户来源信息
struct UserSourceInfo: Codable {
    let sourceType: String
    let referrerUserId: String?
    let campaign: String
    let timestamp: Date
}

/// 邀请响应
struct InviteResponse: Codable {
    let success: Bool
    let message: String
    let rewardPoints: Int?
} 