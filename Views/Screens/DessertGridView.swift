//
//  DessertGridView.swift
//  DessertRun
//
//  Created by Claude on 2025/3/24.
//

import SwiftUI

/// 甜品网格视图
struct DessertGridView: View {
    /// 甜品数据
    private let desserts = DessertData.getSampleDesserts()
    
    /// 选中的甜品
    @State private var selectedDessert: DessertItem?
    
    /// 是否显示引导
    @State private var showGuides = false
    
    /// 是否显示运动类型选择页面
    @State private var showExerciseTypeSelection = false
    
    /// 环境中的应用状态
    @EnvironmentObject var appState: AppState
    
    /// 控制布局刷新
    @State private var forceLayoutUpdate = false
    
    /// 用于过渡动画的命名空间
    @Namespace private var namespace
    
    /// 拖动状态回调
    var onDragStateChanged: ((Bool) -> Void)?
    
    // 初始化方法，可选传入拖动状态回调
    init(onDragStateChanged: ((Bool) -> Void)? = nil) {
        self.onDragStateChanged = onDragStateChanged
    }
    
    var body: some View {
        ZStack {
            // 甜品网格主视图
            mainGridView
                .zIndex(showExerciseTypeSelection ? 0 : 1)
            
            // 运动类型选择视图（条件渲染）
            if showExerciseTypeSelection {
                exerciseTypeSelectionView
                    .zIndex(1)
                    .transition(.identity) // 使用自定义动画，不使用系统过渡
            }
        }
        .onAppear {
            // 延迟一点时间确保视图布局完成后再刷新气泡布局
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                forceLayoutUpdate.toggle()
            }
        }
    }
    
    /// 主网格视图
    private var mainGridView: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景
                Color(hex: "FFFFFF")
                .ignoresSafeArea()
                
                // 气泡布局
                BubbleLayout(
                    items: desserts,
                    config: createConfig(for: geometry.size),
                    onDragStateChanged: onDragStateChanged,
                    content: { dessert, state in
                        // 单个气泡内容
                        BubbleView(
                            item: dessert,
                            bubbleSize: state.size,
                            distanceToCenter: state.distanceToCenter,
                            maxSize: createConfig(for: geometry.size).bubbleSize,
                            minSize: createConfig(for: geometry.size).minBubbleSize,
                            onTap: {
                                selectedDessert = dessert
                                appState.selectedDessert = dessert
                                
                                // 设置过渡ID
                                appState.transitionDessertID = "dessert_image_\(dessert.id)"
                                
                                // 记录位置信息
                                if let window = UIApplication.shared.windows.first {
                                    let image = UIImage(named: dessert.imageName)
                                    let aspectRatio = (image?.size.width ?? 1) / (image?.size.height ?? 1)
                                    let imageHeight: CGFloat = 160
                                    let imageWidth = imageHeight * aspectRatio
                                    let screenHeight = window.bounds.height
                                    
                                    // 调整图片位置到顶部，仅留出足够的安全区域和关闭按钮空间
                                    let topSafeArea = window.safeAreaInsets.top
                                    let imagePosY = topSafeArea + 70 + imageHeight/2
                                    
                                    appState.targetDessertFrame = CGRect(
                                        x: (geometry.size.width - imageWidth) / 2,
                                        y: imagePosY,
                                        width: imageWidth,
                                        height: imageHeight
                                    )
                                }
                                
                                // 设置标题隐藏状态
                                appState.shouldHideTitle = true
                                
                                // 触发动画和视图切换
                                withAnimation {
                                    appState.isTransitioningToExerciseType = true
                                }
                                
                                // 延迟显示运动类型选择页面，给动画一点准备时间
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        showExerciseTypeSelection = true
                                    }
                                }
                            }
                        )
                        .id("\(dessert.id)_bubble")
                        .background(
                            GeometryReader { bubbleGeometry in
                                Color.clear.onAppear {
                                    // 如果是选中的甜品，记录其位置信息以便过渡动画使用
                                    if appState.selectedDessert?.id == dessert.id {
                                        let frame = bubbleGeometry.frame(in: .global)
                                        appState.selectedDessertOriginalFrame = frame
                                    }
                                }
                            }
                        )
                        .matchedGeometryEffect(
                            id: "dessert_image_\(dessert.id)",
                            in: namespace,
                            properties: .position,
                            anchor: .center,
                            isSource: true
                        )
                        .opacity(shouldHideOtherBubbles(dessert) ? 0 : 1)
                    }
                )
                .id(forceLayoutUpdate) // 使用id强制刷新布局
                .padding(.top, 100) // 为顶部标题留出空间
                
                // 底部控制按钮
                VStack {
                    Spacer()
                    
                    // 底部控制按钮
                    HStack {
                        Button(action: { showGuides.toggle() }) {
                            Image(systemName: showGuides ? "eye.slash.fill" : "eye.fill")
                                .font(.title3)
                                .foregroundColor(Color(hex: "212121"))
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                                .shadow(color: Color(hex: "7E4A4A").opacity(0.25), radius: 10, x: 5, y: 5)
                        }
                    }
                    .padding(.bottom, 80) // 为底部导航栏留出空间
                }
            }
        }
    }
    
    /// 运动类型选择视图
    private var exerciseTypeSelectionView: some View {
        CustomExerciseTypeSelectionView(
            namespace: namespace,
            onClose: {
                // 关闭运动类型选择页面
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    appState.isTransitioningToExerciseType = false
                    appState.shouldHideTitle = false
                }
                
                // 延迟隐藏页面，给动画足够的时间完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation {
                        showExerciseTypeSelection = false
                    }
                }
            },
            onWorkoutStart: { exerciseType in
                // 设置选中的运动类型
                appState.selectedExerciseType = exerciseType
                
                // 导航到运动页面
                // 实际项目中这里会连接到WorkoutView的导航
                print("开始运动: \(exerciseType.name)")
            }
        )
    }
    
    /// 创建适合屏幕尺寸的配置
    /// - Parameter size: 屏幕尺寸
    /// - Returns: 布局配置
    private func createConfig(for size: CGSize) -> BubbleLayoutConfiguration {
        var config = BubbleLayoutConfiguration.forScreenSize(size)
        config.showGuides = showGuides
        return config
    }
    
    /// 判断是否应该隐藏其他气泡
    /// - Parameter dessert: 当前气泡对应的甜品
    /// - Returns: 是否应该隐藏
    private func shouldHideOtherBubbles(_ dessert: DessertItem) -> Bool {
        return appState.isTransitioningToExerciseType && appState.selectedDessert?.id != dessert.id
    }
    
    // 视图即将消失时调用
    func onDisappear() {
        // 确保重置状态
        appState.shouldHideTitle = false
    }
} 