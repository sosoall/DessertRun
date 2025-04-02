//
//  ExerciseTypeSelectionView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

/// 运动类型选择视图
struct ExerciseTypeSelectionView: View {
    /// 环境中的应用状态
    @EnvironmentObject var appState: AppState
    
    /// 运动类型列表
    private let exerciseTypes = ExerciseTypeData.getSampleExerciseTypes()
    
    /// 是否导航到运动界面
    @State private var navigateToWorkout = false
    
    /// 卡路里值
    private var calories: Double {
        guard let selectedDessert = appState.selectedDessert else { return 0 }
        if let calValue = Double(selectedDessert.calories.replacingOccurrences(of: "kcal", with: "")) {
            return calValue
        }
        return 0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 顶部区域 - 选中的甜品
                selectedDessertCard
                
                // 标题
                Text("选择运动方式")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "61462C"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                // 运动方式列表
                LazyVStack(spacing: 16) {
                    ForEach(exerciseTypes) { exerciseType in
                        ExerciseTypeCard(
                            exerciseType: exerciseType,
                            calories: calories,
                            onSelect: {
                                // 选择运动类型并导航到运动界面
                                appState.selectedExerciseType = exerciseType
                                navigateToWorkout = true
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(hex: "faf0dd").ignoresSafeArea())
        .navigationTitle("选择运动")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToWorkout) {
            WorkoutView()
                .onAppear {
                    // 进入运动模式，完全隐藏TabBar
                    appState.isInWorkoutMode = true
                }
        }
        .onDisappear {
            // 如果没有进入WorkoutView，恢复TabBar显示
            // 这确保用户点击返回按钮时TabBar能正常显示
            if !navigateToWorkout {
                appState.isInWorkoutMode = false
            }
        }
    }
    
    /// 选中的甜品卡片
    private var selectedDessertCard: some View {
        Group {
            if let dessert = appState.selectedDessert {
                VStack(spacing: 12) {
                    // 甜品信息
                    HStack(spacing: 16) {
                        // 图片
                        Circle()
                            .fill(dessert.backgroundColor ?? Color.white)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "cup.and.saucer.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.white)
                                    .padding(16)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 4)
                        
                        // 文字内容
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dessert.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("目标甜品")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("需要消耗:")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("\(dessert.calories)")
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "FE2D55"))
                                    .fontWeight(.bold)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 5)
                }
                .padding(.horizontal)
            } else {
                // 如果没有选中甜品，显示提示
                Text("请先选择一个甜品")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
}

/// 运动类型卡片
struct ExerciseTypeCard: View {
    /// 运动类型
    let exerciseType: ExerciseType
    
    /// 需要消耗的卡路里
    let calories: Double
    
    /// 选择回调
    var onSelect: () -> Void
    
    /// 预计时间（分钟）
    private var estimatedTime: Double {
        exerciseType.estimatedTimeToComplete(calories: calories)
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                // 左侧图标
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(exerciseType.backgroundColor)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: exerciseType.iconName)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                }
                
                // 中间内容
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseType.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(exerciseType.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(Color(hex: "FE2D55"))
                        
                        Text(formatTime(estimatedTime))
                            .font(.caption)
                            .foregroundColor(Color(hex: "FE2D55"))
                            .fontWeight(.semibold)
                    }
                }
                .padding(.leading, 8)
                
                Spacer()
                
                // 右侧箭头
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5)
        }
    }
    
    /// 格式化时间
    private func formatTime(_ minutes: Double) -> String {
        if minutes < 1 {
            return "不到1分钟"
        } else if minutes < 60 {
            return "约\(Int(minutes.rounded()))分钟"
        } else {
            let hours = Int(minutes / 60)
            let mins = Int(minutes.truncatingRemainder(dividingBy: 60))
            
            if mins == 0 {
                return "约\(hours)小时"
            } else {
                return "约\(hours)小时\(mins)分钟"
            }
        }
    }
}

#Preview {
    NavigationStack {
        ExerciseTypeSelectionView()
            .environmentObject({
                let state = AppState.shared
                state.selectedDessert = DessertData.getSampleDesserts().first!
                return state
            }())
    }
} 