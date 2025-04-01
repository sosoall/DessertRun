
## 算法参考
参考一个react的项目，将其核心算法迁移到swiftUI上。
Demo：https://bubbleui.blakesanie.com/#/demo
Design Overview：https://codeburst.io/deconstructing-the-iconic-apple-watch-bubble-ui-aba68a405689
Resource Code：Documents/App/DessertRun_root/React-Bubble-UI

## 气泡布局的结构

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

### 气泡布局的模块职责

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

## 气泡布局的算法

该项目实现了与React-Bubble-UI完全相同的气泡UI布局算法，包括：

1. **区域划分**：中心区域、过渡区域和外部区域
2. **尺寸计算**：基于位置动态调整气泡大小
3. **紧凑布局**：实现类似Apple Watch的紧凑排列
4. **引力效果**：外部气泡向中心聚拢
5. **蜂窝状网格**：采用六边形排列提高视觉效果

## 气泡布局的主要组件

- `BubbleLayout`：核心布局组件
- `BubbleItemView`：单个气泡视图
- `DessertDetailView`：甜品详情页面

## 气泡布局的完整配置参数

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

## 气泡视图设计扩展性
建议将BubbleView设计成高度可配置的组件。（目前先用圆形代替图案）

## 气泡布局的屏幕适配
BubbleLayout完全支持不同屏幕尺寸，无需手动设置固定宽高。通过GeometryReader自动适配、相对尺寸计算、宽高比例设计、安全区适配的机制来保证
cursor建议为不同屏幕尺寸提供动态配置。