//
//  ExerciseTypeOptionRow.swift
//  DessertRun
//
//  Created by Claude on 2025/4/26.
//

import SwiftUI

/// 运动类型选项行
struct ExerciseTypeOptionRow: View {
    /// 运动类型
    let exerciseType: ExerciseType
    
    /// 卡路里值
    let calories: Double
    
    /// 是否选中
    let isSelected: Bool
    
    /// 点击事件
    let action: () -> Void
    
    /// 预估时间
    private var estimatedTime: Double {
        exerciseType.estimatedTimeToComplete(calories: calories)
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // 运动图标
                Image(systemName: exerciseType.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.black)
                    .padding(10)
                    .padding(.leading, 8)
                
                // 运动信息
                VStack(alignment: .leading, spacing: 5) {
                    Text(exerciseType.name)
                        .bodyBoldStyle()
                        .foregroundColor(.black)
                    
                    Text("约\(formatTime(estimatedTime))，\(String(format: "%.1f", calories / 500))公里。")
                        .captionStyle()
                        .foregroundColor(Color(hex: "757575"))
                }
                .padding(.vertical, 4)
                
                Spacer()
                
                // 单选按钮
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color(hex: "FE2D55") : Color(hex: "757575"), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "FE2D55"))
                            .frame(width: 14, height: 14)
                    }
                }
                .padding(.trailing, 16)
            }
            .frame(height: 75) // 固定高度为75pt
            .background(
                optionBackground(isSelected: isSelected)
            )
        }
    }
    
    // 提取复杂背景代码为单独函数，避免长表达式可能导致的编译器问题
    @ViewBuilder
    private func optionBackground(isSelected: Bool) -> some View {
        // 简化条件表达式和嵌套逻辑
        let shape = RoundedRectangle(cornerRadius: 24)
        
        if isSelected {
            // 选中状态的背景 - 渐变粉红色
            shape
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "FF329A").opacity(0.2), Color(hex: "FFD12C").opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    shape.stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "FF329A"), Color(hex: "FF2C3E")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                )
        } else {
            // 未选中状态的背景 - 浅灰色
            shape.fill(Color(hex: "F5F5F5"))
        }
    }
    
    /// 格式化时间
    private func formatTime(_ minutes: Double) -> String {
        if minutes < 1 {
            return "1分钟"
        } else if minutes < 60 {
            return "\(Int(minutes.rounded()))分钟"
        } else {
            let hours = Int(minutes / 60)
            let mins = Int(minutes.truncatingRemainder(dividingBy: 60))
            
            if mins == 0 {
                return "\(hours)小时"
            } else {
                return "\(hours)小时\(mins)分钟"
            }
        }
    }
} 