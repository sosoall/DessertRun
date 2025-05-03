//
//  DessertGridView.swift
//  DessertRun
//
//  Created by Claude on 2025/3/24.
//

import SwiftUI
import Combine

/// 甜品网格视图
struct DessertGridView: View {
    /// 甜品数据状态
    @State private var desserts: [DessertItem] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    
    /// 动画状态管理
    @ObservedObject var animationState: TransitionAnimationState
    
    /// 环境中的应用状态
    @EnvironmentObject var appState: AppState
    
    /// 控制布局刷新
    @State private var forceLayoutUpdate = false
    
    /// 拖动状态回调
    var onDragStateChanged: ((Bool) -> Void)?
    
    // 初始化方法
    init(animationState: TransitionAnimationState, onDragStateChanged: ((Bool) -> Void)? = nil) {
        self.animationState = animationState
        self.onDragStateChanged = onDragStateChanged
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(hex: "FFFFFF")
                .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("加载中...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let error = errorMessage {
                    VStack {
                        Text("加载失败")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Button("重试") {
                            loadDessertData()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else {
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
                                onTap: { bubbleFrame in
                                    
                                    // 计算图片在气泡中的实际大小
                                    // 图片区域大小由气泡大小和当前位置决定
                                    let imageOffset: CGFloat = -50  // 图片顶部偏移
                                    _ = state.size / createConfig(for: geometry.size).bubbleSize  // 当前缩放比例(暂未使用)
                                    
                                    // 计算图片高度，约为气泡高度的70%
                                    //我手动改成了0.95，是因为不能直接改成1，不知道这里有没有问题。后面测试其他机型的时候要重点关注。
                                    let imageHeight = bubbleFrame.height * 0.95
                                    
                                    // 创建图片区域的实际框架，宽度与气泡相同
                                    let imageFrame = CGRect(
                                        x: bubbleFrame.minX,
                                        y: bubbleFrame.minY + imageOffset,
                                        width: bubbleFrame.width,
                                        height: imageHeight
                                    )
                                    
                                    animationState.selectDessert(
                                        dessert,
                                        originFrame: bubbleFrame,
                                        originalSize: state.size,
                                        imageFrame: imageFrame
                                    )
                                }
                            )
                        }
                    )
                    .id(forceLayoutUpdate) // 使用id强制刷新布局
                    .padding(.top, 100) // 为顶部标题留出空间
                }
                
                // 底部空间，保持布局平衡
                VStack {
                    Spacer()
                    
                    // 为底部导航栏预留空间
                    Color.clear
                        .frame(height: 80)
                }
            }
            .coordinateSpace(name: globalCoordinateSpaceName)
            .environmentObject(animationState) // 将animationState作为环境对象提供给子视图
            .onAppear {
                // 加载数据
                loadDessertData()
                
                // 延迟一点时间确保视图布局完成后再刷新气泡布局
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    forceLayoutUpdate.toggle()
                }
            }
        }
    }
    
    /// 创建适合屏幕尺寸的配置
    /// - Parameter size: 屏幕尺寸
    /// - Returns: 布局配置
    private func createConfig(for size: CGSize) -> BubbleLayoutConfiguration {
        return BubbleLayoutConfiguration.forScreenSize(size, bubbleCount: desserts.count)
    }
    
    /// 加载美食数据
    private func loadDessertData() {
        isLoading = true
        errorMessage = nil
        
        // 使用更安全的方法获取甜品数据，避免使用全局订阅集合
        DessertData.getAllDesserts { [self] loadedDesserts in
            let allDesserts = loadedDesserts
            
            // 使用isImportant字段过滤重要甜品
            let important = allDesserts.filter { $0.isFeatured }
            let others = allDesserts.filter { !$0.isFeatured }
            
            // 安排甜品顺序，将重要甜品放在数组中间
            // 蜂窝布局中，中间位置的索引约为数组长度的1/3到2/3之间
            let totalCount = allDesserts.count
            let middleStart = totalCount / 3
            
            // 计算重要甜品和其他甜品各自应该占用的位置
            var result: [DessertItem] = Array(repeating: allDesserts[0], count: totalCount)
            
            // 确保中间部分空间足够放置所有重要甜品
            let middleSpace = totalCount - 2 * middleStart
            if important.count > middleSpace {
                DRWarning("重要甜品数量(\(important.count))超过中间区域空间(\(middleSpace))，将只显示部分重要甜品")
            }
            
            // 先填充前1/3和后1/3位置为其他甜品
            for (index, item) in others.enumerated() {
                if index < middleStart {
                    // 放在前面1/3
                    result[index] = item
                } else if index >= middleStart && index - middleStart < others.count - middleStart {
                    // 计算后1/3部分的索引，确保不越界
                    let targetIndex = middleStart + min(important.count, middleSpace) + (index - middleStart)
                    if targetIndex < result.count {
                        result[targetIndex] = item
                    }
                }
            }
            
            // 中间1/3位置放置重要甜品
            for (index, item) in important.enumerated() {
                // 确保不会越界
                if index < middleSpace && middleStart + index < result.count {
                    result[middleStart + index] = item
                }
            }
            
            // 在主线程更新UI
            DispatchQueue.main.async {
                self.desserts = result
                self.isLoading = false
                self.forceLayoutUpdate.toggle() // 强制刷新布局
            }
        }
    }
} 