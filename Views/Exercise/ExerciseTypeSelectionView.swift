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
    
    /// 共享的命名空间（从DessertGridView传入）
    var namespace: Namespace.ID
    
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
                            .padding(.bottom, 16)
                        }
                        
                        Spacer()
                        
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
                                .frame(width: 192)
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
                // 添加面板动画
                .offset(y: appState.isTransitioningToExerciseType ? 0 : geometry.size.height)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appState.isTransitioningToExerciseType)
                
                // 关闭按钮 - 放在最上层
                HStack {
                    Button(action: {
                        // 返回动画：先设置过渡状态，面板会通过动画下移
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            appState.isTransitioningToExerciseType = false
                        }
                        
                        // 延迟关闭页面，等待动画完成
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            dismiss()
                        }
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
                // 关闭按钮的出现动画
                .opacity(appState.isTransitioningToExerciseType ? 1 : 0)
                .animation(.easeInOut.delay(0.3), value: appState.isTransitioningToExerciseType)
                
                // 实拍图 - 确保覆盖面板
                if let dessert = appState.selectedDessert {
                    VStack {
                        Spacer()
                            .frame(height: geometry.size.height * 0.12) // 实拍图垂直位置
                        
                        Image(dessert.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 160)
                            .frame(maxWidth: .infinity)
                            .matchedGeometryEffect(
                                id: "dessert_image_\(dessert.id)",
                                in: namespace,
                                isSource: false
                            )
                        
                        Spacer()
                    }
                    .zIndex(2) // 放在面板上方
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            appState.hideTabBarForDrag = true
            
            // 触发面板上移动画
            if !appState.isTransitioningToExerciseType {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        appState.isTransitioningToExerciseType = true
                    }
                }
            }
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

/// 自定义运动类型选择视图（用于ZStack中的条件渲染）
struct CustomExerciseTypeSelectionView: View {
    /// 环境中的应用状态
    @EnvironmentObject var appState: AppState
    
    /// 运动类型列表
    private let exerciseTypes = ExerciseTypeData.getSampleExerciseTypes()
    
    /// 选中的运动类型
    @State private var selectedExerciseType: ExerciseType?
    
    /// 共享的命名空间
    var namespace: Namespace.ID
    
    /// 关闭回调
    var onClose: () -> Void
    
    /// 开始运动回调
    var onWorkoutStart: (ExerciseType) -> Void
    
    /// 卡路里值
    private var calories: Double {
        guard let selectedDessert = appState.selectedDessert else { return 0 }
        if let calValue = Double(selectedDessert.calories.replacingOccurrences(of: "kcal", with: "")) {
            return calValue
        }
        return 0
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // 背景 - 单色背景F8F8F8
                Color(hex: "F8F8F8")
                    .ignoresSafeArea()
                
                // 甜品图片 - 确保在最上层并与气泡匹配
                if let dessert = appState.selectedDessert {
                    Image(dessert.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 160)
                        // 添加带有阴影的效果提高质感
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .matchedGeometryEffect(
                            id: "dessert_image_\(dessert.id)",
                            in: namespace,
                            isSource: false
                        )
                        .position(
                            x: appState.targetDessertFrame.midX, 
                            y: appState.targetDessertFrame.midY
                        )
                        .zIndex(2)
                }
                
                // 白色面板（主内容区）- 从屏幕下方滑入
                VStack(spacing: 0) {
                    // 为图片预留足够空间（仅预留图片高度+边距的空间）
                    Spacer()
                        .frame(height: 200)
                    
                    // 白色面板内容
                    VStack(spacing: 0) {
                        // 目标信息
                        if let dessert = appState.selectedDessert {
                            Text("运动目标：\(dessert.name)")
                                .h1Style()
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .padding(.top, 25)
                            
                            Text("（约\(String(format: "%.0f", calories))卡路里）")
                                .captionStyle()
                                .foregroundColor(.black)
                                .padding(.bottom, 20)
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
                            .padding(.bottom, 16)
                        }
                        .frame(maxHeight: .infinity)
                        
                        // 开始按钮 - 固定在底部
                        Button(action: {
                            if let selectedType = selectedExerciseType {
                                onWorkoutStart(selectedType)
                            }
                        }) {
                            Text("开始")
                                .h1Style()
                                .foregroundColor(.white)
                                .frame(height: 56)
                                .frame(width: 192)
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
                        .padding(.vertical, geometry.safeAreaInsets.bottom > 0 ? 24 : 16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .cornerRadius(24, corners: [.topLeft, .topRight])
                }
                .ignoresSafeArea(.container, edges: .bottom)
                // 添加面板滑入动画
                .offset(y: appState.isTransitioningToExerciseType ? 0 : geometry.size.height)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appState.isTransitioningToExerciseType)
                
                // 关闭按钮 - 放在最上层
                HStack {
                    Button(action: onClose) {
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
                // 关闭按钮的出现动画
                .opacity(appState.isTransitioningToExerciseType ? 1 : 0)
                .animation(.easeInOut.delay(0.3), value: appState.isTransitioningToExerciseType)
            }
        }
        .onAppear {
            appState.hideTabBarForDrag = true
        }
        .onDisappear {
            appState.hideTabBarForDrag = false
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @Namespace var namespace
        
        var body: some View {
            NavigationStack {
                ExerciseTypeSelectionView(namespace: namespace)
                    .environmentObject({
                        let state = AppState.shared
                        state.selectedDessert = DessertData.getSampleDesserts().first
                        return state
                    }())
            }
        }
    }
    
    return PreviewWrapper()
} 