# DessertRun - 零负罪感运动App

DessertRun是一款为运动初学者准备的创新健康应用，核心理念是"零负罪感的运动App"。用户可以通过选择喜爱的美食目标，通过运动"赢得"甜品的方式，激励自己坚持运动。

## 项目特点

1. 完全使用SwiftUI原生开发，后端用GoLang
2. 云端数据存储，支持跨设备数据同步
3. 创新的运动激励机制：以美食为奖励，使运动更有动力
4. 现代化UI设计，大量使用动画和交互效果

## 核心功能

1. **新颖的运动目标**：与其他app的以运动时长、距离、卡路里为目标不同，这个app以美食的热量作为运动目标，使运动效果更直观明确（为了"赢得"某一个食物）。

2. **易完成的运动推荐**：基于所选甜品的热量，推荐适合的、轻松的、无需器械的运动方式，让用户可以轻松消耗热量。

3. **运动过程监控**：运动过程中，用美食动画来陪伴用户。支持暂停、停止、继续，并展示基础运动数据（距离、时间、消耗卡路里等）。

4. **奖励机制**：运动完成后，通过动态动画庆祝，并获得甜品券。

5. **甜品券系统**：支持核销、过期、分享、放入券包等管理功能。根据运动完成度提供完整或部分甜品券。

6. **运动统计**：按日、月、年形象展示用户的运动数据，包括运动时长、距离、获得的甜品券等。

7. **用户系统**：管理用户信息，包括登录、个人资料设置等。

## 技术选型

### 前端技术栈
- **UI框架**：SwiftUI（支持现代UI设计和复杂动画）
- **状态管理**：Combine + @Published属性
- **页面导航**：TabView（底部标签栏）+ NavigationStack/NavigationView（页面跳转）
- **本地缓存**：CoreData（作为云端数据的本地缓存）
- **健康数据**：HealthKit（获取运动数据）
- **位置服务**：CoreLocation（跟踪室外运动）
- **动画效果**：Lottie（实现JSON格式动画）

### 后端技术栈
- **服务端语言**：GoLang
- **API设计**：RESTful API
- **云端数据库**：PostgreSQL（存储用户数据、运动记录等）
- **用户认证**：JWT
- **部署**：Docker + Kubernetes

## 项目架构

采用MVVM（Model-View-ViewModel）架构模式，结合Clean Architecture思想：

```
DessertRun/
├── App/                           # 应用入口和配置
│   ├── DessertRunApp.swift        # 应用入口
│   └── AppState.swift             # 全局应用状态
├── Assets/                        # 资源文件
├── Models/                        # 数据模型
│   ├── User.swift                 # 用户模型
│   ├── DessertItem.swift          # 甜品模型
│   ├── ExerciseType.swift         # 运动类型模型
│   ├── WorkoutSession.swift       # 运动会话模型
│   ├── DessertVoucher.swift       # 甜品券模型
│   └── WorkoutStats.swift         # 运动统计数据模型
├── Views/                         # 视图组件
│   ├── Common/                    # 通用组件
│   ├── Exercise/                  # 运动相关视图
│   │   ├── DessertSelectionView/  # 甜品选择（气泡UI）
│   │   ├── ExerciseTypeView/      # 运动方式选择
│   │   ├── WorkoutView/           # 运动中界面
│   │   └── WorkoutCompleteView/   # 运动完成界面
│   ├── Stats/                     # 统计相关视图
│   │   ├── CalendarView/          # 运动日历
│   │   └── VouchersView/          # 甜品券管理
│   └── Profile/                   # 个人信息相关视图
├── ViewModels/                    # 视图模型
│   ├── ExerciseViewModel.swift    # 运动相关逻辑
│   ├── StatsViewModel.swift       # 统计相关逻辑
│   └── ProfileViewModel.swift     # 个人信息相关逻辑
├── Services/                      # 服务层
│   ├── API/                       # API通信
│   ├── DataSync/                  # 数据同步服务
│   ├── HealthKit/                 # 健康数据服务
│   └── Location/                  # 位置服务
└── Utils/                         # 工具类
    ├── Animations/                # 动画工具
    ├── Extensions/                # 扩展方法
    └── Helpers/                   # 辅助函数
```

## 主要页面设计与实现

### 1. 底部标签栏
应用主界面分为三个主要标签：运动、统计和个人信息。使用TabView实现底部切换。

### 2. 运动模块
整个运动流程分为几个主要环节：

- **选择甜品（运动目标）**:
  - 使用已实现的气泡UI布局展示甜品选项
  - 支持搜索和筛选甜品
  - 点击甜品可查看详情并选择作为目标

- **选择运动方式**:
  - 根据甜品热量，算法推荐适合的运动方式
  - 展示每种运动预计完成所需时间
  - 卡片式设计，支持滑动切换

- **运动中**:
  - 双页面设计：动画激励页和数据详情页
  - 页面1：展示激励性动画、进度条和基础信息
  - 页面2：展示详细运动数据（速度、距离、时间等）
  - 支持左右滑动切换两个页面
  - 运动数据收集：
    - 室外跑步：使用GPS定位
    - 其他运动：结合HealthKit或手动计时

- **运动暂停/完成**:
  - 暂停状态：显示已完成进度、继续按钮和停止按钮
  - 完成状态（达成目标）：展示完整甜品券和庆祝动画
  - 提前结束（未达成目标）：显示部分甜品券，支持继续运动选项

### 3. 统计模块
统计模块分为两个主要部分：

- **运动日历**:
  - 自定义日历视图，显示每日运动打卡状态
  - 支持月度、周度视图切换
  - 点击日期可查看当日详细运动记录
  - 月度数据汇总统计

- **甜品券管理**:
  - 瀑布流展示所有获得的甜品券
  - 券状态区分：有效、过期、已使用
  - 支持券详情查看、分享、核销等操作

### 4. 个人信息模块
- **用户资料**:
  - 基本信息展示与编辑
  - 运动偏好设置
  - 账号管理
  
- **设置**:
  - 通知设置
  - 隐私设置
  - 数据同步选项
  - 其他应用设置

## 数据流设计

### 1. 前端数据管理
- 使用Combine框架处理数据流
- ViewModels发布状态变化，Views订阅更新
- 支持离线模式，本地缓存与云端数据同步

### 2. 云端数据同步
- 登录状态下自动同步数据到云端
- 支持多设备数据同步
- 智能冲突解决策略

### 3. 健康数据集成
- 与HealthKit集成，读取/写入健康数据
- 支持从其他健康应用导入运动数据

## UI设计原则
1. 现代化视觉效果：大量使用阴影、渐变、圆角等效果
2. 动感交互：页面切换、运动进度等位置使用流畅动效
3. 品牌主题色：FE2D55和FF9901，整体风格青春、有活力
4. 简洁明了：每个页面专注展示核心信息，避免信息过载
5. 自适应布局：支持不同iPhone屏幕尺寸

## 开发计划

### 阶段一：前端框架搭建
1. 创建项目基础架构
2. 实现标签栏和基本导航
3. 设计和实现基础UI组件
4. 整合已有的甜品选择气泡UI

### 阶段二：运动核心功能
1. 开发甜品详情页面
2. 实现运动方式推荐算法和UI
3. 开发运动监控页面（动画页和数据页）
4. 实现运动数据收集和处理逻辑
5. 开发运动完成和奖励机制

### 阶段三：统计和用户功能
1. 开发运动日历和数据统计功能
2. 实现甜品券管理系统
3. 开发用户资料和设置页面
4. 实现本地数据持久化

### 阶段四：后端开发与集成
1. 设计和实现API接口
2. 开发用户认证系统
3. 构建云端数据存储
4. 实现前后端数据同步
5. 集成测试和优化

### 阶段五：发布准备
1. 全面测试和Bug修复
2. 性能优化
3. 准备App Store发布材料
4. 应用提交和发布

## 已知问题

### 甜品气泡拖拽卡顿问题
- **问题描述**：当用户手指在气泡上时，无法顺畅拖动页面。点击气泡的操作优先级高于拖动操作，导致用户体验不佳。
- **原因分析**：气泡上的点击手势优先级高于ScrollView的拖动手势，导致系统将手指接触气泡的行为识别为点击而非拖动。
- **临时解决方案**：用户可以将手指放在气泡之外的区域进行拖动。
- **计划解决方案**：需要在BubbleView中修改手势优先级，将拖动手势设置为高于点击手势的优先级。

## 变更日志

### 2025-04-01
1. **UI优化**：
   - 根据Figma设计，将气泡形状从圆形改为圆角方形（squircle）
   - 更新了气泡阴影和内部阴影效果，增强现代感
   - 更新气泡颜色，提高视觉吸引力
   - 添加了标签文字的阴影和背景，提高可读性

2. **页面背景优化**：
   - 将主页背景从单一颜色更改为渐变色效果(FFA751到FFE259)
   - 添加了微妙的径向渐变覆盖层，增加深度感
   - 更新了标题和按钮样式，与新设计保持一致

3. **布局改进**：
   - 调整了气泡大小关系，优化了不同屏幕尺寸的显示效果
   - 更新了栅格系统，增加了大屏幕的列数(从4列到5列)
   - 微调了气泡之间的间距，提高了整体布局的均衡感

5. **版本控制优化**：
   - 创建了.gitignore文件，避免将图片资源文件添加到版本控制系统
   - 配置了忽略临时脚本和构建文件的规则

6. **手势优化**：
   - 修复了气泡拖拽卡顿问题，通过放弃Button组件改用VStack+onTapGesture
   - 拖动手势现在优先于点击手势，使用户可以在气泡上无卡顿地拖动页面

7. **界面优化**：
   - 移除了气泡中的热量信息显示，更聚焦于甜品名称
   - 实现了导航栏的滑动隐藏，在向上拖动时自动隐藏标签栏
   - 保持了界面的一致性，顶部标题和底部导航栏都会在拖动时隐藏

8. **交互体验提升**：
   - 优化了拖动时的动画过渡，使界面变化更加平滑
   - 简化了用户决策，移除非关键决策点的信息（热量数值）
   - 扩大了可视空间，使用户在浏览甜品时能够获得更大的视图区域

9. **气泡名称智能显示**：
   - 实现了气泡名称的距离感知显示，只在气泡接近中心区域时显示名称
   - 添加了平滑淡入淡出过渡，提升用户体验
   - 减少了视觉干扰，使用户能更专注于甜品图片的浏览

### 2023-04-02
1. **TabBar组件完全重构**：
   - 彻底重写TabBar实现，采用新的布局策略和安全区域处理方式
   - 正确检测和应用底部安全区域高度，确保TabBar精确置底
   - 解决了底部灰色边缘显示问题，实现了完全统一的纯白色背景
   - 优化了TabBar隐藏逻辑，增加足够的偏移量确保完全隐藏

2. **运动方式选择页面重设计**：
   - 基于Figma设计图完全重构运动类型选择界面
   - 实现了现代化UI设计，包括渐变背景、圆角面板和精美卡片
   - 添加了运动类型单选功能，并设计了选中状态的视觉反馈
   - 优化了信息展示，包括运动时间和距离估算显示

3. **代码优化与重构**：
   - 修复了多个文件中扩展方法重复声明的问题，确保代码库的一致性
   - 优化了UI工具类的共享机制，避免重复定义相同功能的代码
   - 提升了代码库的健壮性和可维护性
   - 解决了DessertRunApp.swift重复文件问题，修复编译时"Multiple commands produce"错误
   - 修复了应用入口文件中错误的导入语法，解决了"Objective-C module not found"编译错误
   - 修复了错误地尝试修改只读属性shouldHideTabBar的问题，改为正确地使用hideTabBarForDrag属性
   - 优化了复杂视图修饰符链，解决了"Failed to produce diagnostic"编译器错误
   - 进一步改进了条件渲染逻辑，将三元操作符和链式修饰符替换为直观的if-else结构

4. **字体体系统一**：
   - 建立了统一的字体管理系统，包含H1、H2、title、Body Bold、Body和Caption六种样式
   - 创建了Font+Extensions.swift文件，集中管理所有字体样式和行高设置
   - 应用新的字体系统到运动类型选择页面，确保视觉一致性
   - 添加了支持行高设置的文本样式修饰符，使文本展示更加专业

5. **视图边缘处理技巧**：
   - 使用ZStack嵌套布局，解决面板不能延伸到底部的问题
   - 通过.ignoresSafeArea(.container, edges: .bottom)确保内容可以正确延伸到安全区域外
   - 使用内容偏移(offset)和嵌套视图的组合实现复杂的重叠布局
   - 记录了视图延伸方案作为最佳实践，可以用于解决类似的布局问题

6. **技术文档增强**：
   - 创建了《SwiftUI最佳实践指南》文档，系统性归纳项目中积累的所有SwiftUI开发经验
   - 文档包含8大类别，涵盖视图布局、状态管理、手势交互、性能优化等方面
   - 记录了项目中解决的关键技术问题及其解决方案，为团队成员提供技术参考

7. **页面结构重组**：
   - 重新设计了页面层次结构，确保视觉元素正确叠放
   - 使用ZStack、zIndex和offset属性实现复杂的视觉层叠效果
   - 采用更灵活的空间分配策略，实现内容区域的动态调整
   - 页面布局与Figma设计完全同步，确保设计实现的一致性

## 视图延伸到屏幕边缘的最佳实践

### 问题描述
在SwiftUI中，当需要让视图内容延伸到屏幕底部时，经常会遇到两个主要问题：
1. 内容被安全区域限制，无法完全延伸到屏幕边缘
2. 背景颜色延伸到了边缘，但内容仍受到安全区域的约束

### 解决方案
以下是确保视图正确延伸到屏幕边缘的最佳实践：

1. **使用ZStack嵌套布局**：
```swift
ZStack(alignment: .top) {
    // 背景层 - 延伸到底部
    VStack {
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.white)
    .cornerRadius(10, corners: [.topLeft, .topRight])
    .ignoresSafeArea(.container, edges: .bottom) // 关键点：忽略底部安全区域
    
    // 内容层 - 考虑底部安全区域的内边距
    VStack {
        // 实际内容...
    }
    .padding(.bottom, 50) // 确保内容不被底部安全区域遮挡
}
```

2. **适当使用ignoresSafeArea**：
   - `.ignoresSafeArea(.container, edges: .bottom)` 允许视图扩展到底部安全区域
   - 仅将此应用于背景层，而不是包含实际内容的视图
   - 为内容层添加足够的底部内边距，避免内容被设备底部特性遮挡

3. **使用偏移和嵌套视图实现复杂布局**：
   - 使用`.offset(y: -50)`等偏移量创建视图重叠效果
   - 通过嵌套ZStack实现不同部分有不同的布局规则

4. **解决圆角问题**：
   - 只在需要的边添加圆角：`.cornerRadius(10, corners: [.topLeft, .topRight])`
   - 确保底部边缘没有圆角，可以完全延伸到屏幕底部

这种方法的关键是将视图分为"背景层"和"内容层"，背景层可以安全地忽略安全区域并延伸到边缘，而内容层保持适当的内边距以确保可见性和可访问性。

## 技术问题分析与解决方案

### 气泡拖拽卡顿问题深入分析

#### 问题技术原因
在SwiftUI中，手势识别有优先级系统。我们当前的实现中，BubbleView使用了Button组件封装了气泡内容，这导致：

1. Button自带的点击手势优先级默认高于ScrollView的拖动手势
2. 当用户手指接触气泡时，系统优先考虑这可能是对气泡的点击，因此阻止了滚动行为
3. 只有当系统确定这不是点击（例如手指移动超过一定阈值）时，才会将事件传递给ScrollView

#### 推荐解决方案

##### 方案1：使用高优先级的拖动手势
```swift
.highPriorityGesture(
    DragGesture()
        .onChanged { _ in }
)
.simultaneousGesture(
    TapGesture()
        .onEnded { _ in
            onTap()
        }
)
```

##### 方案2：使用手势识别器修饰符
```swift
Button(action: onTap) {
    // 气泡内容...
}
.buttonStyle(PlainButtonStyle())
.gesture(
    DragGesture(minimumDistance: 0)
        .onChanged { _ in }
        .exclusively(
            before: TapGesture()
                .onEnded { _ in
                    onTap()
                }
        )
)
```

##### 方案3：放弃Button，使用自定义手势
```swift
// 替换Button为普通View
VStack {
    // 气泡内容...
}
.contentShape(RoundedRectangle(cornerRadius: bubbleSize * 0.25, style: .continuous))
.onTapGesture {
    onTap()
}
.allowsHitTesting(true) 
```

#### 实施计划
1. 备份当前BubbleView.swift文件
2. 实施方案1，测试效果
3. 如效果不理想，尝试方案2或方案3
4. 进行性能测试，确保UI响应流畅
5. 更新文档，记录解决方案

#### 最终解决方案

经过测试，我们采用了**方案3**，放弃使用Button组件，改为使用普通的VStack加上简单的点击手势：

```swift
// 放弃Button，改用VStack和独立的点击手势
VStack(spacing: 4) {
    // 气泡内容...
}
.padding(contentPadding)
.frame(width: bubbleSize, height: bubbleSize)
.background(backgroundView)
.opacity(calculateOpacity())
.blur(radius: calculateBlurRadius())
.contentShape(RoundedRectangle(cornerRadius: bubbleSize * 0.25, style: .continuous))
// 使用简单的点击手势，优先级较低
.onTapGesture {
    onTap()
}
```

这种实现方式有以下优势：
1. **手势优先级合理**：默认情况下，`onTapGesture`的优先级低于ScrollView的拖动手势
2. **行为一致**：保持了点击气泡的功能，同时允许用户在气泡上开始拖动
3. **简洁可维护**：代码结构简单明了，易于维护和调整
4. **性能良好**：减少了不必要的手势处理器层级

在测试中，用户现在可以在气泡上开始拖动操作，系统不会再误将其识别为点击操作，从而实现了顺畅的拖动体验。