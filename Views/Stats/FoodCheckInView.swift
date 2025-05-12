import SwiftUI

/// 甜品打卡标签页
struct FoodCheckInView: View {
    @ObservedObject var viewModel: FoodCheckInViewModel
    @State private var newRecordId: String? = nil
    @State private var showNewRecordAnimation: Bool = false
    @EnvironmentObject var appState: AppState
    @State private var selectedFilter: RecordFilter = .all
    @State private var selectedRecord: WorkoutRecord? = nil  // 当前选中的记录
    @State private var showExpandedCard: Bool = false  // 是否显示展开视图
    @State private var hasAppeared: Bool = false  // 添加状态标志，追踪视图是否已出现
    
    var body: some View {
        ZStack {
            // 主内容
            ScrollView {
                VStack(spacing: 24) {
                    // 美食记录卡片
                    foodRecordCard
                    
                    // 所有美食打卡记录（直接显示，不需要点击按钮）
                    foodRecordsList
                }
                .padding(.horizontal, 20)  // 全局水平边距
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemGray6))
            .blur(radius: showExpandedCard ? 3 : 0)  // 背景模糊效果
            .allowsHitTesting(!showExpandedCard)  // 禁用弹出时的点击
            
            // 展开的卡片详情视图
            if showExpandedCard, let record = selectedRecord {
                ExpandedCardView(record: record, isShowing: $showExpandedCard)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // 使用hasAppeared标志防止多次调用
            if !hasAppeared {
                DRDebug("[FoodCheckInView] 首次显示，准备加载数据")
                
                // 使用DispatchQueue.main.asyncAfter增加延迟，避免在视图层次结构更新期间的频繁调用
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // 首次进入页面时加载数据
                    DRDebug("[FoodCheckInView] 开始加载数据")
                    // 使用新的loadData方法加载所有所需数据
                    viewModel.loadData()
                    hasAppeared = true
                    
                    // 仅当刚完成打卡时才显示动画（通过检查应用状态中的标记来判断）
                    if appState.justCompletedWorkout, let latestRecord = viewModel.getSortedAllRecords().first {
                        DRDebug("[FoodCheckInView] 检测到新记录，准备显示动画")
                        // 将新记录ID存入状态变量
                        newRecordId = "\(latestRecord.id)"
                        
                        // 延迟一点，确保视图已经加载
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                showNewRecordAnimation = true
                            }
                            
                            // 3秒后重置状态，但不需要消失动画
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                // 没有动画效果，只重置状态
                                showNewRecordAnimation = false
                                newRecordId = nil
                                appState.justCompletedWorkout = false
                                DRDebug("[FoodCheckInView] 重置动画状态完成")
                            }
                        }
                    }
                }
            } else {
                DRDebug("[FoodCheckInView] 视图已显示过，跳过数据加载")
            }
            
            // 添加美食券点击通知的观察者
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ShowExpandedCard"),
                object: nil,
                queue: .main
            ) { notification in
                if let record = notification.object as? WorkoutRecord {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedRecord = record
                        showExpandedCard = true
                    }
                }
            }
        }
        .onDisappear {
            // 移除观察者
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("ShowExpandedCard"),
                object: nil
            )
            
            DRDebug("[FoodCheckInView] 视图消失，移除观察者")
        }
    }
    
    // 美食记录卡片
    private var foodRecordCard: some View {
        VStack(spacing: 24) {
            // 标题
            VStack(spacing: 8) {
                HStack {
                    Text("美食记录")
                        .font(.system(size: 22, weight: .semibold))
                    
                    Spacer()
                }
            }
            
            // 美食排行榜和记录卡片
            VStack(spacing: 20) {
                foodRankingCard
                
                // 数据统计卡片行
                HStack(spacing: 16) {
                    foodCheckInCountCard
                    foodVarietyCard
                }
            }
        }
    }
    
    // 美食排行榜卡片
    private var foodRankingCard: some View {
        VStack(spacing: 16) {
            // 美食排行榜水平布局
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    if let topDesserts = viewModel.getAllTopDesserts(count: 4) {
                            
                        ForEach(Array(topDesserts.enumerated()), id: \.element.id) { index, dessert in
                            VStack(spacing: 8) {
                                ZStack(alignment: .top) {
                                    VStack {
                                        Spacer()
                                        // 使用CachedImage加载图片
                                        CachedImage(url: dessert.imageName, dessertId: dessert.dessertId)
                                            .scaledToFit()
                                            .frame(height: index == 0 ? 120 : 75)
                                            .cornerRadius(8)
                                    }
                                    .frame(height: 120)
                                    
                                    if index == 0 {
                                        Image("crown")
                                            .resizable()
                                            .renderingMode(.original)
                                            .scaledToFit()
                                            .frame(width: 40, height: 40)
                                            .offset(x: 10, y: -15)
                                    }
                                }
                                
                                Text("打卡\(dessert.count)次")
                                    .font(.system(size: 12))
                                    .foregroundColor(.black)
                            }
                        }
                    } else {
                        Text("暂无记录")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    // 美食打卡次数卡片
    private var foodCheckInCountCard: some View {
        HStack(spacing: 12) {
            Image("Number_of_check_in")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 24, height: 24)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(viewModel.totalFoodCheckInCount)")
                    .font(.system(size: 20, weight: .semibold))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text("次美食打卡")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 2, y: 2)
    }
    
    // 美食种类卡片
    private var foodVarietyCard: some View {
        HStack(spacing: 12) {
            Image("Number_of_sort")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 24, height: 24)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(viewModel.allUniqueDessertTypes)")
                    .font(.system(size: 20, weight: .semibold))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text("种美食")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 2, y: 2)
    }
    
    // 所有美食打卡记录列表
    private var foodRecordsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题和筛选区域
            VStack(spacing: 12) {
                HStack {
                    Text("全部打卡记录")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Spacer()
                }
                
                // 筛选选项
                filterOptions
            }
            .padding(.top, 8)
            
            // 所有打卡记录
            allFoodRecords
        }
    }
    
    // 筛选选项
    private var filterOptions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(RecordFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation {
                            selectedFilter = filter
                            
                            // 根据选择的筛选条件加载相应的美食券
                            switch filter {
                            case .all:
                                // 加载全部美食券
                                viewModel.loadDessertVouchers()
                            case .active:
                                // 加载有效的美食券
                                viewModel.loadDessertVouchers(status: "active")
                            case .used:
                                // 加载已使用的美食券
                                viewModel.loadDessertVouchers(status: "used")
                            case .expired:
                                // 加载已过期的美食券
                                viewModel.loadDessertVouchers(status: "expired")
                            }
                        }
                    }) {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedFilter == filter ? .semibold : .regular)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(selectedFilter == filter ? Color.accentColor : Color(UIColor.secondarySystemBackground))
                            .foregroundColor(selectedFilter == filter ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
        }
    }
    
    // 筛选记录
    private var filteredRecords: [String: [WorkoutRecord]] {
        let sortedRecords = viewModel.getSortedAllRecords()
        var groupedRecords = [String: [WorkoutRecord]]()
        
        // 根据筛选条件获取记录
        let filteredList: [WorkoutRecord]
        switch selectedFilter {
        case .all:
            // 使用全部记录，不需要筛选
            filteredList = sortedRecords
        case .active:
            // 使用API返回的"active"状态美食券对应的记录
            filteredList = sortedRecords.filter { record in
                // 查找对应的美食券
                let voucher = appState.dessertVouchers.first(where: { $0.workoutRecordId == record.id })
                // 只保留状态为active的记录
                return voucher?.status == "active"
            }
        case .used:
            // 使用API返回的"used"状态美食券对应的记录
            filteredList = sortedRecords.filter { record in
                // 查找对应的美食券
                let voucher = appState.dessertVouchers.first(where: { $0.workoutRecordId == record.id })
                // 只保留状态为used的记录
                return voucher?.status == "used"
            }
        case .expired:
            // 使用API返回的"expired"状态美食券对应的记录
            filteredList = sortedRecords.filter { record in
                // 查找对应的美食券
                let voucher = appState.dessertVouchers.first(where: { $0.workoutRecordId == record.id })
                // 只保留状态为expired的记录
                return voucher?.status == "expired"
            }
        }
        
        // 按日期分组记录
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年 M月 d日"
        
        for record in filteredList {
            let dateString = dateFormatter.string(from: record.date)
            if groupedRecords[dateString] == nil {
                groupedRecords[dateString] = [record]
            } else {
                groupedRecords[dateString]?.append(record)
            }
        }
        
        return groupedRecords
    }
    
    // 所有美食打卡记录
    private var allFoodRecords: some View {
        VStack(spacing: 24) {
            if appState.workoutRecords.isEmpty {
                emptyRecordsView
            } else {
                // 获取筛选后的分组记录
                let groupedRecords = filteredRecords
                
                if groupedRecords.isEmpty {
                    // 无筛选结果
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                            .padding()
                        
                        Text("未找到符合条件的记录")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    // 确保日期按照倒序排列
                    ForEach(groupedRecords.keys.sorted(by: >), id: \.self) { dateString in
                        VStack(alignment: .leading, spacing: 16) {
                            // 日期标题，增加上边距防止被卡片遮挡
                            Text(dateString)
                                .font(.system(size: 18, weight: .medium))
                                .padding(.leading, 4)
                                .padding(.top, 16)
                                .padding(.bottom, 8)
                            
                            // 当天的记录
                            ForEach(groupedRecords[dateString]!, id: \.id) { record in
                                // 检查是否是新记录
                                let isNewRecord = newRecordId == "\(record.id)" && dateString == filteredRecords.keys.sorted(by: >).first
                                
                                VStack {
                                    if isNewRecord && showNewRecordAnimation {
                                        // 为新记录显示动画效果，只有从顶部出现的动画
                                        DessertVoucherCardSimple(record: record)
                                            .padding(.horizontal, 12)  // 额外卡片内边距
                                            .transition(.move(edge: .top).combined(with: .opacity))
                                    } else {
                                        DessertVoucherCardSimple(record: record)
                                            .padding(.horizontal, 12)  // 额外卡片内边距
                                    }
                                }
                                .padding(.bottom, 12)  // 增加卡片底部边距
                            }
                        }
                    }
                    
                    // 加载更多按钮
                    if viewModel.hasMoreRecords {
                        Button(action: {
                            viewModel.loadMoreRecords()
                        }) {
                            HStack {
                                if viewModel.isLoadingMore {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .frame(width: 20, height: 20)
                                        .padding(.trailing, 8)
                                }
                                
                                Text(viewModel.isLoadingMore ? "加载中..." : "加载更多")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                        .disabled(viewModel.isLoadingMore)
                    } else if !appState.workoutRecords.isEmpty {
                        Text("没有更多记录了")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
    
    // 空记录视图
    private var emptyRecordsView: some View {
        VStack {
            Image(systemName: "tray.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
                .padding()
            
            Text("暂无美食打卡记录")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - 展开的卡片详情视图
struct ExpandedCardView: View {
    let record: WorkoutRecord
    @Binding var isShowing: Bool
    @State private var isShared: Bool = false
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isShowing = false
                    }
                }
            
            // 卡片内容
            VStack(spacing: 0) {
                // 美食券卡片（展开状态）
                DessertVoucherCardSimple(record: record, forceExpanded: true)
                    .frame(width: UIScreen.main.bounds.width - 60)  // 减小宽度以匹配设计
                
                // 底部操作按钮
                HStack(spacing: 40) {
                    // 分享按钮
                    Button(action: {
                        // 分享逻辑
                        isShared = true
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "#FF5A73").opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(hex: "#FF5A73"))
                            }
                            
                            Text("分享")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#FF5A73"))
                        }
                    }
                    
                    // 关闭按钮
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isShowing = false
                        }
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 22))
                                    .foregroundColor(.gray)
                            }
                            
                            Text("关闭")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 24)
            }
            .background(Color.white.opacity(0.95))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 0)
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $isShared) {
            // 分享视图
            VStack {
                Text("分享美食券")
                    .font(.title)
                    .padding()
                
                Text("分享\(record.dessert.name)的美食打卡记录")
                    .padding()
                
                Button("关闭") {
                    isShared = false
                }
                .padding()
            }
        }
    }
}

// MARK: - 筛选选项枚举
enum RecordFilter: String, CaseIterable {
    case all = "全部"
    case active = "可使用"
    case used = "已使用"
    case expired = "已过期"
}

// MARK: - 缓存图片视图
struct CachedImage: View {
    let url: String
    let dessertId: String
    @State private var image: UIImage? = nil
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else {
                // 加载中状态
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
                    .onAppear {
                        loadImage()
                    }
            }
        }
    }
    
    private func loadImage() {
        // 检查URL是否是完整的URL地址（带有http(s)://前缀）
        let completeUrl: String
        if url.hasPrefix("http") {
            completeUrl = url
        } else if url.hasPrefix("/api") {
            // API路径，需要拼接基础URL
            completeUrl = "\(Config.API.baseURL)\(url)"
        } else {
            // 尝试使用dessertId构建获取图片的URL
            completeUrl = "\(Config.API.baseURL)/api/v1/desserts/\(dessertId)/images/regular"
        }
        
        // 使用图片缓存服务加载图片
        ImageCacheService.shared.downloadAndCacheImage(url: completeUrl) { uiImage in
            if let uiImage = uiImage {
                self.image = uiImage
            } else {
                // 如果第一次下载失败，尝试其他可能的URL格式
                let fallbackUrl = "\(Config.API.baseURL)/api/v1/desserts/\(dessertId)/image"
                ImageCacheService.shared.downloadAndCacheImage(url: fallbackUrl) { backupImage in
                    self.image = backupImage ?? UIImage(named: "dessert_placeholder")
                }
            }
        }
    }
} 