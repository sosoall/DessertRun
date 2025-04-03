//
//  ExerciseTypeRow.swift
//  DessertRun
//
//  Created by Claude on 2025/4/12.
//

import SwiftUI

/// 运动类型选项行视图
struct ExerciseTypeRow: View {
    // 运动类型
    let exerciseType: ExerciseType
    
    // 选中的甜品
    let selectedDessert: DessertItem?
    
    // 全局应用状态
    @EnvironmentObject var appState: AppState
    
    // 环境消失
    @Environment(\.dismiss) private var dismiss
    
    // 导航到运动页面
    @State private var navigateToWorkout = false
    
    var body: some View {
        Button(action: {
            startExercise()
        }) {
            HStack(spacing: 15) {
                // 运动图标
                Image(systemName: exerciseType.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedDessert?.backgroundColor ?? Color(hex: "FE2D55"))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    // 运动名称
                    Text(exerciseType.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    // 运动描述
                    Text(exerciseType.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 箭头图标
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
        // 添加分隔线
        .overlay(
            VStack {
                Spacer()
                Divider()
            }
        )
        .navigationDestination(isPresented: $navigateToWorkout) {
            WorkoutView()
        }
    }
    
    /// 开始运动会话
    private func startExercise() {
        guard let dessert = selectedDessert else { return }
        
        // 创建新的运动会话
        let workoutSession = WorkoutSession(
            targetDessert: dessert,
            exerciseType: exerciseType
        )
        
        // 更新应用状态
        appState.selectedExerciseType = exerciseType
        appState.activeWorkoutSession = workoutSession
        
        // 导航到运动视图
        navigateToWorkout = true
        
        // 进入运动模式，隐藏TabBar
        appState.isInWorkoutMode = true
        
        // 关闭当前面板
        dismiss()
    }
} 