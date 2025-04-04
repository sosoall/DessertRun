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
  - 支持搜索甜品
  - 点击甜品可进入运动方式选择面板。（会有顺滑的动效）

- **选择运动方式**:
  - 根据甜品热量，算法推荐适合的运动方式
  - 展示每种运动预计完成所需时间
  - 点击"开始"按钮后，立刻开始运动。
  - 支持关闭，会回到甜品气泡布局页面。

- **运动中**:
  - 双页面设计：动画激励页和数据详情页
  - 页面1：展示激励性动画、进度条和基础信息
  - 页面2：展示详细运动数据（速度、距离、时间等）
  - 支持左右滑动切换两个页面
  - 运动数据收集：
    - 室外跑步：使用GPS定位
    - 其他运动：结合HealthKit或手动计时
  - 运动开始前，会有三秒倒计时

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

## 动效设计
### 从甜品选择页到运动类型页
1. 点击目标甜品后，其他甜品都隐藏，title和导航栏隐藏（easeout）。目标甜品缓慢移动到页面顶部居中。
2. 从底部升起一个运动选择类型面板。
3. 点击关闭后，上述动效反向。
4 动画有先后顺序
   4.1 点击甜品后，出现运动选择类型面板时：
      第一步：加深色背景+title隐藏+原气泡中图片隐藏+可移动甜品图片出现
      第二步：甜品图片移动到顶部居中
      第三步：面板升起
   4.2 关闭甜品面板时
      第一步：面板落下
      第二步：甜品图片移动回去
      第三步：深色背景消失，title出现，可移动甜品图片消失，原气泡中图片出现。

### 运动选择页到运动中
1. 点击"开始"后，开始按钮的颜色从按钮的圆形扩展到整个页面，布满整个页面。
2. 倒计时三秒钟。让用户在这三秒内做好准备
3. 三秒结束后。出现运动中的动画激励页，开始运动。



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

### 2023-04-02
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

4. **代码修复**：
   - 修复了各文件中的语法错误和重复代码问题
   - 修复了AppState.swift中的重复变量声明

5. **版本控制优化**：
   - 创建了.gitignore文件，避免将图片资源文件添加到版本控制系统
   - 配置了忽略临时脚本和构建文件的规则

### 2023-04-03
1. **手势优化**：
   - 修复了气泡拖拽卡顿问题，通过放弃Button组件改用VStack+onTapGesture
   - 拖动手势现在优先于点击手势，使用户可以在气泡上无卡顿地拖动页面

2. **界面优化**：
   - 移除了气泡中的热量信息显示，更聚焦于甜品名称
   - 实现了导航栏的滑动隐藏，在向上拖动时自动隐藏标签栏
   - 保持了界面的一致性，顶部标题和底部导航栏都会在拖动时隐藏

3. **交互体验提升**：
   - 优化了拖动时的动画过渡，使界面变化更加平滑
   - 简化了用户决策，移除非关键决策点的信息（热量数值）
   - 扩大了可视空间，使用户在浏览甜品时能够获得更大的视图区域

### 2023-04-04
1. **导航体验优化**：
   - 重构了标签栏隐藏机制，采用自定义覆盖层代替系统方法
   - 拖动时标签栏平滑隐藏，停止拖动后自动恢复
   - 确保了拖动状态下最大化内容视图区域

2. **气泡名称智能显示**：
   - 实现了气泡名称的距离感知显示，只在气泡接近中心区域时显示名称
   - 添加了平滑淡入淡出过渡，提升用户体验
   - 减少了视觉干扰，使用户能更专注于甜品图片的浏览

3. **整体用户体验提升**：
   - 简化了界面信息层级，提高了关键信息的可见性
   - 优化了手势系统，解决了触摸冲突问题
   - 增强了应用的直观性和易用性

### 2023-04-05
1. **自定义TabBar实现**：
   - 完全重构了TabBar实现，摒弃系统TabBar，采用自定义版本
   - 实现真正的底部导航栏向下滑动隐藏效果，彻底解决了之前的遮挡问题
   - 增加了TabBar状态管理的灵活性，支持两种隐藏模式：拖动时暂时隐藏和运动状态完全隐藏

2. **应用状态管理优化**：
   - 在AppState中增加了TabBar控制相关状态
   - 实现了不同页面间的状态联动，确保用户体验的一致性
   - 优化了运动模式下的界面流程，进入运动状态自动隐藏TabBar，退出时恢复显示

3. **性能优化**：
   - 通过自定义实现减少了布局重绘次数
   - 优化了转场动画的流畅度
   - 提高了界面响应速度和交互体验

### 2023-04-06
1. **TabBar动画优化**：
   - 重构TabBar滑动动画，使图标与底栏一起平滑滑动
   - 修复了以前图标原地消失的突兀效果
   - 改进了整体动画的连贯性和自然感

2. **应用导航流程完善**：
   - 修复在返回导航时TabBar状态不正确的问题
   - 优化了不同页面之间的过渡动画
   - 确保在任何导航场景下TabBar都能正确显示或隐藏

3. **状态管理健壮性提升**：
   - 增加了页面生命周期事件的状态重置逻辑
   - 防止了多页面导航时可能出现的状态不一致问题
   - 提高了应用在各种使用场景下的稳定性

### 2023-04-07
1. **项目结构优化**：
   - 修复了文件结构冲突问题，删除了重复的`ExerciseTypeSelectionView.swift`文件
   - 解决了编译时出现的"Multiple commands produce"错误
   - 确保了视图文件的正确组织和目录结构

2. **打包和部署流程优化**：
   - 修复了编译期错误，使项目能够成功部署到真机设备
   - 清理了项目中的冗余文件和重复定义
   - 提高了项目的稳定性和可维护性

### 2023-04-08
1. **UI细节优化**：
   - 修复了底部导航栏显示两种颜色的问题，确保整个TabBar保持纯白色背景
   - 优化了TabBar延伸到底部安全区域的显示效果
   - 进一步提升了界面的一致性和专业性

2. **项目稳定性提升**：
   - 解决了部署到真机后发现的UI细节问题
   - 优化了各种机型上的显示效果
   - 为应用商店发布做最后的视觉调整

### 2023-04-09
1. **UI细节完善**：
   - 彻底解决了TabBar底部灰色问题，通过添加额外的白色底层确保整个安全区域都保持纯白色
   - 增大了气泡中甜品图片的尺寸，减少了内边距，使图片展示更加突出
   - 进一步提升了应用的视觉一致性和美观度

2. **最终发布准备**：
   - 完成所有UI细节调整和优化
   - 进行最后的兼容性测试，确保在各种设备上显示正常
   - 准备App Store提交材料和截图

### 2023-04-10
1. **TabBar组件完全重构**：
   - 彻底重写TabBar实现，采用新的布局策略和安全区域处理方式
   - 正确检测和应用底部安全区域高度，确保TabBar精确置底
   - 解决了底部灰色边缘显示问题，实现了完全统一的纯白色背景
   - 添加了底部安全距离，避免与iOS系统Home指示条重叠
   - 优化了TabBar隐藏逻辑，增加足够的偏移量确保完全隐藏

2. **高级UI布局优化**：
   - 优化了内容区域和TabBar之间的布局关系
   - 改进了在不同设备上的显示效果，包括有刘海和无刘海设备
   - 确保视觉效果的一致性和专业性，为应用商店发布做最后准备

3. **最终用户体验完善**：
   - 图片尺寸和边距调整，提高主要内容可见性
   - UI元素间距和对齐优化，增强整体设计的协调性
   - 交互流畅度测试和优化，确保应用响应迅速且直观


## 上线前多机型测试拾遗
1. 运动选择类型页的移动动画，起始和结束的图片大小和位置。我做了绝对数值上的调整，但是不确定是否有普适性，在后面的机型测试中要格外关注

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

## 备份代码

### 删除的ExerciseTypeSelectionPanel代码
```swift
/// 运动类型选择面板
struct ExerciseTypeSelectionPanel: View {
    /// 选中的甜品
    let dessert: DessertItem?
    
    /// 取消回调
    var onDismiss: () -> Void
    
    /// 是否导航到运动界面
    @State private var navigateToWorkout = false
    
    /// 环境中的应用状态
    @EnvironmentObject var appState: AppState
    
    /// 运动类型列表
    private let exerciseTypes = ExerciseTypeData.getSampleExerciseTypes()
    
    /// 卡路里值
    private var calories: Double {
        guard let selectedDessert = dessert else { return 0 }
        if let calValue = Double(selectedDessert.calories.replacingOccurrences(of: "kcal", with: "")) {
            return calValue
        }
        return 0
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 顶部拖动条
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 60, height: 5)
                .padding(.top, 12)
            
            // 标题
            Text("请选择运动方式")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "61462C"))
                .padding(.top, 5)
            
            // 甜品信息卡片
            if let dessert = dessert {
                HStack {
                    Text("目标甜品 • \(dessert.name)")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(dessert.calories)")
                        .font(.headline)
                        .foregroundColor(Color(hex: "FE2D55"))
                }
                .padding(.horizontal, 20)
            }
            
            // 运动类型列表
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(exerciseTypes) { exerciseType in
                        ExerciseTypeCard(
                            exerciseType: exerciseType,
                            calories: calories,
                            onSelect: {
                                // 选择运动类型并导航到运动界面
                                appState.selectedExerciseType = exerciseType
                                navigateToWorkout = true
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .padding(.horizontal)
        .frame(height: UIScreen.main.bounds.height * 0.75)
        .background(Color(hex: "faf0dd"))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    if gesture.translation.height > 100 {
                        onDismiss()
                    }
                }
        )
        .navigationDestination(isPresented: $navigateToWorkout) {
            WorkoutView()
                .onAppear {
                    appState.isInWorkoutMode = true
                }
        }
    }
}

/// 运动类型卡片
struct ExerciseTypeCard: View {
    /// 运动类型
    let exerciseType: ExerciseType
    
    /// 需要消耗的卡路里
    let calories: Double
    
    /// 选择回调
    var onSelect: () -> Void
    
    /// 预计时间（分钟）
    private var estimatedTime: Double {
        exerciseType.estimatedTimeToComplete(calories: calories)
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                // 左侧图标
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(exerciseType.backgroundColor)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: exerciseType.iconName)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                }
                
                // 中间内容
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseType.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(exerciseType.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(Color(hex: "FE2D55"))
                        
                        Text(formatTime(estimatedTime))
                            .font(.caption)
                            .foregroundColor(Color(hex: "FE2D55"))
                            .fontWeight(.semibold)
                    }
                }
                .padding(.leading, 8)
                
                Spacer()
                
                // 右侧箭头
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5)
        }
    }
    
    /// 格式化时间
    private func formatTime(_ minutes: Double) -> String {
        if minutes < 1 {
            return "不到1分钟"
        } else if minutes < 60 {
            return "约\(Int(minutes.rounded()))分钟"
        } else {
            let hours = Int(minutes / 60)
            let mins = Int(minutes.truncatingRemainder(dividingBy: 60))
            
            if mins == 0 {
                return "约\(hours)小时"
            } else {
                return "约\(hours)小时\(mins)分钟"
            }
        }
    }
}


