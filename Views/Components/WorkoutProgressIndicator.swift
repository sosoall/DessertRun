import SwiftUI

/// 运动打卡引导进度条
/// 用于显示运动打卡的3个步骤进度：选择美食目标 -> 选择运动类型 -> 完成运动
struct WorkoutProgressIndicator: View {
    /// 当前步骤 (1: 选择美食目标, 2: 选择运动类型, 3: 完成运动)
    let currentStep: Int
    
    /// 进度步骤定义
    private let steps = [
        (title: "选择美食", step: 1),
        (title: "选择运动", step: 2),
        (title: "完成运动", step: 3)
    ]
    
    var body: some View {
        VStack(spacing: 6) {
            // 步骤指示器
            HStack(spacing: 0) {
                ForEach(0..<steps.count, id: \.self) { index in
                    let step = steps[index]
                    let isCompleted = step.step < currentStep
                    let isCurrent = step.step == currentStep
                    
                    HStack(spacing: 0) {
                        // 步骤圆圈
                        ZStack {
                            Circle()
                                .fill(isCompleted || isCurrent ? Color(hex: "FE2D55") : Color.gray.opacity(0.3))
                                .frame(width: 24, height: 24)
                            
                            Text("\(step.step)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        // 连接线（除了最后一个）
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(step.step < currentStep ? Color(hex: "FE2D55") : Color.gray.opacity(0.3))
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .frame(height: 24)
            
            // 步骤标题
            HStack(spacing: 0) {
                ForEach(0..<steps.count, id: \.self) { index in
                    let step = steps[index]
                    let isCompleted = step.step < currentStep
                    let isCurrent = step.step == currentStep
                    
                    Text(step.title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isCompleted || isCurrent ? Color(hex: "FE2D55") : Color.gray)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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