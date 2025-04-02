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
    
    /// 选中的运动类型
    @State private var selectedExerciseType: ExerciseType?
    
    /// 卡路里值
    private var calories: Double {
        guard let selectedDessert = appState.selectedDessert else { return 0 }
        if let calValue = Double(selectedDessert.calories.replacingOccurrences(of: "kcal", with: "")) {
            return calValue
        }
        return 0
    }
    
    // 环境返回功能
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // 背景 - 单色背景F8F8F8
                Color(hex: "F8F8F8")
                    .ignoresSafeArea()
                
                // 白色面板（主内容区）- 从屏幕上方约1/3处开始
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: geometry.size.height * 0.22) // 面板顶部距离
                    
                    // 白色面板内容
                    VStack(spacing: 0) {
                        // 目标信息
                        if let dessert = appState.selectedDessert {
                            Text("运动目标：\(dessert.name)")
                                .h1Style()
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .padding(.top, 30)
                            
                            Text("（约\(String(format: "%.0f", calories))卡路里）")
                                .captionStyle()
                                .foregroundColor(.black)
                                .padding(.bottom, 24)
                        }
                        
                        // 选择提示文字
                        Text("请选择运动类型")
                            .h2Style()
                            .foregroundColor(Color(hex: "757575"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 25)
                            .padding(.bottom, 16)
                        
                        // 选项列表区域 - 填充空间直到开始按钮
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(exerciseTypes) { exerciseType in
                                    ExerciseTypeOptionRow(
                                        exerciseType: exerciseType,
                                        calories: calories,
                                        isSelected: selectedExerciseType?.id == exerciseType.id,
                                        action: {
                                            selectedExerciseType = exerciseType
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 25)
                        }
                        .padding(.bottom, 20)
                        
                        // 开始按钮 - 固定在底部
                        Button(action: {
                            if let selectedType = selectedExerciseType {
                                appState.selectedExerciseType = selectedType
                                navigateToWorkout = true
                            }
                        }) {
                            Text("开始")
                                .h1Style()
                                .foregroundColor(.white)
                                .frame(height: 56)
                                .frame(width: 100)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color(hex: "FF329A"), Color(hex: "FF2C3E")]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(28)
                        }
                        .disabled(selectedExerciseType == nil)
                        .opacity(selectedExerciseType == nil ? 0.6 : 1.0)
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 34 : 24)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                }
                .ignoresSafeArea(.container, edges: .bottom)
                
                // 关闭按钮 - 放在最上层
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    .padding(.leading)
                    
                    Spacer()
                }
                .padding(.top, 20)
                .zIndex(3) // 放在最上层
                
                // 实拍图 - 确保覆盖面板
                if let dessert = appState.selectedDessert {
                    VStack {
                        Spacer()
                            .frame(height: geometry.size.height * 0.05) // 实拍图垂直位置
                        
                        Image(dessert.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 150)
                            .frame(maxWidth: .infinity)
                        
                        Spacer()
                    }
                    .zIndex(2) // 放在面板上方
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            appState.hideTabBarForDrag = true
        }
        .onDisappear {
            if !navigateToWorkout {
                appState.hideTabBarForDrag = false
            }
        }
        .navigationDestination(isPresented: $navigateToWorkout) {
            WorkoutView()
                .onAppear {
                    appState.isInWorkoutMode = true
                }
        }
    }
}

/// 运动类型选项行
struct ExerciseTypeOptionRow: View {
    let exerciseType: ExerciseType
    let calories: Double
    let isSelected: Bool
    let action: () -> Void
    
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
                        .stroke(isSelected ? Color(hex: "FE2D55") : Color(hex: "49454F"), lineWidth: 2)
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
            // 选中状态的背景
            shape
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "FF329A"), Color(hex: "FFD12C")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ).opacity(0.15)
                )
                .overlay(
                    shape.stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "FF329A"), Color(hex: "FF2C3E")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                )
        } else {
            // 未选中状态的背景 - 更新为F1F1F1
            shape.fill(Color(hex: "F1F1F1"))
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