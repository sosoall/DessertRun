//
//  DessertToExerciseTransition.swift
//  DessertRun
//
//  Created by Claude on 2025/4/10.
//

import SwiftUI
import Combine

// 注意: 使用 Extensions/View/CornerRadiusExtension.swift 中的共享扩展实现圆角
// 文件底部的扩展已被删除以避免冲突

// 在文件开头添加全局常量
let globalCoordinateSpaceName = "dessertRunGlobalSpace"

// 添加存储取消令牌的类
private class CancellableStorage {
    static let shared = CancellableStorage()
    var cancellables = Set<AnyCancellable>()
    
    private init() {}
}

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
    @State private var expandedExerciseID: String? = nil
    
    /// 运动时长（分钟）
    @State private var exerciseDuration: Double = 30
    
    /// 运动距离（米）
    @State private var exerciseDistance: Double = 2000
    
    /// 展示成功提示
    @State private var showingSuccessAlert: Bool = false
    
    /// API返回的运动类型列表
    @State private var apiExerciseTypes: [APIExerciseType] = []
    
    /// 是否正在加载运动类型
    @State private var isLoadingExerciseTypes: Bool = false
    
    /// 加载错误信息
    @State private var loadingError: String? = nil
    
    /// 在文件中添加成员变量，用于存储API响应状态
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    /// 存储每个运动类型的计算结果
    @State private var calculatedDurations: [ExerciseType: Double] = [:]
    @State private var calculatedDistances: [ExerciseType: Double] = [:]
    
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
    
    // 初始化方法
    init(animationState: TransitionAnimationState, screenSize: CGSize) {
        self.animationState = animationState
        self.screenSize = screenSize
        
        // 初始化时加载运动类型
        _isLoadingExerciseTypes = State(initialValue: true)
        
        // 添加禁用缓存的日志
        DRInfo("DessertToExerciseTransition: 已禁用运动计算缓存，始终从API获取实时数据")
    }
    
    // 获取运动类型列表（兼容两种方式）
    private var exerciseTypes: [ExerciseType] {
        // 直接返回API返回的运动类型，不进行任何转换
        return apiExerciseTypes
    }
    
    /// 计算目标框架（甜品在顶部的位置）
    private func calculateTargetFrame() -> CGRect {
        // 获取屏幕尺寸
        let screenWidth = screenSize.width
        
        // 图像尺寸
        let imageSize: CGFloat = min(screenWidth * 0.3, 100)
        
        // 卡片到顶部的距离
        let topPadding: CGFloat = 80
        
        // 设置图像在顶部居中
        let imageX = (screenWidth - imageSize) / 2
        let imageY = topPadding
        
        return CGRect(x: imageX, y: imageY, width: imageSize, height: imageSize)
    }
    
    /// 计算两个框架之间的插值
    private func calculateIntermediateFrame(from: CGRect, to: CGRect, progress: Double) -> CGRect {
        let clampedProgress = min(max(progress, 0), 1)
        
        let x = from.origin.x + (to.origin.x - from.origin.x) * clampedProgress
        let y = from.origin.y + (to.origin.y - from.origin.y) * clampedProgress
        let width = from.width + (to.width - from.width) * clampedProgress
        let height = from.height + (to.height - from.height) * clampedProgress
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    /// 获取甜品卡路里
    private var calories: Double {
        guard let selectedDessert = animationState.selectedDessert else { return 0 }
        if let calValue = Double(selectedDessert.calories.replacingOccurrences(of: "kcal", with: "")) {
            return calValue
        }
        return 0
    }
    
    /// 不需要在前端计算建议时长，直接使用API返回值
    
    /// 不需要在前端计算建议距离，直接使用API返回值
    
    /// 从API加载运动类型
    private func loadExerciseTypes() {
        isLoadingExerciseTypes = true
        loadingError = nil
        
        APIService.shared.fetchExerciseTypes()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    isLoadingExerciseTypes = false
                    if case .failure(let error) = completion {
                        loadingError = error.errorMessage
                        // 加载失败时使用本地定义的运动类型
                        print("加载运动类型失败: \(error.errorMessage)")
                    }
                },
                receiveValue: { types in
                    apiExerciseTypes = types
                    isLoadingExerciseTypes = false
                    
                    // 获取到运动类型后立即计算所有类型的建议时间/距离
                    if let dessert = animationState.selectedDessert,
                       let caloriesValue = Double(dessert.calories.replacingOccurrences(of: "kcal", with: "")) {
                        self.preloadAllExerciseCalculations(calories: caloriesValue)
                    }
                }
            )
            .store(in: &CancellableStorage.shared.cancellables)
    }
    
    /// 加载运动计算结果
    private func loadExerciseCalculation(for exerciseType: ExerciseType) {
        // 使用新的方法选择运动类型
        selectExerciseType(exerciseType)
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
    
    /// 提交运动记录
    private func submitWorkout() {
        guard let dessert = animationState.selectedDessert,
              let exerciseType = selectedExercise else {
            return
        }
        
        // 设置加载状态
        isLoading = true
        errorMessage = nil
        
        // 计算消耗的甜品数量
        var equivalentDessertCount: Double = 1.0
        
        if exerciseType.usesDistance {
            // 基于距离计算比例
            if let baseDistance = calculatedDistances[exerciseType], baseDistance > 0 {
                equivalentDessertCount = exerciseDistance / baseDistance
            }
        } else {
            // 基于时间计算比例
            if let baseDuration = calculatedDurations[exerciseType], baseDuration > 0 {
                equivalentDessertCount = exerciseDuration / baseDuration
            }
        }
        
        // 精确到小数点后两位
        equivalentDessertCount = (equivalentDessertCount * 100).rounded() / 100
        
        // 构建API请求参数
        var params: [String: Any] = [
            // 直接使用原始dessert.id，现在它已经是String类型
            "dessert_id": dessert.id,
            "exercise_type": exerciseType.type,
            "equivalent_dessert_count": Double(equivalentDessertCount), // 确保是Double类型
            "note": ""
        ]
        
        // 根据运动类型添加时长或距离
        if exerciseType.usesDistance {
            // 确保距离是Double类型
            let distanceInKm = Double(exerciseDistance) / 1000.0
            params["distance"] = distanceInKm // 转换为公里
        } else {
            // 确保时长是Double类型
            params["duration"] = Double(exerciseDuration)
        }
        
        // 添加详细日志记录
        DRDebug("提交运动记录 - 详细参数：")
        for (key, value) in params {
            DRDebug("参数[\(key)] = \(value), 类型: \(type(of: value))")
        }
        
        DRDebug("甜品ID: \(dessert.id), 名称: \(dessert.name)")
        DRDebug("运动类型: \(exerciseType.type), 名称: \(exerciseType.name)")
        DRDebug("等效甜品数量: \(equivalentDessertCount), 类型: \(type(of: equivalentDessertCount))")
        
        if exerciseType.usesDistance {
            let distance = exerciseDistance / 1000
            DRDebug("运动距离: \(distance)公里, 类型: \(type(of: distance))")
        } else {
            DRDebug("运动时间: \(exerciseDuration)分钟, 类型: \(type(of: exerciseDuration))")
        }
        
        // 将完整参数转为JSON字符串输出
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                DRDebug("完整的JSON参数: \n\(jsonString)")
            }
        } catch {
            DRError("无法序列化参数到JSON: \(error.localizedDescription)")
        }
        
        // 调用API创建运动记录
        APIService.shared.createWorkoutRecord(params: params)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        self.errorMessage = error.errorMessage
                        DRError("创建运动记录失败: \(error.errorMessage)")
                        
                        // 增加更详细的错误信息
                        if let apiError = error
                            as? APIServiceError {
                            DRError("API错误详情: \(apiError)")
                            
                            if case .networkError(let networkError) = apiError {
                                DRError("网络错误详情: \(networkError)")
                            }
                        }
                    }
                },
                receiveValue: { response in
                    self.isLoading = false
                    
                    // 设置刚完成打卡标记，用于触发动画
                    appState.justCompletedWorkout = true
                    
                    // 手动添加记录到本地状态
                    if let record = response {
                        appState.addWorkoutRecord(record)
                        DRInfo("成功创建运动记录: \(record.id)")
                    }
                    
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
            )
            .store(in: &CancellableStorage.shared.cancellables)
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
            .onAppear {
                // 在视图出现时加载运动类型数据
                DispatchQueue.main.async {
                    // 通过APIService直接请求数据
                    APIService.shared.fetchExerciseTypes()
                        .receive(on: DispatchQueue.main)
                        .sink(
                            receiveCompletion: { completion in
                                self.isLoadingExerciseTypes = false
                                if case .failure(let error) = completion {
                                    self.loadingError = error.errorMessage
                                    print("加载运动类型失败: \(error.errorMessage)")
                                }
                            },
                            receiveValue: { types in
                                self.apiExerciseTypes = types
                                self.isLoadingExerciseTypes = false
                                
                                // 获取到运动类型后立即计算所有类型的建议时间/距离
                                if let dessert = animationState.selectedDessert,
                                   let caloriesValue = Double(dessert.calories.replacingOccurrences(of: "kcal", with: "")) {
                                    self.preloadAllExerciseCalculations(calories: caloriesValue)
                                }
                            }
                        )
                        .store(in: &CancellableStorage.shared.cancellables)
                }
            }
        }
    }
    
    // MARK: - 提取的子视图
    
    /// 甜品图片视图
    private var dessertImageView: some View {
        Group {
            if let dessert = animationState.selectedDessert {
                // 使用DessertImageView组件显示甜品图片
                DessertImageView(
                    dessert: dessert,
                    type: .regular
                    // 不指定size，让外部frame控制大小
                )
                .frame(width: currentPosition.width, height: currentPosition.height)
                .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
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
                    // 不需要额外图片，因为从气泡移动过来的图片已经使用DessertImageView
                    
                    Text("运动目标：\(dessert.name)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    
                    Text("（约\(Int(calories))卡路里）")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                        .padding(.bottom, 5)
                }
                .padding(.bottom, 15)
            }
        }
    }
    
    /// 运动列表视图
    private var exerciseListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(exerciseTypes, id: \.self) { exerciseType in
                    exerciseRowView(for: exerciseType)
                }
            }
            .padding(.bottom, 20)
        }
    }
    
    /// 单个运动类型行视图
    private func exerciseRowView(for exerciseType: ExerciseType) -> some View {
        // 使用预计算的结果
        let requiredValueText: String
        if animationState.selectedDessert != nil {
            if exerciseType.usesDistance {
                // 优先使用预计算的距离，如果没有则显示加载中
                if let distance = calculatedDistances[exerciseType] {
                    requiredValueText = "约\(String(format: "%.1f", distance / 1000))公里"
                } else {
                    requiredValueText = "加载中..."
                }
            } else {
                // 优先使用预计算的时间，如果没有则显示加载中
                if let duration = calculatedDurations[exerciseType] {
                    requiredValueText = "约\(Int(duration))分钟"
                } else {
                    requiredValueText = "加载中..."
                }
            }
        } else {
            requiredValueText = "选择甜品计算所需运动量"
        }
        
        return VStack(spacing: 0) {
            // 主要卡片
        Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    if expandedExerciseID == exerciseType.type {
                        // 如果已经展开，则关闭
                        expandedExerciseID = nil
                        selectedExercise = nil
                    } else {
                        // 展开此运动类型
                        expandedExerciseID = exerciseType.type
                        selectedExercise = exerciseType
                        
                        // 尝试从服务器获取计算结果
                        loadExerciseCalculation(for: exerciseType)
                    }
                }
        }) {
            HStack(spacing: 0) {
                    // 直接显示彩色图标，不使用圆圈
                    Image(systemName: exerciseType.iconName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(exerciseType.color)
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
                    if expandedExerciseID == exerciseType.type {
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
                                    .fill(exerciseType.color)
                            )
                            .padding(.trailing, 16)
                    }
                }
                .frame(height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "F8F8F8"))
                        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
                )
            }
            .buttonStyle(CustomScaleButtonStyle())
            
            // 展开的配置区域
            if expandedExerciseID == exerciseType.type {
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
        // 设置当前选择的运动类型
        let isCurrentType = selectedExercise == exerciseType
        
        // 声明指示是否使用距离的变量
        @State var localUsesDistance: Bool = exerciseType.usesDistance
        
        // 食品消息状态变量
        @State var foodMessageForDistance: String = "计算中..."
        @State var foodMessageForTime: String = "计算中..."
        
        // 当选择一个新的运动类型时，加载计算结果
        if !isCurrentType {
            DispatchQueue.main.async {
                self.selectedExercise = exerciseType
                
                // 重置输入，加载新计算
                if exerciseType.usesDistance {
                    self.exerciseDuration = 0
                } else {
                    self.exerciseDistance = 0
                }
                
                // 立即加载计算结果
                self.loadExerciseCalculation(for: exerciseType)
                
                // 如果已经计算过这个运动类型，使用之前的计算结果
                if let duration = self.calculatedDurations[exerciseType], self.exerciseDuration == 0 {
                    self.exerciseDuration = duration
                }
                
                if let distance = self.calculatedDistances[exerciseType], self.exerciseDistance == 0 {
                    self.exerciseDistance = distance
                }
                
                // 更新甜点消耗估算
                self.updateFoodConsumptionMessage(for: exerciseType)
            }
        }
        
        // 提取当前的甜点名称
        let dessertName = animationState.selectedDessert?.name ?? ""
        
        // 计算食品消息
        let currentFoodMessageForDistance = calculateFoodMessageForDistance(exerciseType: exerciseType, dessertName: dessertName)
        let currentFoodMessageForTime = calculateFoodMessageForTime(exerciseType: exerciseType, dessertName: dessertName)
        
        return VStack(spacing: 20) {
            if animationState.selectedDessert != nil {
                if exerciseType.usesDistance {
                    // 距离选择
                    VStack(alignment: .center, spacing: 8) {
                        Text("运动距离")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                        
                        HStack {
                            Button(action: {
                                exerciseDistance = max(100, exerciseDistance - 500)
                                updateFoodConsumptionMessage(for: exerciseType)
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Color(hex: "F3F3F3")))
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
                                updateFoodConsumptionMessage(for: exerciseType)
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(exerciseType.color)
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        Text(currentFoodMessageForDistance)
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
                                updateFoodConsumptionMessage(for: exerciseType)
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Color(hex: "F3F3F3")))
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
                                updateFoodConsumptionMessage(for: exerciseType)
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(exerciseType.color)
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        Text(currentFoodMessageForTime)
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
            
            // 打卡按钮
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
                            gradient: Gradient(colors: [Color(hex: "FF5E57"), Color(hex: "FF2D55")]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .cornerRadius(25)
                    )
                    .shadow(color: Color(hex: "FF2D55").opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "F8F8F8"))
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }
    
    // 计算距离对应的食品消息
    private func calculateFoodMessageForDistance(exerciseType: ExerciseType, dessertName: String) -> String {
        // 使用guard let安全解包
        guard let baseDistance = calculatedDistances[exerciseType] else {
            return "计算中..."
        }
        
        if baseDistance > 0 {
            let foodCount = exerciseDistance / baseDistance
            return "预计消耗\(String(format: "%.1f", foodCount))个\(dessertName)"
        } else {
            return "计算中..."
        }
    }
    
    // 计算时间对应的食品消息
    private func calculateFoodMessageForTime(exerciseType: ExerciseType, dessertName: String) -> String {
        // 使用guard let安全解包
        guard let baseDuration = calculatedDurations[exerciseType] else {
            return "计算中..."
        }
        
        if baseDuration > 0 {
            let foodCount = exerciseDuration / baseDuration
            return "预计消耗\(String(format: "%.1f", foodCount))个\(dessertName)"
        } else {
            return "计算中..."
        }
    }
    
    // 更新甜点消耗估算信息
    private func updateFoodConsumptionMessage(for exerciseType: ExerciseType) {
        // 方法实现不需要包含任何代码，因为我们已经将计算逻辑移到了独立的函数中
    }
    
    /// 获取运动类型专属渐变色
    private func getGradientColors(for exerciseType: ExerciseType) -> [Color] {
        return [exerciseType.color, exerciseType.color]
        }
    
    /// 添加方法来预加载所有运动类型的计算结果
    private func preloadAllExerciseCalculations(calories: Double) {
        for exerciseType in apiExerciseTypes {
            let typeStr = exerciseType.type
            
            // 获取当前登录用户的体重
            let weight = AuthService.shared.currentUser?.bodyData?.weight ?? 0.0
            let weightInt = Int(weight)
            
            if exerciseType.usesDistance {
                // 距离类型运动 - 直接使用API返回的usesDistance字段
                // 始终发起网络请求，不再使用缓存
                requestExerciseDistance(exerciseType: exerciseType, typeStr: typeStr, calories: calories, retryCount: 3, cacheKey: "")
            } else {
                // 时间类型运动
                // 始终发起网络请求，不再使用缓存
                requestExerciseDuration(exerciseType: exerciseType, typeStr: typeStr, calories: calories, retryCount: 3, cacheKey: "")
            }
        }
    }
    
    /// 请求运动距离（带重试机制）
    private func requestExerciseDistance(exerciseType: ExerciseType, typeStr: String, calories: Double, retryCount: Int, cacheKey: String) {
        if retryCount <= 0 {
            print("距离计算请求失败: 已达最大重试次数")
            return
        }
        
        APIService.shared.calculateExerciseDistance(exerciseType: typeStr, calories: calories)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("距离计算请求失败(\(4-retryCount)/3): \(error.errorMessage)")
                        // 重试
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.requestExerciseDistance(exerciseType: exerciseType, typeStr: typeStr, calories: calories, retryCount: retryCount - 1, cacheKey: cacheKey)
                        }
                    }
                },
                receiveValue: { response in
                    if let response = response {
                        // 直接使用API返回的距离结果，不进行任何计算
                        let distance = response.distance * 1000 // 仅转换单位：公里→米
                        print("获取到距离计算结果: \(distance)米")
                        self.calculatedDistances[exerciseType] = distance
                        // 不再缓存结果
                    }
                }
            )
            .store(in: &CancellableStorage.shared.cancellables)
    }
    
    /// 请求运动时间（带重试机制）
    private func requestExerciseDuration(exerciseType: ExerciseType, typeStr: String, calories: Double, retryCount: Int, cacheKey: String) {
        if retryCount <= 0 {
            print("时间计算请求失败: 已达最大重试次数")
            return
        }
        
        APIService.shared.calculateExerciseTime(exerciseType: typeStr, calories: calories)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("时间计算请求失败(\(4-retryCount)/3): \(error.errorMessage)")
                        // 重试
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.requestExerciseDuration(exerciseType: exerciseType, typeStr: typeStr, calories: calories, retryCount: retryCount - 1, cacheKey: cacheKey)
                        }
                    }
                },
                receiveValue: { response in
                    if let response = response {
                        // 直接使用API返回的时间结果，不进行任何计算
                        print("获取到时间计算结果: \(response.duration)分钟")
                        self.calculatedDurations[exerciseType] = response.duration
                        // 不再缓存结果
                    }
                }
            )
            .store(in: &CancellableStorage.shared.cancellables)
    }
    
    /// 选择运动类型
    private func selectExerciseType(_ exerciseType: ExerciseType) {
        self.selectedExercise = exerciseType
        self.expandedExerciseID = exerciseType.type
        
        // 清除数据
        errorMessage = nil
        isLoading = true
        
        // 根据API返回的usesDistance字段直接决定使用哪种计算方式
        if exerciseType.usesDistance {
            self.calculateDistance(exerciseType)
        } else {
            self.calculateTime(exerciseType)
        }
    }
    
    /// 计算运动时间
    private func calculateTime(_ exerciseType: ExerciseType) {
        guard let dessert = animationState.selectedDessert, let calories = Double(dessert.calories.replacingOccurrences(of: "kcal", with: "")) else {
            isLoading = false
            return
        }
        
        DRInfo("请求计算运动时间: 类型=\(exerciseType.name), 卡路里=\(calories)")
        
        APIService.shared.calculateExerciseTime(exerciseType: exerciseType.type, calories: calories)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        self.errorMessage = error.errorMessage
                        DRError("计算运动时间失败: \(error.errorMessage)")
                    }
                },
                receiveValue: { response in
                    self.isLoading = false
                    guard let response = response else {
                        DRError("API返回空数据")
                        self.errorMessage = "服务器返回空数据，请稍后再试"
                        return
                    }
                    
                    // 保存API返回的计算结果
                    let duration = response.duration
                    self.exerciseDuration = duration
                    self.calculatedDurations[exerciseType] = duration
                    DRInfo("API实时计算运动时间: \(duration)分钟，体重: \(response.weight)kg")
                }
            )
            .store(in: &CancellableStorage.shared.cancellables)
    }
    
    /// 计算运动距离
    private func calculateDistance(_ exerciseType: ExerciseType) {
        guard let dessert = animationState.selectedDessert, let calories = Double(dessert.calories.replacingOccurrences(of: "kcal", with: "")) else {
            isLoading = false
            return
        }
        
        DRInfo("请求计算运动距离: 类型=\(exerciseType.name), 卡路里=\(calories)")
        
        APIService.shared.calculateExerciseDistance(exerciseType: exerciseType.type, calories: calories)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoading = false
                    if case .failure(let error) = completion {
                        self.errorMessage = error.errorMessage
                        DRError("计算运动距离失败: \(error.errorMessage)")
                    }
                },
                receiveValue: { response in
                    self.isLoading = false
                    guard let response = response else {
                        DRError("API返回空数据")
                        self.errorMessage = "服务器返回空数据，请稍后再试"
                        return
                    }
                    
                    // 保存API返回的计算结果，直接使用API结果，不在前端进行任何计算
                    let distance = response.distance * 1000 // 仅转换单位：公里→米
                    self.exerciseDistance = distance
                    self.calculatedDistances[exerciseType] = distance
                    DRInfo("API实时计算运动距离: \(distance)米，体重: \(response.weight)kg")
                }
            )
            .store(in: &CancellableStorage.shared.cancellables)
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

// MARK: - 缓存管理
extension DessertToExerciseTransition {
    /// 清除所有旧版运动计算缓存
    static func clearLegacyExerciseCalculationCaches() {
        // 获取所有UserDefaults键
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        // 清除所有距离和时间计算缓存
        var clearedCount = 0
        for key in allKeys {
            if key.starts(with: "distance_") || key.starts(with: "duration_") {
                userDefaults.removeObject(forKey: key)
                clearedCount += 1
            }
        }
        
        DRInfo("已清除\(clearedCount)项旧版运动计算缓存，当前版本已禁用缓存机制")
    }
    
    /// 清除所有运动计算缓存（向后兼容）
    @available(*, deprecated, message: "使用clearLegacyExerciseCalculationCaches代替")
    static func clearAllExerciseCalculationCaches() {
        clearLegacyExerciseCalculationCaches()
    }
} 

