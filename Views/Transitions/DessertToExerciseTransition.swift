//
//  DessertToExerciseTransition.swift
//  DessertRun
//
//  Created by Claude on 2025/4/10.
//

import SwiftUI

// 注意: 使用 Extensions/View/CornerRadiusExtension.swift 中的共享扩展实现圆角
// 文件底部的扩展已被删除以避免冲突

// 在文件开头添加全局常量
let globalCoordinateSpaceName = "dessertRunGlobalSpace"

/// 甜品到运动类型的过渡动画视图
struct DessertToExerciseTransition: View {
    /// 动画状态
    @ObservedObject var animationState: TransitionAnimationState
    
    /// 应用状态
    @EnvironmentObject var appState: AppState
    
    /// 屏幕尺寸
    let screenSize: CGSize
    
    /// 全局坐标空间名称
    let globalCoordinateSpaceName = "DessertTransitionCoordinateSpace"
    
    /// 导航到运动页面
    @State private var navigateToWorkout = false
    
    /// 计算甜品图片的位置
    private var currentPosition: CGRect {
        // 如果没有选中的甜品，返回零框架
        guard animationState.selectedDessert != nil else { return .zero }
        
        // 获取起始和目标位置
        let startFrame = animationState.imageOriginFrame ?? .zero
        let targetFrame = calculateTargetFrame()
        
        // 确保有有效的起始位置
        guard startFrame != .zero else { return targetFrame }
        
        // 根据进度计算当前位置
        let progress = animationState.dessertPositionProgress
        
        // 使用插值计算框架
        let resultFrame = calculateIntermediateFrame(
            from: startFrame,
            to: targetFrame,
            progress: progress
        )
        
        return resultFrame
    }
    
    /// 计算目标框架（甜品在顶部的位置）
    private func calculateTargetFrame() -> CGRect {
        // 计算顶部中心的小图片位置：居中，宽度为屏幕宽度的1/3
        let screenWidth = UIScreen.main.bounds.width
        let size: CGFloat = 120
        let x = (screenWidth - size) / 2
        let y = UIScreen.main.bounds.height * 0.05  // 顶部5%位置
        
        return CGRect(x: x, y: y, width: size, height: size)
    }
    
    /// 计算两个框架之间的中间帧
    private func calculateIntermediateFrame(from: CGRect, to: CGRect, progress: CGFloat) -> CGRect {
        let x = from.origin.x + (to.origin.x - from.origin.x) * progress
        let y = from.origin.y + (to.origin.y - from.origin.y) * progress
        let width = from.width + (to.width - from.width) * progress
        let height = from.height + (to.height - from.height) * progress
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    /// 获取面板偏移量
    private var panelOffset: CGFloat {
        // 当面板完全显示时偏移应为0（底部对齐）
        // 当面板完全隐藏时，偏移应为面板高度（在屏幕外）
        let panelHeight = screenSize.height * 0.85
        let hiddenOffset = panelHeight
        // 可见状态的偏移量为0（底部对齐）
        
        // 根据面板位置进度计算当前偏移量
        // 从隐藏状态（屏幕外）到显示状态（底部对齐）
        return hiddenOffset * (1 - animationState.panelPositionProgress)
    }
    
    /// 背景不透明度
    private var backgroundOpacity: Double {
        let progress = animationState.animationProgress
        return min(1.0, progress * 2.0) // 加快背景变暗速度
    }
    
    /// 卡路里值
    private var calories: Double {
        guard let selectedDessert = animationState.selectedDessert else { return 0 }
        if let calValue = Double(selectedDessert.calories.replacingOccurrences(of: "kcal", with: "")) {
            return calValue
        }
        return 0
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) { // 使用ZStack的底部对齐
                // 背景遮罩
                Color.black
                    .opacity(animationState.backgroundDimLevel)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        // 点击背景区域可关闭面板
                        animationState.dismissPanel()
                    }
                
                // 运动类型选择面板 - 使用自定义实现
                panelView
                    .frame(maxWidth: .infinity)
                    .frame(height: screenSize.height * 0.85)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -5)
                    )
                    .offset(y: panelOffset) // offset相对于底部对齐位置
                    .animation(.standardTransition, value: panelOffset)
                    .zIndex(1)
                
                // 甜品图片 - 从气泡移动到顶部中心
                dessertImageView
                    .position(x: currentPosition.midX, y: currentPosition.midY)
                    .zIndex(2) // 确保甜品图片在面板上层
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .edgesIgnoringSafeArea(.bottom) // 忽略底部安全区域，避免出现白条
            .coordinateSpace(name: globalCoordinateSpaceName)
            .environmentObject(animationState) // 确保所有子视图都能访问animationState
            .navigationDestination(isPresented: $navigateToWorkout) {
                WorkoutView()
                    .onAppear {
                        // 进入运动模式 - 使用AppState而不是animationState
                        appState.isInWorkoutMode = true
                    }
            }
        }
    }
    
    // MARK: - 提取的子视图
    
    /// 甜品图片视图
    private var dessertImageView: some View {
        Group {
            if let dessert = animationState.selectedDessert {
                // 使用getFullImageName获取新的图片名称格式
                let imageName = dessert.getFullImageName(for: .regular)
                // 如果找到甜品图片名称，使用该图片，否则使用默认图标
                if UIImage(named: imageName) != nil {
                    Image(imageName)
                        .resizable()
                        .scaledToFit() // 使用scaledToFit保持图片比例
                        .frame(width: currentPosition.width, height: currentPosition.height)
                        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                } else {
                    // 默认图标
                    Image(systemName: "cup.and.saucer.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(dessert.backgroundColor ?? .orange)
                        .frame(width: currentPosition.width, height: currentPosition.height)
                        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
                }
            }
        }
    }
    
    /// 面板视图
    private var panelView: some View {
        VStack(spacing: 0) {
            // 顶部区域包含关闭按钮
            HStack {
            // 顶部拖动条
                Spacer()
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 60, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 8)
                Spacer()
                
                // 右上角关闭按钮
                Button(action: {
                    animationState.dismissPanel()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.gray.opacity(0.1)))
                }
                .padding(.trailing, 16)
                .padding(.top, 10)
            }
            
            // 标题区域
            titleView
            
            // 请选择运动类型标题
            Text("请选择运动类型")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "757575"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            
            // 分隔线
            Divider()
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            
            // 面板内容 - 运动类型列表
            exerciseListView
                .padding(.bottom, 0) // 移除底部间距
        }
        .padding(.top, 0) // 移除顶部间距
        .background(Color.white)
    }
    
    /// 标题视图
    private var titleView: some View {
        Group {
            if let dessert = animationState.selectedDessert {
                VStack(alignment: .center, spacing: 0) {
                    Text("运动目标：\(dessert.name)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    Text("（约\(Int(calories))卡路里）")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .padding(.top, 5)
                }
                .padding(.bottom, 25)
            }
        }
    }
    
    /// 运动列表视图
    private var exerciseListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(ExerciseType.allCases, id: \.self) { exerciseType in
                    exerciseRowView(for: exerciseType)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    /// 单个运动类型行视图
    private func exerciseRowView(for exerciseType: ExerciseType) -> some View {
        Button(action: {
            // 选择运动类型并导航到运动页面 - 使用AppState而不是animationState
            appState.selectedExerciseType = exerciseType
            navigateToWorkout = true
        }) {
            HStack(spacing: 0) {
                // 左侧圆形图标区域
                ZStack {
                    // 渐变背景圆
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: getGradientColors(for: exerciseType)),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(color: getGradientColors(for: exerciseType)[0].opacity(0.5), radius: 8, x: 2, y: 4)
                    
                    // 白色内圆
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 50, height: 50)
                    
                    // 图标
                    Image(systemName: exerciseType.iconName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 1, y: 1)
                }
                .padding(.leading, 5)
                
                // 中间文本内容
                VStack(alignment: .leading, spacing: 6) {
                    // 运动名称
                    Text(exerciseType.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    
                    HStack(spacing: 5) {
                        // 时间/距离图标
                        Image(systemName: exerciseType.usesDistance ? "figure.walk" : "clock.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "666666"))
                        
                        // 时间/距离文本
                        Text(exerciseType.getEstimatedCompletion(calories: calories))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "666666"))
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        Capsule()
                            .fill(Color(hex: "F3F3F3"))
                    )
                }
                .padding(.leading, 12)
                
                Spacer()
                
                // 右侧箭头
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "BBBBBB"))
                    .padding(.trailing, 20)
            }
            .frame(height: 90)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 5)
            )
            .overlay(
                // 为卡片添加几何装饰
                ZStack {
                    // 右上角三角形装饰
                    Path { path in
                        path.move(to: CGPoint(x: 280, y: 0))
                        path.addLine(to: CGPoint(x: 350, y: 0))
                        path.addLine(to: CGPoint(x: 350, y: 40))
                        path.closeSubpath()
    }
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                getGradientColors(for: exerciseType)[0].opacity(0.05),
                                getGradientColors(for: exerciseType)[1].opacity(0.1)
                            ]),
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        )
                    )
                    
                    // 左下角弧形装饰
                    Path { path in
                        path.move(to: CGPoint(x: 80, y: 90))
                        path.addArc(center: CGPoint(x: 40, y: 60),
                                   radius: 40,
                                   startAngle: .degrees(90),
                                   endAngle: .degrees(180),
                                   clockwise: false)
                        path.addLine(to: CGPoint(x: 0, y: 90))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                getGradientColors(for: exerciseType)[0].opacity(0.08),
                                getGradientColors(for: exerciseType)[1].opacity(0.12)
                            ]),
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
                }
                .mask(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                )
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .buttonStyle(CustomScaleButtonStyle())
    }
    
    /// 获取运动类型专属渐变色
    private func getGradientColors(for exerciseType: ExerciseType) -> [Color] {
        switch exerciseType {
        case .houseCleaning:
            return [Color(hex: "825AE2"), Color(hex: "5D42B5")]
        case .dogWalking:
            return [Color(hex: "FF9F2F"), Color(hex: "F27121")]
        case .walking:
            return [Color(hex: "56E38A"), Color(hex: "39B574")]
        case .running:
            return [Color(hex: "FF6928"), Color(hex: "FF3F1A")]
        case .homeWorkout:
            return [Color(hex: "FF4B91"), Color(hex: "E61E5A")]
        case .hiitWorkout:
            return [Color(hex: "FF2D55"), Color(hex: "D81547")]
        case .stairClimbing:
            return [Color(hex: "4CD964"), Color(hex: "2CA94C")]
        default:
            return [Color(hex: "8A2387"), Color(hex: "E94057")]
            }
        }
}

// MARK: - 自定义按钮样式
struct CustomScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Color扩展
extension Color {
    /// 根据指定系数调整颜色饱和度
    /// - Parameter factor: 饱和度调整系数 (0-1)
    /// - Returns: 调整后的颜色
    func saturated(by factor: CGFloat) -> Color {
        // 提取色相、饱和度和亮度
        let uiColor = UIColor(self)
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        if uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            // 调整饱和度和亮度
            let adjustedSaturation = min(1.0, s * factor * 1.3) // 稍微提高饱和度
            let adjustedBrightness = min(1.0, b * (0.7 + factor * 0.3)) // 较高饱和度时亮度稍低
            
            return Color(UIColor(hue: h, 
                               saturation: adjustedSaturation, 
                               brightness: adjustedBrightness, 
                               alpha: a))
        }
        
        return self // 如果无法调整，返回原始颜色
        }
    }
    
// MARK: - 自定义按钮样式
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// 在文件顶部添加扩展，为ExerciseType添加渐变色属性
extension ExerciseType {
    var gradientColors: [Color] {
        switch self {
        case .houseCleaning:
            return [Color(hex: "825AE2"), Color(hex: "5D42B5")]
        case .dogWalking:
            return [Color(hex: "FF9F2F"), Color(hex: "F27121")]
        case .running:
            return [Color(hex: "FF6928"), Color(hex: "FF3F1A")]
        case .walking:
            return [Color(hex: "4CB8C4"), Color(hex: "3CD3AD")]
        case .homeWorkout:
            return [Color(hex: "FF4B91"), Color(hex: "E61E5A")]
        case .hiitWorkout:
            return [Color(hex: "FF2D55"), Color(hex: "D81547")]
        case .stairClimbing:
            return [Color(hex: "4CD964"), Color(hex: "2CA94C")]
        default:
            return [Color(hex: "8A2387"), Color(hex: "E94057")]
        }
    }
} 