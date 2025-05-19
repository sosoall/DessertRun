import SwiftUI

/// 甜品打卡标签页
struct FoodCheckInView: View {
    @StateObject var viewModel = FoodCheckInViewModel.shared
    @State private var newRecordId: String? = nil
    @State private var showNewRecordAnimation: Bool = false
    @EnvironmentObject var appState: AppState
    @State private var selectedFilter: RecordFilter = .all
    @State private var selectedRecord: WorkoutRecord? = nil  // 当前选中的记录
    @State private var showExpandedCard: Bool = false  // 是否显示展开视图
    @State private var hasAppeared: Bool = false  // 添加状态标志，追踪视图是否已出现
    @State private var forceRefresh: Bool = false  // 强制刷新标记
    @State private var hasLoadedVouchers: Bool = false  // 添加标记，追踪美食券是否已加载
    @State private var preloadedCardInfo: [String: Any]? = nil
    
    // 添加静态变量，用于全局追踪是否已经完成初始加载
    private static var hasInitialDataLoaded: Bool = false
    
    // 添加变量，记录视图是否通过打卡完成页导航过来
    @State private var navigatedFromWorkoutComplete: Bool = false
    
    var body: some View {
        ZStack {
            // 主内容
            ScrollView {
                VStack(spacing: 20) {
                    // 美食记录卡片
                    foodRecordCard
                    
                    // 所有美食打卡记录（直接显示，不需要点击按钮）
                    foodRecordsList
                        .id("foodRecordsList-\(forceRefresh)-\(appState.dessertVouchers.count)")  // 添加ID确保视图刷新
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
                ExpandedCardView(record: record, isShowing: $showExpandedCard, preloadedImageInfo: preloadedCardInfo)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // 监听新的排行榜图片加载完成通知
            NotificationCenter.default.addObserver(forName: NSNotification.Name("RankingImagesLoaded"), object: nil, queue: .main) { _ in
                // 仅刷新排行榜部分，不影响美食券列表
                DispatchQueue.main.async {
                    // 使用轻量级方式刷新，仅标记排行榜部分需要更新
                    self.forceRefresh.toggle()
                }
            }
            
            // 检查是否是从打卡完成页面导航过来，如果是，则标记并等待真正显示时才加载数据
            if appState.justCompletedWorkout {
                navigatedFromWorkoutComplete = true
                DRInfo("[FoodCheckInView] 检测到从打卡完成页导航过来，将延迟加载数据")
            }
            
            // 修改加载逻辑：如果是从打卡完成页导航过来，则检查navigatedFromWorkoutComplete标志
            // 如果不是，则按原来逻辑加载
            if !navigatedFromWorkoutComplete {
                // 分别加载不同数据，避免相互影响
                // 1. 如果美食记录为空，加载美食记录
                if appState.workoutRecords.isEmpty {
                    viewModel.loadWorkoutRecordsIndependently()
                }
                
                // 2. 单独加载排行榜数据
                if viewModel.topDesserts.isEmpty && !viewModel.isLoadingTopDesserts {
                    viewModel.loadTopDessertsIndependently(limit: 5)
                }
                
                // 3. 如果美食券为空，加载美食券数据
                if appState.dessertVouchers.isEmpty {
                    viewModel.loadVouchersIndependently()
                }
                
                // 首次加载检查全局标记，而不是仅基于hasAppeared
                if !Self.hasInitialDataLoaded {
                    // 立即设置标志，防止重复加载
                    hasAppeared = true
                    Self.hasInitialDataLoaded = true
                    
                    // 延迟加载，确保视图已完全呈现
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        // 使用分离的加载函数代替单一的loadData()
                        if appState.workoutRecords.isEmpty {
                            viewModel.loadWorkoutRecordsIndependently()
                        }
                        
                        if appState.dessertVouchers.isEmpty {
                            viewModel.loadVouchersIndependently()
                        }
                        
                        if viewModel.topDesserts.isEmpty {
                            viewModel.loadTopDessertsIndependently(limit: 5)
                        }
                        
                        // 设置美食券已加载标记
                        self.hasLoadedVouchers = true
                    }
                }
            } else {
                // 如果是从打卡完成页导航过来，在视图完全出现后才加载数据
                DRInfo("[FoodCheckInView] 从打卡完成页导航过来，将延迟加载数据")
                
                // 延迟加载数据，确保中间页已完全关闭
                // 增加延迟时间，从0.5秒改为0.8秒，确保中间页完全关闭且转场动画结束
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    DRInfo("[FoodCheckInView] 中间页完全关闭后，开始加载数据")
                    
                    // 加载最新的美食券数据
                    viewModel.loadVouchersIndependently()
                    
                    // 加载最新的运动记录数据
                    viewModel.loadWorkoutRecordsIndependently()
                    
                    // 加载排行榜数据
                    viewModel.loadTopDessertsIndependently(limit: 5)
                    
                    // 重置标志
                    navigatedFromWorkoutComplete = false
                    
                    // 设置美食券已加载标记
                    self.hasLoadedVouchers = true
                    
                    // 处理新记录动画
                    if appState.justCompletedWorkout {
                        // 增加延迟时间，从0.3秒改为0.5秒，确保数据完全加载后再显示动画
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if let latestRecord = viewModel.getSortedAllRecords().first {
                                // 将新记录ID存入状态变量
                                newRecordId = "\(latestRecord.id)"
                                
                                DRInfo("[FoodCheckInView] 显示新记录动画，记录ID: \(latestRecord.id)")
                                
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showNewRecordAnimation = true
                                }
                                
                                // 3秒后重置状态，但不需要消失动画
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    // 没有动画效果，只重置状态
                                    showNewRecordAnimation = false
                                    newRecordId = nil
                                    appState.justCompletedWorkout = false
                                }
                                
                                // 强制刷新列表，确保新记录显示
                                self.forceRefresh.toggle()
                            }
                        }
                    }
                }
            }
            
            // 添加美食券点击通知的观察者
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ShowExpandedCard"),
                object: nil,
                queue: .main
            ) { notification in
                if let record = notification.object as? WorkoutRecord {
                    // 处理卡片传递的额外信息
                    let userInfo = notification.userInfo
                    let hasPreloadedImages = userInfo?["preloadedImages"] as? Bool ?? false
                    
                    if hasPreloadedImages {
                        DRDebug("[FoodCheckInView] 使用卡片已预加载的图片信息，避免重复加载")
                    }
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedRecord = record
                        showExpandedCard = true
                    }
                    
                    // 在ShowExpandedCard通知处理中保存预加载信息
                    // 将[AnyHashable:Any]?转换为[String:Any]?
                    if let anyHashableUserInfo = userInfo {
                        // 创建一个新的[String:Any]字典
                        var stringUserInfo = [String: Any]()
                        
                        // 遍历原始字典，将所有键转换为String
                        for (key, value) in anyHashableUserInfo {
                            if let stringKey = key as? String {
                                stringUserInfo[stringKey] = value
                            }
                        }
                        
                        // 赋值转换后的字典
                        preloadedCardInfo = stringUserInfo
                    } else {
                        preloadedCardInfo = nil
                    }
                }
            }
            
            // 添加美食券数据更新通知的观察者
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("VouchersUpdated"),
                object: nil,
                queue: .main
            ) { _ in
                // 强制刷新视图
                DispatchQueue.main.async {
                    self.forceRefresh.toggle()
                    DRInfo("[FoodCheckInView] 收到VouchersUpdated通知，当前美食券数量: \(self.appState.dessertVouchers.count)")
                }
            }
            
            // 专门添加"加载更多"数据完成的通知观察者
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("NewRecordCreated"),
                object: nil,
                queue: .main
            ) { _ in
                // 强制整个视图刷新
                DispatchQueue.main.async {
                    DRInfo("[FoodCheckInView] 收到全局刷新通知，强制刷新所有记录视图")
                    self.forceRefresh.toggle()
                }
            }
            
            // 添加运动记录更新通知的观察者 
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("WorkoutRecordsUpdated"),
                object: nil,
                queue: .main
            ) { _ in
                // 强制刷新视图
                DispatchQueue.main.async {
                    DRInfo("[FoodCheckInView] 收到运动记录更新通知，当前运动记录数量: \(self.appState.workoutRecords.count)")
                    self.forceRefresh.toggle()
                }
            }
            
            // 修改TopDessertsUpdated通知观察者，仅刷新排行榜部分
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("TopDessertsUpdated"),
                object: nil,
                queue: .main
            ) { notification in
                // 检查通知中的ViewModel实例
                if let notificationViewModel = notification.userInfo?["viewModel"] as? FoodCheckInViewModel {
                    let notificationViewModelAddress = Unmanaged.passUnretained(notificationViewModel).toOpaque()
                    let selfViewModelAddress = Unmanaged.passUnretained(self.viewModel).toOpaque()
                    
                    // 两个实例不同时，需要强制更新数据
                    if notificationViewModelAddress != selfViewModelAddress {
                        if let items = notification.userInfo?["items"] as? [StatTopDessertItem], !items.isEmpty {
                            DispatchQueue.main.async {
                                // 直接从通知获取数据并更新
                                self.viewModel.topDesserts = items
                                // 不触发全局刷新，仅刷新排行榜部分
                            }
                        }
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
            
            // 移除美食券数据更新的观察者
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("VouchersUpdated"),
                object: nil
            )
            
            // 移除排行榜数据更新的观察者
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("TopDessertsUpdated"),
                object: nil
            )
            
            // 移除运动记录更新的观察者
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("WorkoutRecordsUpdated"),
                object: nil
            )
            
            // 移除新记录创建的观察者
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("NewRecordCreated"),
                object: nil
            )
        }
    }
    
    // 美食记录卡片
    private var foodRecordCard: some View {
        VStack(spacing: 14) {
            // 标题
            HStack {
                Text("美食券")
                    .font(.system(size: 20, weight: .semibold)) // H2字体样式
                
                Spacer()
            }
            
            // 美食排行榜卡片
            VStack(spacing: 16) {
                // 标题栏
                HStack {
                    Text("美食排行榜")
                        .font(.system(size: 16, weight: .medium)) // Title字体样式
                    
                    Spacer()
                    
                    // 刷新按钮
                    Button(action: {
                        // 刷新排行榜数据 - 仅刷新排行榜，不影响美食券列表
                        viewModel.loadTopDesserts(limit: 5)
                        DRDebug("[FoodCheckInView] 用户手动刷新排行榜")
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                            .foregroundColor(viewModel.isLoadingTopDesserts ? .gray : .blue)
                    }
                    .disabled(viewModel.isLoadingTopDesserts)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                
                // 美食排行榜水平布局
                if viewModel.isLoadingTopDesserts {
                    // 加载中状态
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.2)
                            .padding()
                        Spacer()
                    }
                    .frame(height: 90) // 更紧凑
                } else if viewModel.topDesserts.isEmpty {
                    // 空状态
                    HStack {
                        Spacer()
                        VStack {
                            Text("暂无记录")
                                .font(.system(size: 14)) // Caption字体样式
                                .foregroundColor(.gray)
                                .padding()
                        }
                        Spacer()
                    }
                    .frame(height: 90) // 更紧凑
                    .onAppear {
                        DRDebug("[FoodCheckInView] 排行榜显示空状态，数据量: \(viewModel.topDesserts.count)")
                        
                        // 如果是空的，尝试再加载一次
                        if !viewModel.isLoadingTopDesserts {
                            viewModel.loadTopDesserts(limit: 5)
                            DRDebug("[FoodCheckInView] 排行榜为空，自动尝试再次加载")
                        }
                    }
                } else {
                    // 有数据状态
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) { // 减少间距
                            ForEach(viewModel.topDesserts, id: \.id) { dessert in
                                VStack(spacing: 4) { // 更紧凑
                                    ZStack(alignment: .top) {
                                        VStack {
                                            Spacer()
                                            
                                            // 使用CachedImage加载图片，尺寸更小
                                            CachedImage(url: dessert.imageName, dessertId: dessert.dessertId)
                                                .scaledToFit()
                                                .frame(height: dessert.id == viewModel.topDesserts.first?.id ? 90 : 60) // 更小的图片
                                                .cornerRadius(8)
                                        }
                                        .frame(height: 90) // 更紧凑
                                        
                                        if dessert.id == viewModel.topDesserts.first?.id {
                                            Image("crown")
                                                .resizable()
                                                .renderingMode(.original)
                                                .scaledToFit()
                                                .frame(width: 28, height: 28) // 更小的皇冠
                                                .offset(x: 8, y: -10)
                                        }
                                    }
                                    
                                    Text("打卡\(dessert.count)次")
                                        .font(.system(size: 12)) // Caption字体样式
                                        .foregroundColor(.black)
                                }
                                // 添加唯一ID，避免整个列表刷新
                                .id("top-dessert-\(dessert.id)")
                            }
                        }
                        .padding(.vertical, 10) // 更紧凑
                        .padding(.horizontal, 14)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            // 使用特定的ID使排行榜独立刷新，而不是整个视图
            .id("topDesserts-\(viewModel.topDesserts.count)-\(viewModel.isLoadingTopDesserts ? "loading" : "loaded")")
        }
    }
    
    // 所有美食打卡记录
    private var foodRecordsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题和筛选区域
            VStack(spacing: 12) {
                
                // 筛选选项
                filterOptions
            }
            .padding(.top, 8)
            
            // 所有打卡记录 - 添加ID使其能在数据变化时刷新
            allFoodRecords
                .id("allFoodRecords-\(appState.dessertVouchers.count)-\(selectedFilter)-\(forceRefresh)")
        }
    }
    
    // 筛选选项
    private var filterOptions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(RecordFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation {
                            // 只有在筛选条件变化时才重新加载数据
                            if selectedFilter != filter {
                                selectedFilter = filter
                                
                                // 使用本地筛选代替重新请求API
                                // 只有在真正需要通过API获取不同状态记录时才调用
                                if !hasLoadedVouchers || appState.dessertVouchers.isEmpty {
                                    // 仅在尚未加载或数据为空时调用API
                                    switch filter {
                                    case .all:
                                        viewModel.loadDessertVouchers()
                                    case .active:
                                        viewModel.loadDessertVouchers(status: "active")
                                    case .used:
                                        viewModel.loadDessertVouchers(status: "used")
                                    case .expired:
                                        viewModel.loadDessertVouchers(status: "expired")
                                    }
                                    hasLoadedVouchers = true
                                }
                            }
                        }
                    }) {
                        Text(filter.rawValue)
                            .font(.system(size: 14)) // Body字体样式
                            .fontWeight(selectedFilter == filter ? .semibold : .regular)
                            .padding(.vertical, 6) // 更紧凑
                            .padding(.horizontal, 14) // 更紧凑
                            .background(selectedFilter == filter ? Color.accentColor : Color(UIColor.secondarySystemBackground))
                            .foregroundColor(selectedFilter == filter ? .white : .primary)
                            .cornerRadius(16)
                    }
                }
            }
        }
    }
    
    // 筛选记录
    private var filteredRecords: [String: [WorkoutRecord]] {
        let sortedRecords = viewModel.getSortedAllRecords()
        var groupedRecords = [String: [WorkoutRecord]]()
        
        // 仅在数量为0时打印警告信息，避免重复请求
        let vouchersCount = appState.dessertVouchers.count
        if vouchersCount == 0 && !appState.justCompletedWorkout {
            DRWarning("[FoodCheckInView] 警告: 没有美食券数据!")
            // 尝试重新加载美食券数据
            DispatchQueue.main.async {
                if !self.viewModel.isLoadingVouchers {
                    self.viewModel.loadVouchersIndependently()
                }
            }
        } else {
            DRDebug("[FoodCheckInView] 处理记录过滤，当前美食券数量: \(vouchersCount)")
        }
        
        // 根据筛选条件获取记录
        let filteredList: [WorkoutRecord]
        switch selectedFilter {
        case .all:
            // 使用全部记录，不需要筛选
            filteredList = sortedRecords
        case .active, .used, .expired:
            // 使用API返回的对应状态美食券的记录
            let status = selectedFilter == .active ? "active" : (selectedFilter == .used ? "used" : "expired")
            // 使用更可靠的方式查找对应record
            filteredList = sortedRecords.filter { record in
                // 查找对应的美食券
                return appState.dessertVouchers.contains(where: { 
                    $0.workoutRecordId == record.id && $0.status == status 
                })
            }
        }
        
        // 创建一个record ID到美食券的映射
        let recordIdToVoucher = Dictionary(grouping: appState.dessertVouchers, by: { $0.workoutRecordId ?? "" })
        DRDebug("[FoodCheckInView] 构建记录映射，美食券总数: \(appState.dessertVouchers.count), 有效记录ID映射: \(recordIdToVoucher.count)")
        
        // 按日期分组记录
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年 M月 d日"
        
        // 创建一个集合来追踪已添加的记录ID，避免重复添加
        var addedRecordIds = Set<String>()
        
        // 优先处理新添加的记录，确保它显示在最前面
        if appState.justCompletedWorkout && newRecordId != nil {
            let recordIdString = newRecordId!
            
            // 查找对应的记录
            if let newRecord = sortedRecords.first(where: { "\($0.id)" == recordIdString }) {
                // 查找对应的美食券，必须使用美食券的创建时间
                if let voucher = appState.dessertVouchers.first(where: { $0.workoutRecordId == newRecord.id }) {
                    // 使用美食券的创建日期作为分组依据
                    let voucherDate = voucher.createdAt
                    let dateString = dateFormatter.string(from: voucherDate)
                    
                    if groupedRecords[dateString] == nil {
                        groupedRecords[dateString] = [newRecord]
                    } else {
                        groupedRecords[dateString]?.append(newRecord)
                    }
                    
                    // 标记该ID已添加，避免重复添加
                    addedRecordIds.insert(newRecord.id)
                    
                    DRDebug("[FoodCheckInView] 优先添加新记录到列表(使用美食券日期): id=\(newRecord.id), 日期=\(dateString)")
                } else {
                    // 如果没有美食券，那么就不能显示
                    DRWarning("[FoodCheckInView] 警告: 新记录无对应美食券，无法显示: id=\(newRecord.id)")
                }
            }
        }
        
        // 记录一下处理前的状态，用于诊断
        let filteredCount = filteredList.count
        let recordsCount = sortedRecords.count
        DRDebug("[FoodCheckInView] 开始处理所有记录: 总记录数=\(recordsCount), 筛选后记录数=\(filteredCount), 美食券数=\(vouchersCount)")
        
        // 处理所有记录
        for record in filteredList {
            // 获取record ID
            let recordId = record.id
            
            // 避免重复添加同一记录
            if addedRecordIds.contains(recordId) {
                continue
            }
            
            // 先标记该记录ID已添加，确保不会重复添加
            addedRecordIds.insert(recordId)
            
            // 查找对应的美食券
            if let vouchers = recordIdToVoucher[recordId], !vouchers.isEmpty, let voucher = vouchers.first {
                // 使用美食券的创建日期作为分组依据
                let voucherDate = voucher.createdAt
                let dateString = dateFormatter.string(from: voucherDate)
                
                if groupedRecords[dateString] == nil {
                    groupedRecords[dateString] = [record]
                } else {
                    groupedRecords[dateString]?.append(record)
                }
            } else if appState.justCompletedWorkout && newRecordId == "\(recordId)" {
                // 特殊处理新添加的记录，只有找到对应美食券才能显示
                if let voucher = appState.dessertVouchers.first(where: { $0.workoutRecordId == recordId }) {
                    // 使用美食券的创建日期作为分组依据
                    let voucherDate = voucher.createdAt
                    let dateString = dateFormatter.string(from: voucherDate)
                    
                    if groupedRecords[dateString] == nil {
                        groupedRecords[dateString] = [record]
                    } else {
                        groupedRecords[dateString]?.append(record)
                    }
                    
                    DRDebug("[FoodCheckInView] 添加新记录到列表(使用美食券日期): id=\(recordId), 日期=\(dateString)")
                } else {
                    // 如果没有美食券，不能显示
                    DRWarning("[FoodCheckInView] 警告: 新记录无对应美食券，无法显示: id=\(recordId)")
                }
            }
        }
        
        // 计算实际处理的记录数，用于诊断
        let totalGroupedCount = groupedRecords.values.map { $0.count }.reduce(0, +)
        DRDebug("[FoodCheckInView] 分组后的记录总数: \(totalGroupedCount), 分组数: \(groupedRecords.count)")
        
        if totalGroupedCount < vouchersCount {
            DRWarning("[FoodCheckInView] 警告: 处理后的记录数(\(totalGroupedCount))少于美食券数(\(vouchersCount))")
        }
        
        return groupedRecords
    }
    
    // 获取日期字符串到时间戳的映射
    private func getDateStringToTimestampMapping() -> [String: TimeInterval] {
        var dateToTimestamp = [String: TimeInterval]()
        
        // 遍历所有记录，收集每个日期组的时间戳
        for record in viewModel.getSortedAllRecords() {
            if let voucher = appState.dessertVouchers.first(where: { $0.workoutRecordId == record.id }) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy年 M月 d日"
                let dateString = dateFormatter.string(from: voucher.createdAt)
                let timestamp = voucher.createdAt.timeIntervalSince1970
                
                // 如果已经有这个日期，保留最大的时间戳（最新的记录）
                if let existingTimestamp = dateToTimestamp[dateString], existingTimestamp > timestamp {
                    continue
                }
                
                dateToTimestamp[dateString] = timestamp
            }
        }
        
        return dateToTimestamp
    }
    
    // 所有美食打卡记录
    private var allFoodRecords: some View {
        VStack(spacing: 20) {
            if appState.workoutRecords.isEmpty {
                emptyRecordsView
            } else {
                // 获取筛选后的分组记录 - 存储到临时变量以避免多次计算
                let groupedRecords = filteredRecords
                
                if groupedRecords.isEmpty {
                    // 检查是否是因为刚完成打卡，美食券数据还未更新
                    if appState.justCompletedWorkout {
                        // 显示加载中提示
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.2)
                                .padding()
                            
                            Text("加载新打卡记录...")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .onAppear {
                            // 自动重新加载美食券数据
                            if !viewModel.isLoadingVouchers {
                                DRDebug("[FoodCheckInView] 检测到新完成的打卡但无显示记录，主动加载美食券数据")
                                viewModel.loadVouchersIndependently()
                            }
                        }
                    } else {
                        // 无筛选结果
                        VStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundColor(.gray.opacity(0.5))
                                .padding()
                            
                            Text("未找到符合条件的记录")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    }
                } else {
                    // 获取日期到时间戳的映射表
                    let dateToTimestamp = getDateStringToTimestampMapping()
                    
                    // 使用时间戳进行日期排序
                    let sortedDates = groupedRecords.keys.sorted { dateStr1, dateStr2 in
                        // 从映射表中获取时间戳
                        let timestamp1 = dateToTimestamp[dateStr1] ?? 0
                        let timestamp2 = dateToTimestamp[dateStr2] ?? 0
                        
                        // 按照时间戳倒序排列
                        return timestamp1 > timestamp2
                    }
                    
                    ForEach(sortedDates, id: \.self) { dateString in
                        VStack(alignment: .leading, spacing: 12) {
                            // 日期标题，增加上边距防止被卡片遮挡
                            Text(dateString)
                                .font(.system(size: 16, weight: .medium)) // Title字体样式
                                .padding(.leading, 4)
                                .padding(.top, 12)
                                .padding(.bottom, 6)
                            
                            // 当天的记录，按时间戳倒序排列
                            let sortedRecords = groupedRecords[dateString]!.sorted { record1, record2 in
                                // 如果有新打卡记录，它应该显示在最前面
                                if newRecordId == "\(record1.id)" && appState.justCompletedWorkout {
                                    return true
                                } else if newRecordId == "\(record2.id)" && appState.justCompletedWorkout {
                                    return false
                                }
                                
                                // 获取关联的美食券时间戳
                                let voucher1 = appState.dessertVouchers.first(where: { $0.workoutRecordId == record1.id })
                                let voucher2 = appState.dessertVouchers.first(where: { $0.workoutRecordId == record2.id })
                                
                                // 获取时间戳进行比较，按时间戳倒序（新的在前）
                                let timestamp1 = voucher1?.createdAt.timeIntervalSince1970 ?? 0
                                let timestamp2 = voucher2?.createdAt.timeIntervalSince1970 ?? 0
                                
                                return timestamp1 > timestamp2
                            }
                            
                            // 使用ID作为唯一标识，避免重复渲染
                            ForEach(sortedRecords, id: \.id) { record in
                                // 检查是否是新记录
                                let isNewRecord = newRecordId == "\(record.id)" && dateString == sortedDates.first
                                
                                VStack {
                                    if isNewRecord && showNewRecordAnimation {
                                        // 为新记录显示动画效果，只有从顶部出现的动画
                                        DessertVoucherCardSimple(record: record)
                                            .environmentObject(appState)  // 显式传递AppState
                                            .padding(.horizontal, 8)  // 减少卡片内边距
                                            .transition(.move(edge: .top).combined(with: .opacity))
                                    } else {
                                        DessertVoucherCardSimple(record: record)
                                            .environmentObject(appState)  // 显式传递AppState
                                            .padding(.horizontal, 8)  // 减少卡片内边距
                                    }
                                }
                                .padding(.bottom, 8)  // 减少卡片底部边距
                                // 使用记录ID作为视图的唯一标识符，避免重复渲染
                                .id("voucher-card-\(record.id)")
                                .onAppear {
                                    // 记录显示时打印调试信息
                                    if let voucher = appState.dessertVouchers.first(where: { $0.workoutRecordId == record.id }) {
                                        let dateFormatter = DateFormatter()
                                        dateFormatter.dateFormat = "yyyy-MM-dd"
                                        let createdDateStr = dateFormatter.string(from: voucher.createdAt)
                                        DRDebug("[FoodCheckInView] 渲染记录: id=\(record.id), 美食券日期=\(createdDateStr)")
                                    }
                                }
                            }
                        }
                    }
                    
                    // 修改加载更多按钮 - 始终显示按钮，不再使用if viewModel.hasMoreVouchers判断
                    Button(action: {
                        DRInfo("[FoodCheckInView] 用户点击加载更多美食券按钮，当前页: \(viewModel.currentVoucherPage), 总数: \(viewModel.totalVouchersCount), 已加载: \(appState.dessertVouchers.count)")
                        viewModel.loadMoreVouchers()
                        
                        // 延迟一点时间再强制刷新视图，确保数据加载有时间完成
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.forceRefresh.toggle()
                            DRInfo("[FoodCheckInView] 加载更多后强制刷新，当前记录数: \(appState.dessertVouchers.count)")
                        }
                    }) {
                        HStack {
                            if viewModel.isLoadingMoreVouchers {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .frame(width: 18, height: 18)
                                    .padding(.trailing, 6)
                            }
                            
                            // 根据状态显示不同文本
                            if appState.dessertVouchers.isEmpty {
                                Text("暂无记录")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            } else if viewModel.noMoreVouchersConfirmed {
                                Text("没有更多记录了")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            } else if viewModel.isLoadingMoreVouchers {
                                Text("加载中...")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            } else {
                                Text("加载更多")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    // 仅在确认无更多记录或正在加载时禁用按钮
                    .disabled(viewModel.isLoadingMoreVouchers || viewModel.noMoreVouchersConfirmed)
                    // 使用ID确保按钮的状态变化能触发重新渲染
                    .id("load-more-btn-\(viewModel.isLoadingMoreVouchers)-\(viewModel.noMoreVouchersConfirmed)-\(forceRefresh)")
                    .onAppear {
                        DRInfo("[FoodCheckInView] 显示加载更多按钮，当前记录数: \(appState.dessertVouchers.count), 总记录数: \(viewModel.totalVouchersCount)")
                    }
                }
            }
        }
    }
    
    // 空记录视图
    private var emptyRecordsView: some View {
        VStack {
            Image(systemName: "tray.fill")
                .font(.system(size: 32))
                .foregroundColor(.gray.opacity(0.5))
                .padding()
            
            Text("暂无美食打卡记录")
                .font(.system(size: 16))  // Body字体样式
                .foregroundColor(.gray)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - 展开的卡片详情视图
struct ExpandedCardView: View {
    let record: WorkoutRecord
    @Binding var isShowing: Bool
    @State private var isShared: Bool = false
    let preloadedImageInfo: [String: Any]?
    
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
            VStack(spacing: 16) {
                // 顶部关闭按钮 - 右上角
                HStack {
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isShowing = false
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.9))
                                .frame(width: 32, height: 32)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .zIndex(1) // 确保关闭按钮在最上层
                
                // 美食券卡片（展开状态）- 尺寸更大
                // 传递预加载的图片信息，避免重复加载
                DessertVoucherCardSimple(record: record, forceExpanded: true)
                    .frame(width: UIScreen.main.bounds.width - 40)  // 确保卡片宽度合适
                    .onAppear {
                        // 如果有预加载的图片信息，记录日志
                        if let preloaded = preloadedImageInfo?["preloadedImages"] as? Bool, preloaded {
                            DRDebug("[ExpandedCardView] 使用了预加载的图片信息，减少重复加载")
                        }
                    }
                
                // 底部分享按钮 - 更新样式与Figma一致
                Button(action: {
                    // 分享逻辑
                    isShared = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                        
                        Text("分享可以获得5颗星星")
                            .font(.system(size: 14, weight: .medium))  // Body Bold字体样式
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 28)
                    .frame(minWidth: 260)
                    .background(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    Color(hex: "#FE2D55"),
                                    Color(hex: "#FF896E")
                                ]
                            ),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 6)
                .padding(.bottom, 20)
            }
            .background(Color.white.opacity(0))
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $isShared) {
            // 分享视图
            VStack {
                Text("分享美食券")
                    .font(.system(size: 18, weight: .medium))  // Title字体样式
                    .padding()
                
                Text("分享\(record.dessert.name)的美食打卡记录")
                    .font(.system(size: 16))  // Body字体样式
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


