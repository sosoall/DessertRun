import SwiftUI

/// 运动打卡引导进度条
/// 用于显示运动打卡的3个步骤进度：选择美食目标 -> 选择运动类型 -> 完成运动
struct WorkoutProgressIndicator: View {
    /// 当前步骤 (1: 选择美食目标, 2: 选择运动类型, 3: 完成运动)
    let currentStep: Int
    
    /// 进度步骤定义
    private let steps = [
        (title: "享受美食", step: 1),
        (title: "运动消耗", step: 2),
        (title: "热量归零！", step: 3)
    ]
    
    var body: some View {
        VStack(spacing: 3) {
            // 使用GeometryReader确保精确对齐
            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                let nodeCount = steps.count
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
                    
                    // 步骤圆圈
                    HStack(spacing: 0) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            let step = steps[index]
                            let isCompleted = step.step < currentStep
                            let isCurrent = step.step == currentStep
                            
                            ZStack {
                                // 实际显示的圆圈
                                if isCompleted {
                                    Circle()
                                        .fill(Color(hex: "FE2D55"))
                                        .frame(width: 24, height: 24)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                } else if isCurrent {
                                    // 当前步骤 - 白色背景遮挡线条
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 26, height: 26)
                                    
                                    Circle()
                                        .fill(Color(hex: "FE2D55"))
                                        .frame(width: 24, height: 24)
                                    
                                    Text("\(step.step)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    // 未完成的节点 - 白色背景遮挡线条
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 26, height: 26)
                                    
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 24, height: 24)
                                    
                                    Text("\(step.step)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(width: spacing, height: 26) // 每个节点占用相同宽度
                        }
                    }
                }
            }
            .frame(height: 26)
            
            // 步骤标题 - 使用相同的布局确保对齐
            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                let nodeCount = steps.count
                let spacing = totalWidth / CGFloat(nodeCount)
                
                HStack(spacing: 0) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        let step = steps[index]
                        let isCompleted = step.step < currentStep
                        let isCurrent = step.step == currentStep
                        
                        Text(step.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(isCompleted || isCurrent ? Color(hex: "FE2D55") : Color.gray)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(width: spacing, height: 24) // 减少文字区域高度
                    }
                }
            }
            .frame(height: 24) // 减少文字区域高度
        }
        .frame(height: 53) // 26 + 3 + 24 = 53，减少总高度
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
    }
}

// MARK: - 预览
#Preview {
    VStack(spacing: 20) {
        WorkoutProgressIndicator(currentStep: 1)
        WorkoutProgressIndicator(currentStep: 2)
        WorkoutProgressIndicator(currentStep: 3)
    }
    .padding()
} 