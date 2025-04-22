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
    
    /// 选中的运动类型
    @State private var selectedExercise: ExerciseType? = nil
    
    /// 展开的运动类型ID
    @State private var expandedExerciseID: Int? = nil
    
    /// 运动时长（分钟）
    @State private var exerciseDuration: Double = 30
    
    /// 运动距离（米）
    @State private var exerciseDistance: Double = 2000
    
    /// 展示成功提示
    @State private var showingSuccessAlert: Bool = false
    
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
    
    /// 计算建议的运动时长（分钟）
    private func suggestedDuration(for exerciseType: ExerciseType) -> Double {
        let targetCalories = calories
        
        // 使用ExerciseType中的方法计算时间
        let hours = exerciseType.calculateExerciseTime(calories: targetCalories)
        
        // 转换为分钟
        let minutes = hours * 60
        
        // 向上取整到最接近的5分钟
        return ceil(minutes / 5) * 5
    }
    
    /// 计算建议的运动距离（米）
    private func suggestedDistance(for exerciseType: ExerciseType) -> Double {
        let targetCalories = calories
        
        // 使用ExerciseType中的方法计算距离（公里）
        let distanceInKm = exerciseType.calculateRunningDistance(calories: targetCalories)
        
        // 转换为米并向上取整到最接近的100米
        return ceil(distanceInKm * 1000 / 100) * 100
    }
    
    /// 提交运动记录
    private func submitWorkout() {
        guard let dessert = animationState.selectedDessert,
              let exerciseType = selectedExercise else {
            return
        }
        
        // 计算消耗的卡路里
        var caloriesBurned: Double = 0
        
        if exerciseType.usesDistance {
            // 基于距离计算卡路里
            caloriesBurned = exerciseType.calculateCaloriesForDistance(
                distance: exerciseDistance,
                weight: 65 // 使用默认体重65kg
            )
        } else {
            // 基于时间计算卡路里
            caloriesBurned = exerciseType.calculateCaloriesForTime(
                minutes: exerciseDuration,
                weight: 65 // 使用默认体重65kg
            )
        }
        
        // 创建运动记录
        let record = WorkoutRecord(
            dessert: dessert,
            exerciseType: exerciseType,
            completionDate: Date(),
            duration: exerciseDuration,
            caloriesBurned: caloriesBurned,
            distance: exerciseType.usesDistance ? exerciseDistance : nil
        )
        
        // 添加记录到应用状态
        appState.addWorkoutRecord(record)
        
        // 设置刚完成打卡标记，用于触发动画
        appState.justCompletedWorkout = true
        
        // 关闭面板
        animationState.dismissPanel()
        
        // 短暂延迟后切换到甜品打卡标签页
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                // 将TabBar切换到甜品打卡标签（索引为1）
                appState.selectedTabIndex = 1
            }
        }
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
            Text("请选择运动打卡")
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
        // 提前计算所需的提示文本
        let requiredValueText: String
        if let dessert = animationState.selectedDessert {
            if exerciseType.usesDistance {
                let distance = suggestedDistance(for: exerciseType)
                requiredValueText = "约\(String(format: "%.1f", distance / 1000))公里"
            } else {
                let duration = suggestedDuration(for: exerciseType)
                requiredValueText = "约\(Int(duration))分钟"
            }
        } else {
            requiredValueText = "选择甜品计算所需运动量"
        }
        
        return VStack(spacing: 0) {
            // 主要卡片
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    if expandedExerciseID == exerciseType.rawValue {
                        // 如果已经展开，则关闭
                        expandedExerciseID = nil
                        selectedExercise = nil
                    } else {
                        // 展开此运动类型
                        expandedExerciseID = exerciseType.rawValue
                        selectedExercise = exerciseType
                        
                        // 设置默认值为建议的时长/距离
                        if exerciseType.usesDistance {
                            exerciseDistance = suggestedDistance(for: exerciseType)
                        } else {
                            exerciseDuration = suggestedDuration(for: exerciseType)
                        }
                    }
                }
            }) {
                HStack(spacing: 0) {
                    // 直接显示彩色图标，不使用圆圈
                    Image(systemName: exerciseType.iconName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(exerciseType.backgroundColor)
                        .padding(.leading, 20)
                    
                    // 中间文本内容
                    VStack(alignment: .leading, spacing: 4) {
                        // 运动名称
                        Text(exerciseType.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                        
                        // 使用提前计算好的文本
                        Text(requiredValueText)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                    
                    // 右侧按钮文本
                    if expandedExerciseID == exerciseType.rawValue {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.trailing, 20)
                    } else {
                        Text("打卡")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(exerciseType.backgroundColor)
                            )
                            .padding(.trailing, 16)
                    }
                }
                .frame(height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                )
            }
            .buttonStyle(CustomScaleButtonStyle())
            
            // 展开的配置区域
            if expandedExerciseID == exerciseType.rawValue {
                expandedExerciseOptions(for: exerciseType)
                    .padding(.top, 2)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.7)),
                        removal: .opacity.animation(.easeOut(duration: 0.25))
                    ))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
    
    /// 展开的运动选项
    private func expandedExerciseOptions(for exerciseType: ExerciseType) -> some View {
        // 提前计算预估卡路里和消耗数量
        let dessertName = animationState.selectedDessert?.name ?? ""
        
        // 获取推荐运动时长和距离
        let suggestedDurationValue = suggestedDuration(for: exerciseType)
        let suggestedDistanceValue = suggestedDistance(for: exerciseType)
        
        // 使用实际运动时长/推荐运动时长的比值计算消耗美食个数
        // 距离模式的计算
        let foodCountForDistance = exerciseType.usesDistance ? 
            exerciseDistance / suggestedDistanceValue : 0
        let foodMessageForDistance = "预计消耗\(String(format: "%.1f", foodCountForDistance))个\(dessertName)"
        
        // 时间模式的计算
        let foodCountForTime = !exerciseType.usesDistance ? 
            exerciseDuration / suggestedDurationValue : 0
        let foodMessageForTime = "预计消耗\(String(format: "%.1f", foodCountForTime))个\(dessertName)"
        
        return VStack(spacing: 20) {
            if let dessert = animationState.selectedDessert {
                if exerciseType.usesDistance {
                    // 距离选择
                    VStack(alignment: .center, spacing: 8) {
                        Text("运动距离")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                        
                        HStack {
                            Button(action: {
                                exerciseDistance = max(100, exerciseDistance - 500)
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Color(hex: "#F3F3F3")))
                                    .overlay(
                                        Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            
                            Spacer()
                            
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\(String(format: "%.1f", exerciseDistance / 1000))")
                                    .font(.system(size: 28, weight: .bold))
                                
                                Text("公里")
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                                    .padding(.leading, 2)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                exerciseDistance += 500
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(exerciseType.backgroundColor)
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        Text(foodMessageForDistance)
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                } else {
                    // 时长选择
                    VStack(alignment: .center, spacing: 8) {
                        Text("运动时长")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                        
                        HStack {
                            Button(action: {
                                exerciseDuration = max(5, exerciseDuration - 5)
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Color(hex: "#F3F3F3")))
                                    .overlay(
                                        Circle().stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            
                            Spacer()
                            
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\(Int(exerciseDuration))")
                                    .font(.system(size: 28, weight: .bold))
                                
                                Text("分钟")
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                                    .padding(.leading, 2)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                exerciseDuration += 5
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(exerciseType.backgroundColor)
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        Text(foodMessageForTime)
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            } else {
                // 添加一个默认的视图，以确保始终返回View
                Text("请选择甜品")
                    .foregroundColor(.gray)
                    .padding()
            }
            
            // 打卡按钮 - 恢复颜色
            Button(action: {
                submitWorkout()
            }) {
                Text("完成打卡")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#FF5E57"), Color(hex: "#FF2D55")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .cornerRadius(25)
                    )
                    .shadow(color: Color(hex: "#FF2D55").opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#F8F8F8"))
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }
    
    /// 获取运动类型专属渐变色
    private func getGradientColors(for exerciseType: ExerciseType) -> [Color] {
        return [exerciseType.backgroundColor, exerciseType.backgroundColor]
    }
}

// MARK: - 自定义按钮样式
struct CustomScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
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

// 在ExerciseType扩展中添加新的方法
extension ExerciseType {
    /// 获取每分钟每公斤体重消耗的卡路里
    func getCaloriesPerMinutePerKg() -> Double {
        switch self {
        case .houseCleaning:
            return 0.05
        case .dogWalking:
            return 0.06
        case .walking:
            return 0.07
        case .running:
            return 0.12
        case .homeWorkout:
            return 0.08
        case .hiitWorkout:
            return 0.14
        case .stairClimbing:
            return 0.11
        }
    }
    
    /// 计算指定时间消耗的卡路里
    func calculateCaloriesForTime(minutes: Double, weight: Double = 65.0) -> Double {
        return minutes * getCaloriesPerMinutePerKg() * weight
    }
    
    /// 获取每公里每公斤体重消耗的卡路里
    func getCaloriesPerKmPerKg() -> Double {
        switch self {
        case .walking:
            return 0.8
        case .running:
            return 1.2
        default:
            return 1.0
        }
    }
    
    /// 计算指定距离消耗的卡路里
    func calculateCaloriesForDistance(distance: Double, weight: Double = 65.0) -> Double {
        // 距离转换为公里
        let distanceInKm = distance / 1000.0
        return distanceInKm * getCaloriesPerKmPerKg() * weight
    }
} 