# DessertRun 扩展库文档

本文档介绍了DessertRun应用程序中所有可用的扩展功能。通过这些扩展，可以简化开发流程并提高代码可维护性。

## 目录结构

```
Extensions/
├── View/                  # 视图相关扩展
│   ├── CornerRadiusExtension.swift      # 圆角扩展
│   ├── AnimationExtension.swift         # 动画扩展
│   ├── ConditionalModifierExtension.swift # 条件修饰符扩展
│   ├── FrameObserverExtension.swift     # 框架观察器扩展
│   ├── ViewStateExtension.swift         # 视图状态管理扩展
│   └── TextStyleExtension.swift         # 文本样式扩展
├── Foundation/            # 基础类型扩展
│   ├── DateExtension.swift             # 日期扩展
│   ├── StringExtension.swift           # 字符串扩展
│   └── NumberExtension.swift           # 数字扩展
├── Color/                 # 颜色相关扩展
│   └── ColorExtension.swift            # 颜色扩展
└── System/                # 系统功能扩展
    ├── NotificationExtension.swift     # 通知扩展
    └── HealthKitExtension.swift        # HealthKit扩展
```

## 视图扩展 (View/)

### 圆角扩展 (CornerRadiusExtension.swift)

为视图添加指定角的圆角效果。

```swift
// 给视图的所有角添加圆角
myView.cornerRadius(10)

// 只给左上和右上角添加圆角
myView.cornerRadius(10, corners: [.topLeft, .topRight])
```

### 动画扩展 (AnimationExtension.swift)

提供动画完成回调功能。

```swift
// 动画完成后执行操作
Text("Hello")
    .onAnimationCompleted(for: opacity) {
        // 动画完成后执行的代码
    }
```

### 条件修饰符扩展 (ConditionalModifierExtension.swift)

基于条件应用视图修饰符。

```swift
// 条件性应用修饰符
myView.if(isHighlighted) {
    $0.foregroundColor(.red)
}

// 条件分支
myView.if(isEnabled) {
    $0.foregroundColor(.blue)
} else: {
    $0.foregroundColor(.gray)
}
```

### 框架观察器扩展 (FrameObserverExtension.swift)

观察视图框架的变化。

```swift
// 监听视图尺寸变化
myView.observeFrame { frame in
    print("视图尺寸变化为: \(frame)")
}
```

### 视图状态管理扩展 (ViewStateExtension.swift)

管理视图的加载、空状态和错误状态。

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

### 文本样式扩展 (TextStyleExtension.swift)

快速应用文本样式。

```swift
// 标题样式
Text("标题").titleStyle()

// 副标题样式
Text("副标题").subtitleStyle()

// 正文样式
Text("正文").bodyStyle()

// 说明文本样式
Text("说明").captionStyle()

// 按钮样式
Text("点击我").asButton()

// 卡片样式
myView.cardStyle()

// 高亮样式
myView.highlighted()
```

## 基础类型扩展 (Foundation/)

### 日期扩展 (DateExtension.swift)

日期格式化和计算功能。

```swift
// 格式化日期
let dateString = Date().formatted(format: "yyyy年MM月dd日")

// 获取日期组件
let year = Date().year
let month = Date().month
let day = Date().day

// 计算两个日期间隔天数
let days = Date().days(from: someDate)

// 添加天数
let futureDate = Date().adding(days: 7)
```

### 字符串扩展 (StringExtension.swift)

字符串处理功能。

```swift
// 从字符串中提取数字
let number = "价格：123.45元".extractedNumbers // 返回123.45

// 不区分大小写的包含判断
"Hello".containsIgnoringCase("hel") // 返回true

// 裁剪空白
let trimmed = "  hello  ".trimmed // 返回"hello"

// 邮箱验证
"user@example.com".isValidEmail // 返回true
```

### 数字扩展 (NumberExtension.swift)

数字格式化和计算功能。

```swift
// 整数添加前导零
5.paddedWithZero(length: 3) // 返回"005"

// 随机整数
let random = Int.random(max: 100)

// 保留小数位
let rounded = 3.14159.rounded(toPlaces: 2) // 返回3.14

// 数字格式化
let formatted = 3.14159.formatted(toPlaces: 2) // 返回"3.14"

// 单位转换
let meters = 1.5.kilometersToMeters // 返回1500
let kilometers = 1500.metersToKilometers // 返回1.5
```

## 颜色扩展 (Color/)

### 颜色扩展 (ColorExtension.swift)

颜色创建和处理功能。

```swift
// 从十六进制创建颜色
let color = Color(hex: "#FF5500")

// 获取颜色亮度
let brightness = color.brightness

// 获取对比色（黑色或白色）
let contrastingColor = color.contrastingColor
```

## 系统功能扩展 (System/)

### 通知扩展 (NotificationExtension.swift)

本地通知管理。

```swift
// 请求通知权限
let granted = await UNUserNotificationCenter.requestPermission()

// 发送本地通知
UNUserNotificationCenter.scheduleLocalNotification(
    title: "提醒",
    body: "该去跑步了！",
    delay: 60 * 60 // 1小时后
)

// 取消通知
UNUserNotificationCenter.cancelAllPendingNotifications()
```

### HealthKit扩展 (HealthKitExtension.swift)

健康数据访问。

```swift
// 请求HealthKit权限
let granted = await HKHealthStore.requestAuthorization(for: [
    HKQuantityType.quantityType(forIdentifier: .stepCount)!
])

// 获取步数
let healthStore = HKHealthStore()
healthStore.fetchLatestStepCount { steps, error in
    if let steps = steps, error == nil {
        print("最近7天步数: \(steps)")
    }
}

// 获取消耗的卡路里
healthStore.fetchActiveEnergyBurned(from: startDate, to: endDate) { calories, error in
    if let calories = calories, error == nil {
        print("消耗的卡路里: \(calories)")
    }
}
```

## 使用建议

1. **导入方式**：在需要使用扩展的文件顶部导入主模块即可，无需单独导入每个扩展文件。

2. **添加新扩展**：向项目添加新扩展时，请遵循现有的目录结构和命名约定。

3. **文档更新**：添加新扩展后，请更新本文档以保持文档的完整性。

4. **命名规范**：
   - 扩展文件名应以"Extension"结尾
   - 方法名应该清晰描述功能
   - 参数名应该有意义且一致

5. **注释**：为每个扩展方法添加适当的文档注释，包括功能描述、参数说明和返回值说明。 