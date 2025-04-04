# DessertRun 扩展库

本文档介绍了DessertRun应用程序中所有可用的扩展功能。通过这些扩展，可以简化开发流程并提高代码可维护性。

## 目录结构

```
Extensions/
├── View/                            # 视图相关扩展
│   ├── AnimationExtension.swift     # 动画扩展
│   ├── TextStyleExtension.swift     # 文本样式扩展
│   ├── ViewStateExtension.swift     # 视图状态管理扩展
│   └── ViewUtilityExtensions.swift  # 视图实用工具扩展（包含圆角、样式、条件修饰符等）
├── Color/                           # 颜色相关扩展
│   └── ColorExtension.swift         # 颜色扩展
├── Foundation/                      # 基础类型扩展
│   ├── DateExtension.swift          # 日期扩展
│   ├── StringExtension.swift        # 字符串扩展
│   └── NumberExtension.swift        # 数字扩展
└── System/                          # 系统功能扩展
    ├── NotificationExtension.swift  # 通知扩展
    └── HealthKitExtension.swift     # HealthKit扩展
```

## 视图扩展 (View/)

### 动画扩展 (AnimationExtension.swift)

提供标准动画效果，确保整个应用的动画一致性。

- `standardTransition`: 标准过渡动画，0.5秒，弹性效果
- `standardInterface`: 标准界面动画，0.35秒，缓入缓出
- `standardReverseTransition`: 标准反向过渡动画，0.4秒，减小弹性
- `quickInterface`: 快速界面动画，0.2秒，缓入缓出
- `delayedTransition`: 延迟过渡动画，0.5秒，0.2秒延迟

使用示例：
```swift
// 应用标准界面动画
myView.withStandardAnimation(value: someState)

// 应用导航栏隐藏/显示动画
myView.animatedNavBarHidden(true)

// 应用动画偏移量
myView.animatedOffset(x: 20, y: 0)
```

### 文本样式扩展 (TextStyleExtension.swift)

提供统一的文本样式。

- `Font.DessertRun`: 应用字体样式（largeTitle、title、body、caption）
- `largeTitleStyle()`: 应用大标题样式
- `titleStyle()`: 应用标题样式
- `bodyStyle()`: 应用正文样式
- `captionStyle()`: 应用描述文本样式
- `accentTextStyle()`: 应用强调文本样式

使用示例：
```swift
// 标题样式
Text("标题").titleStyle()

// 正文样式
Text("正文").bodyStyle()

// 强调文本样式
Text("重要信息").accentTextStyle()
```

### 视图状态管理扩展 (ViewStateExtension.swift)

提供视图状态管理功能。

- `loading(isLoading:loadingView:)`: 显示加载状态
- `withEmptyState(for:placeholder:)`: 处理空状态
- `withErrorHandling(error:retryAction:errorContent:)`: 处理错误状态

使用示例：
```swift
// 加载状态
myView.loading(isLoading: $isLoading)

// 自定义加载视图
myView.loading(isLoading: $isLoading) {
    LoadingView()
}

// 空状态
myList.withEmptyState(for: items) {
    Text("暂无数据")
}

// 错误状态
myView.withErrorHandling(error: $error, retryAction: fetchData) { error in
    VStack {
        Text("出错了: \(error.localizedDescription)")
        Button("重试") { fetchData() }
    }
}
```

### 视图实用工具扩展 (ViewUtilityExtensions.swift)

包含多种实用的视图扩展功能：

#### 圆角扩展
- `cornerRadiusExt(_:corners:)`: 为视图的特定角落添加圆角
- `RoundedCornerExt`: 支持特定角落圆角的自定义形状

使用示例：
```swift
// 给视图的所有角添加圆角
myView.cornerRadius(10)

// 只给左上和右上角添加圆角
myView.cornerRadiusExt(10, corners: [.topLeft, .topRight])
```

#### 样式扩展
- `cardShadow(radius:yOffset:)`: 添加卡片样式阴影
- `standardBorder(color:width:)`: 添加标准边框
- `standardPadding()`: 添加标准内边距
- `standardBackground()`: 添加标准背景

使用示例：
```swift
// 添加卡片阴影
myView.cardShadow()

// 添加标准边框
myView.standardBorder()

// 添加标准背景
myView.standardBackground()
```

#### 框架观察扩展
- `observeFrame(onChange:)`: 观察视图框架的变化并执行回调

使用示例：
```swift
// 监听视图尺寸变化
myView.observeFrame { frame in
    print("视图尺寸变化为: \(frame)")
}
```

#### 条件修饰符扩展
- `if(_:transform:)`: 基于条件应用修饰符
- `ifElse(_:ifTransform:elseTransform:)`: 基于条件应用两种不同的修饰符
- `ifLet(_:transform:)`: 基于可选值应用修饰符

使用示例：
```swift
// 条件性应用修饰符
myView.if(isHighlighted) {
    $0.foregroundColor(.red)
}

// 条件分支
myView.ifElse(isEnabled) {
    $0.foregroundColor(.blue)
} else: {
    $0.foregroundColor(.gray)
}
```

## 颜色扩展 (Color/)

### 颜色扩展 (ColorExtension.swift)

提供颜色相关功能。

- `Color(hex:)`: 从十六进制字符串创建颜色
- `Color.DessertRun`: 应用主题颜色（accent、background、textPrimary等）
- `hexString`: 将颜色转换为十六进制字符串
- `brightness`: 估算颜色的亮度
- `contrastingColor`: 获取对比色（黑色或白色）

使用示例：
```swift
// 从十六进制创建颜色
let color = Color(hex: "#FF5500")

// 使用应用主题颜色
Text("强调文本").foregroundColor(Color.DessertRun.accent)
Rectangle().fill(Color.DessertRun.backgroundSecondary)

// 获取颜色亮度
let brightness = color.brightness

// 获取对比色（黑色或白色）
let contrastingColor = color.contrastingColor
```

## 使用最佳实践

1. **在样式设计前创建样式**：在视图代码中使用样式前，确保先在相应的扩展文件中定义好样式。

2. **命名规范**：使用描述性命名，如`standardPadding()`而不是`padding1()`。

3. **文档注释**：为每个扩展和方法提供文档注释，说明其功能和用途。

4. **组织扩展**：将相关功能组织在同一个扩展中，避免过度分散。

5. **避免重复**：检查现有扩展是否已提供需要的功能，避免创建重复的扩展。 