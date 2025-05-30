import SwiftUI

// 进度节点数据结构
struct ProgressNode {
    let title: String
    let isCompleted: Bool
    let isInProgress: Bool
}

/// 挑战进度视图组件
struct ChallengeProgressView: View {
    let isEnrolled: Bool
    let progressResponse: ChallengeProgressResponse?
    let selectedChallenge: ChallengeActivity?
    let currentEnrollment: EnrollmentWithChallengeDetail?
    
    // 添加刷新状态
    @State private var refreshTrigger = UUID()
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                getProgressIcon()
                Text(getProgressTitle())
                    .font(getProgressTitleFont())
                    .foregroundColor(getProgressTitleColor())
                Spacer()
            }
            
            // 节点进度条
            progressNodeView()
            
            // 进度文本
            if let progressText = getProgressText() {
                Text(progressText)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ChallengeProgressUpdated"))) { _ in
            // 收到更新通知时触发重新渲染
            refreshTrigger = UUID()
            DRInfo("[ChallengeProgressView] 收到挑战进度更新通知，刷新显示")
        }
        .id(refreshTrigger) // 添加id以确保重新渲染
    }
    
    // MARK: - 辅助方法
    
    // 获取进度图标
    private func getProgressIcon() -> some View {
        let iconName: String
        let color: Color
        
        if !isEnrolled {
            iconName = "chart.line.uptrend.xyaxis"
            color = Color(hex: "FE2D55")
        } else {
            let statusString = getCurrentStatusString()
            switch statusString {
            case "ongoing":
                iconName = "flame.fill"
                color = Color(hex: "4CAF50") // 绿色，与已报名tag统一
            case "completed":
                iconName = "crown.fill"
                color = Color(hex: "FF9500") // 橙色，更清楚可见
            case "failed":
                iconName = "arrow.counterclockwise"
                color = Color(hex: "FE2D55")
            default:
                iconName = "chart.line.uptrend.xyaxis"
                color = Color(hex: "FE2D55")
            }
        }
        
        return Image(systemName: iconName)
            .font(.system(size: 20))
            .foregroundColor(color)
    }
    
    // 获取进度标题
    private func getProgressTitle() -> String {
        if !isEnrolled {
            return "如何完成挑战"
        } else {
            let statusString = getCurrentStatusString()
            switch statusString {
            case "ongoing":
                return "已报名挑战，去运动吧！"
            case "completed":
                return "恭喜已完成挑战！"
            case "failed":
                return "谢谢参与活动！可重新挑战"
            default:
                return "挑战进度"
            }
        }
    }
    
    // 获取进度标题字体
    private func getProgressTitleFont() -> Font {
        return .system(size: 20, weight: .semibold)
    }
    
    // 获取进度标题颜色
    private func getProgressTitleColor() -> Color {
        return .black
    }
    
    // 获取当前状态字符串
    private func getCurrentStatusString() -> String {
        if let progressResponse = progressResponse {
            return progressResponse.enrollment.status.rawValue
        } else if let enrollment = currentEnrollment {
            switch enrollment.enrollment.enrollmentStatus {
            case .ongoing:
                return "ongoing"
            case .completed:
                return "completed"
            case .failed:
                return "failed"
            }
        } else {
            return "ongoing"
        }
    }
    
    // 节点进度条视图
    private func progressNodeView() -> some View {
        let nodes = getProgressNodes()
        
        return VStack(spacing: 16) {
            // 使用GeometryReader确保精确对齐
            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                let nodeCount = nodes.count
                let spacing = totalWidth / CGFloat(nodeCount)
                
                ZStack(alignment: .leading) {
                    // 背景连接线
                    HStack(spacing: 0) {
                        Spacer()
                            .frame(width: spacing * 0.2) // 左边留20%距离
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 2)
                        
                        Spacer()
                            .frame(width: spacing * 0.2) // 右边留20%距离
                    }
                    
                    // 节点
                    HStack(spacing: 0) {
                        ForEach(0..<nodes.count, id: \.self) { index in
                            ZStack {
                                // 实际显示的圆圈
                                if nodes[index].isCompleted {
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 28, height: 28)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                } else if nodes[index].isInProgress {
                                    // 进行中的节点 - 白色背景遮挡线条
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 24, height: 24)
                                    
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 20, height: 20)
                                } else {
                                    // 未完成的节点 - 白色背景遮挡线条
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 24, height: 24)
                                    
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 20, height: 20)
                                }
                            }
                            .frame(width: spacing, height: 28) // 每个节点占用相同宽度
                            
                            if index < nodes.count - 1 {
                                // 这里不需要连接线，因为背景已经有了
                            }
                        }
                    }
                }
            }
            .frame(height: 28)
            
            // 节点标签 - 使用相同的布局确保对齐
            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                let nodeCount = nodes.count
                let spacing = totalWidth / CGFloat(nodeCount)
                
                HStack(spacing: 0) {
                    ForEach(0..<nodes.count, id: \.self) { index in
                        Text(nodes[index].title)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(width: spacing, height: 32) // 与节点使用相同的宽度
                    }
                }
            }
            .frame(height: 32)
        }
        .frame(height: 76) // 28 + 16 + 32 = 76
    }
    
    // 获取进度节点数据
    private func getProgressNodes() -> [ProgressNode] {
        let statusString = getCurrentStatusString()
        let completedCheckins = progressResponse?.enrollment.completedCheckins ?? 0
        let requiredCheckins = selectedChallenge?.requiredCheckins ?? 3
        
        if statusString == "failed" {
            return [
                ProgressNode(title: "挑战活动\n已过期", isCompleted: true, isInProgress: false),
                ProgressNode(title: "重新参加\n挑战", isCompleted: false, isInProgress: false)
            ]
        } else if !isEnrolled {
            return [
                ProgressNode(title: "报名\n比赛", isCompleted: false, isInProgress: false),
                ProgressNode(title: "发放\n任务卡", isCompleted: false, isInProgress: false),
                ProgressNode(title: "完成\n任务", isCompleted: false, isInProgress: false),
                ProgressNode(title: "发放\n奖励", isCompleted: false, isInProgress: false)
            ]
        } else {
            let taskTitle = completedCheckins < requiredCheckins ? 
                "已完成\n\(completedCheckins)/\(requiredCheckins)次任务" : 
                "完成\n任务"
            
            switch statusString {
            case "ongoing":
                if completedCheckins == 0 {
                    return [
                        ProgressNode(title: "报名\n比赛", isCompleted: true, isInProgress: false),
                        ProgressNode(title: "发放\n任务卡", isCompleted: true, isInProgress: false),
                        ProgressNode(title: taskTitle, isCompleted: false, isInProgress: true),
                        ProgressNode(title: "发放\n奖励", isCompleted: false, isInProgress: false)
                    ]
                } else if completedCheckins < requiredCheckins {
                    return [
                        ProgressNode(title: "报名\n比赛", isCompleted: true, isInProgress: false),
                        ProgressNode(title: "发放\n任务卡", isCompleted: true, isInProgress: false),
                        ProgressNode(title: taskTitle, isCompleted: false, isInProgress: true),
                        ProgressNode(title: "发放\n奖励", isCompleted: false, isInProgress: false)
                    ]
                } else {
                    return [
                        ProgressNode(title: "报名\n比赛", isCompleted: true, isInProgress: false),
                        ProgressNode(title: "发放\n任务卡", isCompleted: true, isInProgress: false),
                        ProgressNode(title: taskTitle, isCompleted: true, isInProgress: false),
                        ProgressNode(title: "发放\n奖励", isCompleted: false, isInProgress: true)
                    ]
                }
            case "completed":
                return [
                    ProgressNode(title: "报名\n比赛", isCompleted: true, isInProgress: false),
                    ProgressNode(title: "发放\n任务卡", isCompleted: true, isInProgress: false),
                    ProgressNode(title: taskTitle, isCompleted: true, isInProgress: false),
                    ProgressNode(title: "发放\n奖励", isCompleted: true, isInProgress: false)
                ]
            default:
                return [
                    ProgressNode(title: "报名\n比赛", isCompleted: true, isInProgress: false),
                    ProgressNode(title: "发放\n任务卡", isCompleted: true, isInProgress: false),
                    ProgressNode(title: taskTitle, isCompleted: false, isInProgress: true),
                    ProgressNode(title: "发放\n奖励", isCompleted: false, isInProgress: false)
                ]
            }
        }
    }
    
    // 获取进度文本
    private func getProgressText() -> String? {
        if !isEnrolled {
            return nil
        }
        
        let statusString = getCurrentStatusString()
        let completedCheckins = progressResponse?.enrollment.completedCheckins ?? 0
        let requiredCheckins = selectedChallenge?.requiredCheckins ?? 3
        let remainingDays = progressResponse?.remainingDays ?? 0
        
        switch statusString {
        case "ongoing":
            return "剩余天数：\(remainingDays)天"            
        case "completed":
            return "已获得所有奖励"
        case "failed":
            return "可以重新参加新的挑战"
        default:
            return "剩余天数：\(remainingDays)天"
        }
    }
}

#Preview {
    ChallengeProgressView(
        isEnrolled: true,
        progressResponse: nil,
        selectedChallenge: nil,
        currentEnrollment: nil
    )
} 