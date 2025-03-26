# DessertRun - Swift版气泡UI甜品菜单

一个基于Swift/SwiftUI实现的甜品菜单应用，使用类似Apple Watch的气泡UI界面展示甜品选项。

## 项目特点

- 完全使用Swift原生开发
- 实现Apple Watch风格的气泡UI布局
- 支持平滑滚动和动态缩放效果
- 自适应布局设计

## 技术细节

### 算法参考
参考一个react的项目，将其核心算法迁移到swiftUI上。
Demo：https://bubbleui.blakesanie.com/#/demo
Design Overview：https://codeburst.io/deconstructing-the-iconic-apple-watch-bubble-ui-aba68a405689
Resource Code：Documents/App/DessertRun_root/React-Bubble-UI

## 项目结构

```
DessertRun/
├── DessertRunApp.swift            # 应用入口
├── Assets.xcassets/               # 图片资源
├── Preview Content/               # 预览资源
├── Models/                        # 数据模型
│   ├── DessertItem.swift          # 甜品数据模型
│   └── BubbleState.swift          # 气泡状态模型
├── Views/                         # 视图组件
│   ├── ContentView.swift          # 主内容视图
│   ├── Components/                # 可复用组件
│   │   ├── BubbleView.swift       # 单个气泡视图
│   │   ├── BubbleGuideView.swift  # 辅助参考线视图
│   │   └── ColorExtensions.swift  # 颜色扩展
│   └── Screens/                   # 应用页面
│       ├── DessertGridView.swift  # 甜品网格视图
│       └── DessertDetailView.swift # 甜品详情页
└── Layouts/                       # 布局组件
    ├── BubbleLayout.swift         # 气泡布局主组件
    ├── BubbleLayoutConfiguration.swift # 布局配置
    ├── BubbleGeometryCalculator.swift # 几何计算工具
    └── BubblePositionProvider.swift  # 位置提供者
```

### 模块职责

1. **Models/**：数据模型定义
   - DessertItem：甜品数据模型
   - BubbleState：气泡状态模型，包含位置、大小等信息

2. **Views/Components/**：可复用UI组件
   - BubbleView：单个气泡的可视化组件
   - BubbleGuideView：显示布局参考线的辅助组件
   - ColorExtensions：颜色处理扩展

3. **Views/Screens/**：应用主要页面
   - DessertGridView：显示甜品网格的主页面
   - DessertDetailView：甜品详情页面

4. **Layouts/**：布局系统核心组件
   - BubbleLayout：气泡UI的主布局组件
   - BubbleLayoutConfiguration：布局配置参数
   - BubbleGeometryCalculator：处理气泡位置、大小计算的工具类
   - BubblePositionProvider：提供初始气泡位置的工具类

### 布局算法

该项目实现了与React-Bubble-UI完全相同的气泡UI布局算法，包括：

1. **区域划分**：中心区域、过渡区域和外部区域
2. **尺寸计算**：基于位置动态调整气泡大小
3. **紧凑布局**：实现类似Apple Watch的紧凑排列
4. **引力效果**：外部气泡向中心聚拢
5. **蜂窝状网格**：采用六边形排列提高视觉效果

### 主要组件

- `BubbleLayout`：核心布局组件
- `BubbleItemView`：单个气泡视图
- `DessertDetailView`：甜品详情页面

## 数据模型

```swift
struct DessertItem: Identifiable {
    let id: Int
    let name: String
    let imageName: String
    let price: String
    let calories: String
}
```

## 完整配置参数

布局可通过以下参数自定义：

- `bubbleSize`：气泡最大尺寸
- `minBubbleSize`：气泡最小尺寸
- `gutter`：气泡间距
- `provideProps`：是否向子组件传递特殊属性
- `numCols`：排列的列数
- `fringeWidth`：过渡区域宽度
- `yRadius`：中心区域垂直半径
- `xRadius`：中心区域水平半径
- `cornerRadius`：中心区域圆角半径
- `showGuides`：显示/隐藏参考线
- `compact`：启用/禁用紧凑布局
- `gravitation`：引力效果强度(0-1)

## 使用方法

详见示例代码和项目文档。

## 原理分析

该项目基于文章"Deconstructing the Iconic Apple Watch Bubble UI"实现，
完整算法请参考：https://codeburst.io/deconstructing-the-iconic-apple-watch-bubble-ui-aba68a405689

## 开发进度

- [x] 完成核心布局算法
- [x] 实现SwiftUI适配
- [ ] 添加甜品详情页
- [ ] 实现动画效果

## 完整气泡配置参数

```swift
struct BubbleLayoutConfiguration {
    // 布局主要参数
    var bubbleSize: CGFloat = 200        // 气泡最大尺寸
    var minBubbleSize: CGFloat = 20      // 气泡最小尺寸
    var gutter: CGFloat = 16             // 气泡间隔
    var provideProps: Bool = false       // 是否向子组件传递特殊属性
    var numCols: Int = 6                 // 排列的列数
    var fringeWidth: CGFloat = 100       // 过渡区域宽度
    var yRadius: CGFloat = 200           // 中心区域垂直半径
    var xRadius: CGFloat = 200           // 中心区域水平半径
    var cornerRadius: CGFloat = 100      // 中心区域圆角半径
    var showGuides: Bool = false         // 显示参考线
    var compact: Bool = false            // 紧凑模式
    var gravitation: CGFloat = 0         // 引力效果(0-1)
    
    // 计算属性
    var maxSize: CGFloat { bubbleSize }
    var minSize: CGFloat { minBubbleSize }
}
```

## 蜂窝状网格排列

```swift
private func arrangeBubblesInHoneycombGrid() {
    let totalItems = bubbleViews.count
    let itemsPerRow = configuration.numCols
    
    for (index, bubbleView) in bubbleViews.enumerated() {
        // 添加视图到容器
        self.addSubview(bubbleView)
        
        // 计算行和列
        let row = index / itemsPerRow
        let col = index % itemsPerRow
        
        // 计算初始位置（交错的蜂窝状布局）
        let isOddRow = row % 2 != 0
        let xOffset = isOddRow ? configuration.bubbleSize / 2 : 0
        
        let x = CGFloat(col) * (configuration.bubbleSize + configuration.gutter) + xOffset
        let y = CGFloat(row) * (configuration.bubbleSize + configuration.gutter) * 0.866 // 六边形排列的垂直偏移
        
        // 存储初始状态
        let initialPosition = CGPoint(x: x, y: y)
        let region = determineRegion(position: initialPosition, config: configuration)
        let size = calculateBubbleSize(position: initialPosition, region: region, config: configuration)
        
        bubbleStates.append(BubbleState(
            size: size,
            position: initialPosition,
            originalPosition: initialPosition,
            scale: size / configuration.bubbleSize,
            distanceToCenter: distance(from: initialPosition, to: .zero),
            region: region
        ))
    }
}
```

## 应用状态到视图

```swift
private func applyState(state: BubbleState, toView view: UIView) {
    // 设置尺寸
    view.frame.size = CGSize(width: state.size, height: state.size)
    
    // 设置位置（居中）
    view.center = CGPoint(
        x: self.bounds.width / 2 + state.position.x,
        y: self.bounds.height / 2 + state.position.y
    )
    
    // 只在启用provideProps时传递属性给子视图
    if configuration.provideProps {
        if let bubbleItem = view as? BubbleItemView {
            bubbleItem.updateWithState(
                bubbleSize: state.size,
                distanceToCenter: state.distanceToCenter,
                maxSize: configuration.bubbleSize,
                minSize: configuration.minBubbleSize
            )
        }
    }
}
```

## 气泡排列算法

考虑到原始实现中的特殊排列方式

```swift
private func calculateBubblePositions() {
    let totalItems = bubbleViews.count
    let maxCols = configuration.numCols
    
    var positions: [CGPoint] = []
    var currentRow = 0
    var currentCol = 0
    
    // 根据原始React-Bubble-UI的排列逻辑计算位置
    for i in 0..<totalItems {
        // 是否为奇数行
        let isOddRow = currentRow % 2 != 0
        
        // 行中最大列数
        let colsInThisRow = isOddRow ? maxCols - 1 : maxCols
        
        // 计算X位置，奇数行有偏移
        let xOffset = isOddRow ? configuration.bubbleSize / 2 : 0
        let x = CGFloat(currentCol) * (configuration.bubbleSize + configuration.gutter) + xOffset
        
        // 计算Y位置，使用0.866作为六边形排列的垂直压缩因子
        let y = CGFloat(currentRow) * (configuration.bubbleSize + configuration.gutter) * 0.866
        
        positions.append(CGPoint(x: x, y: y))
        
        // 更新列计数
        currentCol += 1
        
        // 如果达到当前行的最大列数，转到下一行
        if currentCol >= colsInThisRow {
            currentRow += 1
            currentCol = 0
        }
    }
    
    return positions
}
```

## 气泡UI协议 - 确保一致的属性传递
protocol BubbleItemProtocol {
    func updateWithState(bubbleSize: CGFloat, distanceToCenter: CGFloat, maxSize: CGFloat, minSize: CGFloat)
}

// 更新气泡视图实现
class BubbleItemView: UIView, BubbleItemProtocol {
    // ... 其他代码 ...
    
    // 实现协议方法
    func updateWithState(bubbleSize: CGFloat, distanceToCenter: CGFloat, maxSize: CGFloat, minSize: CGFloat) {
        // 计算当前比例
        let scale = bubbleSize / maxSize
        
        // 基于距离中心远近调整透明度
        let opacity = 0.5 + 0.5 * (1.0 - min(distanceToCenter / 500, 1.0))
        
        // 应用透明度
        contentView.alpha = opacity
        
        // 调整字体大小
        titleLabel.font = .systemFont(ofSize: 10 + 2 * scale, weight: .medium)
        
        // 可以根据需要添加更多属性
    }
}

## 修正SwiftUI版本参数
struct BubbleLayout<Item: Identifiable, Content: View>: View {
    // 配置参数
    private var config: BubbleLayoutConfiguration
    
    // 数据和内容
    private var items: [Item]
    private var content: (Item, BubbleState) -> Content
    
    // 状态
    @State private var contentOffset: CGPoint = .zero
    @State private var bubbleStates: [UUID: BubbleState] = [:]
    
    init(
        items: [Item], 
        config: BubbleLayoutConfiguration = BubbleLayoutConfiguration(),
        @ViewBuilder content: @escaping (Item, BubbleState) -> Content
    ) {
        self.items = items
        self.config = config
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 可选：显示参考线
                if config.showGuides {
                    BubbleGuideView(config: config)
                }
                
                // 气泡内容
                ForEach(items) { item in
                    let state = bubbleState(for: item, in: geometry)
                    
                    if config.provideProps {
                        content(item, state)
                            .frame(width: state.size, height: state.size)
                            .position(
                                x: geometry.size.width / 2 + state.position.x,
                                y: geometry.size.height / 2 + state.position.y
                            )
                    } else {
                        content(item, BubbleState(
                            size: config.bubbleSize,
                            position: state.position,
                            originalPosition: state.originalPosition,
                            scale: 1.0,
                            distanceToCenter: 0,
                            region: .center
                        ))
                        .frame(width: state.size, height: state.size)
                        .position(
                            x: geometry.size.width / 2 + state.position.x,
                            y: geometry.size.height / 2 + state.position.y
                        )
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        contentOffset.x -= value.translation.width - value.startLocation.x
                        contentOffset.y -= value.translation.height - value.startLocation.y
                    }
            )
        }
    }
    
    // ... 其他代码 ...
}

struct ContentView: View {
    // 甜品数据
    let desserts = [
        DessertItem(id: 1, name: "草莓蛋糕", imageName: "strawberry_cake", price: "32", calories: "280"),
        DessertItem(id: 2, name: "巧克力慕斯", imageName: "chocolate_mousse", price: "38", calories: "320"),
        DessertItem(id: 3, name: "蓝莓芝士", imageName: "blueberry_cheese", price: "42", calories: "350"),
        // ... 其他甜品
    ]
    
    // 布局配置
    let bubbleConfig = BubbleLayoutConfiguration(
        bubbleSize: 130,
        minBubbleSize: 60,
        gutter: 14,
        provideProps: true,
        numCols: 5,
        fringeWidth: 80,
        yRadius: 150,
        xRadius: 150,
        cornerRadius: 70,
        showGuides: false,
        compact: true,
        gravitation: 5
    )
    
    // 选中的甜品
    @State private var selectedDessert: DessertItem?
    
    var body: some View {
        ZStack {
            // 背景
            Color(hex: "fae8c8").ignoresSafeArea()
            
            // 气泡布局
            BubbleLayout(
                items: desserts,
                config: bubbleConfig
            ) { dessert, state in
                // 单个气泡内容
                BubbleView(
                    item: dessert,
                    bubbleSize: state.size,
                    distanceToCenter: state.distanceToCenter,
                    maxSize: bubbleConfig.bubbleSize,
                    minSize: bubbleConfig.minBubbleSize,
                    onTap: {
                        selectedDessert = dessert
                    }
                )
            }
        }
        .sheet(item: $selectedDessert) { dessert in
            // 详情页
            DessertDetailView(dessert: dessert)
        }
    }
}

## 气泡视图设计扩展性
建议将BubbleView设计成高度可配置的组件。（目前先用圆形代替图案）

## 屏幕适配
BubbleLayout完全支持不同屏幕尺寸，无需手动设置固定宽高。通过GeometryReader自动适配、相对尺寸计算、宽高比例设计、安全区适配的机制来保证
cursor建议为不同屏幕尺寸提供动态配置。

## 如何调整
如果您希望进一步微调参数，可以修改foriPhone16()方法中的参数：
增大yRadius和xRadius可以让中心区域显示更多大气泡
调整bubbleSize可以改变气泡的大小
修改numCols可以改变每行的气泡数量