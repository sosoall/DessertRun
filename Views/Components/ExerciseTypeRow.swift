//
//  ExerciseTypeRow.swift
//  DessertRun
//
//  Created by Claude on 2025/4/12.
//

import SwiftUI
import UIKit

/// 运动类型行组件
struct ExerciseTypeRow: View {
    /// 环境中的应用状态
    @EnvironmentObject var appState: AppState
    
    /// 环境消失事件
    @Environment(\.dismiss) private var dismiss
    
    /// 运动类型
    let exerciseType: ExerciseType
    
    /// 选中的甜品
    let selectedDessert: DessertItem?
    
    /// 是否选中
    @State private var isSelected: Bool = false
    
    /// 开始运动
    private func startExercise() {
        guard let selectedDessert = selectedDessert else { return }
        
        self.isSelected = true
        
        // 创建新的运动会话
        let workoutSession = WorkoutSession(
            dessert: selectedDessert,
            exerciseType: exerciseType,
            targetCalories: Double(selectedDessert.calories.replacingOccurrences(of: "kcal", with: "")) ?? 0,
            startTime: Date()
        )
        
        // 更新应用状态
        appState.selectedExerciseType = exerciseType
        appState.activeWorkoutSession = workoutSession
        appState.isInWorkoutMode = true
        
        // 延迟关闭当前视图，确保动画完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }
    
    var body: some View {
        Button(action: startExercise) {
            HStack {
                // 单选按钮
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color(hex: "FE2D55") : Color(hex: "49454F"), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "FE2D55"))
                            .frame(width: 10, height: 10)
                    }
                }
                .frame(width: 30, height: 48)
                
                // 图标
                ZStack {
                    Circle()
                        .fill(Color(hex: "F5F5F5"))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: exerciseType.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(Color.black)
                }
                
                // 文本内容
                VStack(alignment: .leading, spacing: 2) {
                    Text(exerciseType.displayName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(exerciseType.getTimeDescription())
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "757575"))
                }
                .padding(.leading, 10)
                
                Spacer()
                
                // 箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "757575"))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                Group {
                    if isSelected {
                        // 选中状态 - 粉色到金色渐变
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "FF329A"), Color(hex: "FFD12C")]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .strokeBorder(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color(hex: "FF329A"), Color(hex: "FF2C3E")]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white)
                    }
                }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension ExerciseType {
    /// 获取时间描述
    func getTimeDescription() -> String {
        return "约30分钟，2公里。"
    }
}

#Preview {
    VStack {
        ExerciseTypeRow(
            exerciseType: ExerciseType.running,
            selectedDessert: DessertData.getSampleDesserts().first
        )
        .environmentObject(AppState.shared)
    }
    .background(Color.white)
    .previewLayout(.sizeThatFits)
} 