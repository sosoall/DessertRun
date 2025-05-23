import SwiftUI

/// 优化版挑战首页视图 - 整合了瀑布流布局
struct ChallengeGridView: View {
    // 环境对象
    @EnvironmentObject var appState: AppState
    
    // 视图模型
    @StateObject private var viewModel = ChallengeViewModel(appState: AppState.shared)
    
    // 屏幕尺寸
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // UI状态
    @State private var showUserEnrollments = false
    @State private var selectedFilter: String = "all" // "all", "free", "paid"
    
    // 调试状态
    @State private var showDebugInfo: Bool = true
    @State private var scrollOffset: CGPoint = .zero
    @State private var scrollViewSize: CGSize = .zero
    @State private var forceRefresh: UUID = UUID()
    
    // 安全边距 - 初始使用较小值
    @State private var safetyMargin: CGFloat = 20
    
    // 固定高度值
    private let fixedTopHeight: CGFloat = 65
    private let fixedFilterHeight: CGFloat = 57
    private let fixedSafeAreaTop: CGFloat = 59
    
    // 计算总顶部高度
    private var totalTopHeight: CGFloat {
        return fixedTopHeight + fixedFilterHeight + safetyMargin
    }
    
    // 处理后的去重数据
    private var uniqueActivities: [ChallengeActivity] {
        let ids = Set(viewModel.filteredActivities.map { $0.id })
        return ids.compactMap { id in
            viewModel.filteredActivities.first { $0.id == id }
        }
    }
    
    // 计算列数
    private var columnCount: Int {
        horizontalSizeClass == .regular ? 3 : 2
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // 背景色
            Color(hex: 0xF2F2F2).ignoresSafeArea()
            
            // 使用常规ScrollView
            ScrollView {
                VStack(spacing: 0) {
                    // 顶部空白 - 匹配顶部固定区域的高度
                    Color.clear
                        .frame(height: totalTopHeight)
                    
                    // 主内容区域
                    if uniqueActivities.isEmpty {
                        // 空状态
                        emptyStateView
                    } else {
                        // 使用简化版瀑布流
                        SimplifiedWaterfallGrid(
                            items: uniqueActivities,
                            columns: columnCount,
                            spacing: 12
                        ) { challenge in
                            NavigationLink(destination: 
                                ChallengeDetailView(challengeId: challenge.id)
                                    .environmentObject(appState)
                            ) {
                                ChallengeCardView(
                                    challenge: challenge,
                                    isEnrolled: viewModel.isEnrolled(in: challenge.id)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100) // 添加底部空间，确保底部内容可以滚动到视图中心
                    }
                }
                // 使用ID强制刷新
                .id(forceRefresh)
            }
            .scrollIndicators(.visible) // 显示滚动指示器以便调试
            .coordinateSpace(name: "scroll")
            .overlay(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: ScrollPositionKey.self, value: geo.frame(in: .named("scroll")).origin)
                        .onAppear {
                            scrollViewSize = geo.size
                        }
                        .onChange(of: geo.size) { _, newSize in
                            scrollViewSize = newSize
                        }
                }
            )
            .onPreferenceChange(ScrollPositionKey.self) { position in
                self.scrollOffset = position
            }
            .refreshable {
                // 刷新时先清空再加载
                viewModel.challengeActivities = []
                // 切换强制刷新标志，确保布局重置
                forceRefresh = UUID()
                // 加载新数据
                viewModel.loadChallenges()
            }
            
            // 顶部固定区域
            VStack(spacing: 0) {
                // 顶部导航区域
                topNavigationArea
                
                // 筛选器区域
                filterArea
            }
            .background(Color.white)
            .zIndex(10)
            
            // 详细调试信息
            if showDebugInfo {
                VStack(alignment: .leading) {
                    Text("顶部高度: \(Int(fixedTopHeight))")
                    Text("筛选高度: \(Int(fixedFilterHeight))")
                    Text("安全边距: \(Int(safetyMargin))")
                    Text("总顶部高度: \(Int(totalTopHeight))")
                    Text("滚动偏移: y = \(Int(scrollOffset.y))")
                    Text("滚动视图尺寸: \(Int(scrollViewSize.width)) x \(Int(scrollViewSize.height))")
                    Text("活动数量: \(uniqueActivities.count)")
                    Text("列数: \(columnCount)")
                    
                    Button("隐藏调试") {
                        showDebugInfo = false
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // 调整安全边距按钮
                    HStack {
                        Button {
                            safetyMargin += 10
                            print("增加安全边距到: \(safetyMargin)")
                            // 切换强制刷新标志
                            forceRefresh = UUID()
                        } label: {
                            Text("+10")
                                .frame(width: 50, height: 30)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        
                        Button {
                            if safetyMargin >= 10 {
                                safetyMargin -= 10
                                print("减少安全边距到: \(safetyMargin)")
                                // 切换强制刷新标志
                                forceRefresh = UUID()
                            }
                        } label: {
                            Text("-10")
                                .frame(width: 50, height: 30)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    
                    // 强制重新加载数据按钮
                    Button("重新加载") {
                        viewModel.challengeActivities = []
                        forceRefresh = UUID()
                        viewModel.loadChallenges()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .padding(.top, 8)
                }
                .padding()
                .background(Color.yellow.opacity(0.8))
                .cornerRadius(8)
                .padding(8)
                .position(x: 100, y: 200)
                .zIndex(100)
            }
            
            // 加载中指示器
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
                    .zIndex(20)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showUserEnrollments) {
            EnrolledChallengeView()
                .environmentObject(appState)
        }
        .onAppear {
            // 页面出现时加载数据
            if viewModel.challengeActivities.isEmpty {
                viewModel.loadChallenges()
            }
            if viewModel.enrolledChallenges.isEmpty {
                viewModel.loadEnrollments()
            }
        }
    }
    
    // 顶部导航区域
    private var topNavigationArea: some View {
        HStack {
            Text("挑战活动")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: {
                // 显示用户已报名的挑战
                showUserEnrollments = true
            }) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 22))
                    .foregroundColor(.black)
                    .padding(8)
                    .background(Circle().fill(Color.white))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Color.white)
        .frame(height: fixedTopHeight)
    }
    
    // 筛选器区域
    private var filterArea: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterButton(
                    title: "全部",
                    isSelected: selectedFilter == "all",
                    action: { 
                        selectedFilter = "all"
                        viewModel.selectedActivityType = "all"
                    }
                )
                
                FilterButton(
                    title: "免费挑战",
                    isSelected: selectedFilter == "free",
                    action: { 
                        selectedFilter = "free"
                        viewModel.selectedActivityType = "free"
                    }
                )
                
                FilterButton(
                    title: "付费挑战",
                    isSelected: selectedFilter == "paid",
                    action: { 
                        selectedFilter = "paid"
                        viewModel.selectedActivityType = "paid"
                    }
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white)
        .frame(height: fixedFilterHeight)
    }
    
    // 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("暂无挑战活动")
                .font(.headline)
                .foregroundColor(.gray)
            
            Button("刷新") {
                viewModel.challengeActivities = []
                forceRefresh = UUID()
                viewModel.loadChallenges()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.DessertRun.accent)
            .foregroundColor(.white)
            .cornerRadius(20)
        }
        .padding(.top, 100)
        .frame(maxWidth: .infinity)
    }
}

// 滚动位置偏好键
struct ScrollPositionKey: PreferenceKey {
    static var defaultValue: CGPoint {
        return .zero
    }
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

/// 简化版瀑布流布局 - 使用基本栅格而非PreferenceKey
struct SimplifiedWaterfallGrid<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let columns: Int
    let spacing: CGFloat
    let content: (Item) -> Content
    
    // 构造函数
    init(items: [Item], columns: Int, spacing: CGFloat, @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.columns = max(1, columns)
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        // 将数据分为多个列
        let columnItems = distributeItemsIntoColumns()
        
        // 创建列容器
        HStack(alignment: .top, spacing: spacing) {
            // 对每一列创建一个VStack
            ForEach(0..<columns, id: \.self) { columnIndex in
                // 确保我们不会越界访问数组
                if columnIndex < columnItems.count {
                    // 每列的垂直堆栈
                    LazyVStack(spacing: spacing) {
                        ForEach(columnItems[columnIndex], id: \.id) { item in
                            content(item)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top, spacing)
    }
    
    // 使用更均衡的方法分配项目到各列
    private func distributeItemsIntoColumns() -> [[Item]] {
        // 初始化所有列
        var columns = Array(repeating: [Item](), count: self.columns)
        
        // 创建列高度数组，初始值都是0
        var columnHeights = Array(repeating: CGFloat(0), count: self.columns)
        
        // 先对项目进行分类：新手挑战和非新手挑战
        let beginnerItems = items.filter { 
            // 尝试将item转换为ChallengeActivity来获取isForBeginner属性
            if let challenge = $0 as? ChallengeActivity {
                return challenge.isForBeginner
            }
            return false
        }
        
        let nonBeginnerItems = items.filter {
            // 尝试将item转换为ChallengeActivity来获取isForBeginner属性
            if let challenge = $0 as? ChallengeActivity {
                return !challenge.isForBeginner
            }
            return true // 如果无法转换，保持原样
        }
        
        // 首先处理新手挑战，让它们出现在最开始
        for item in beginnerItems {
            // 找到当前最短的列
            if let minIndex = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset {
                // 将项目添加到该列
                columns[minIndex].append(item)
                
                // 计算并更新列高度（基于内容估算实际高度而非简单加1）
                let estimatedHeight = calculateEstimatedHeight(for: item)
                columnHeights[minIndex] += estimatedHeight
            }
        }
        
        // 然后处理其他挑战
        for item in nonBeginnerItems {
            // 找到当前最短的列
            if let minIndex = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset {
                // 将项目添加到该列
                columns[minIndex].append(item)
                
                // 计算并更新列高度（基于内容估算实际高度而非简单加1）
                let estimatedHeight = calculateEstimatedHeight(for: item)
                columnHeights[minIndex] += estimatedHeight
            }
        }
        
        return columns
    }
    
    // 根据内容估算项目的高度
    private func calculateEstimatedHeight(for item: Item) -> CGFloat {
        // 基础高度（卡片的最小高度）
        var baseHeight: CGFloat = 180
        
        // 尝试将item转换为ChallengeActivity来获取详细信息
        if let challenge = item as? ChallengeActivity {
            // 为较长的文字内容添加额外高度
            let nameLength = challenge.name.count
            let descLength = challenge.description.count
            
            // 标题额外高度：每超过15个字符增加10点高度
            let nameExtraHeight = CGFloat(max(0, nameLength - 15)) * 0.8
            
            // 描述额外高度：每超过50个字符增加5点高度
            let descExtraHeight = CGFloat(max(0, descLength - 50)) * 0.5
            
            // 根据是否为付费挑战增加额外高度（付费挑战可能会显示价格信息）
            let typeExtraHeight: CGFloat = challenge.activityType == .paid ? 20 : 0
            
            // 总高度
            return baseHeight + nameExtraHeight + descExtraHeight + typeExtraHeight
        }
        
        // 默认返回基础高度
        return baseHeight
    }
}

/// 筛选按钮组件
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.DessertRun.accent : Color.gray.opacity(0.1))
                )
                .foregroundColor(isSelected ? .white : .black)
        }
    }
}

#Preview {
    NavigationView {
        ChallengeGridView()
            .environmentObject(AppState.shared)
    }
} 