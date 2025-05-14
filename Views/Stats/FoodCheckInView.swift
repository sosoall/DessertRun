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
    @State private var viewModelAddress: String = "" // 存储ViewModel的内存地址，用于调试
    
    var body: some View {
        ZStack {
            // 主内容
            ScrollView {
                VStack(spacing: 24) {
                    // 调试信息显示
                    if !viewModelAddress.isEmpty {
                        Text("VM地址: \(viewModelAddress)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
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
                ExpandedCardView(record: record, isShowing: $showExpandedCard)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            // 记录ViewModel的内存地址，用于调试追踪
            viewModelAddress = "\(Unmanaged.passUnretained(viewModel).toOpaque())"
            DRDebug("[FoodCheckInView] 视图出现，使用ViewModel实例: \(viewModelAddress)")
            
            // 使用hasAppeared标志防止多次调用
            if !hasAppeared {
                DRDebug("[FoodCheckInView] 首次显示，准备加载数据，ViewModel实例: \(viewModelAddress)")
                
                // 立即设置标志，防止重复加载
                hasAppeared = true
                
                // 延迟加载，确保视图已完全呈现
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    DRDebug("[FoodCheckInView] 开始加载数据，ViewModel实例: \(viewModelAddress)")
                    viewModel.loadData() // 这会同时加载打卡记录、美食券和排行榜数据
                    
                    // 强制刷新UI，确保使用正确的ViewModel实例
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        DRDebug("[FoodCheckInView] 延迟刷新，ViewModel数据数量: \(self.viewModel.topDesserts.count), 美食券数量: \(self.appState.dessertVouchers.count)")
                        self.forceRefresh.toggle()
                    }
                    
                    // 再次尝试获取美食券数据并刷新
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        // 直接从服务调用获取美食券
                        self.viewModel.loadDessertVouchers()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.forceRefresh.toggle()
                            DRDebug("[FoodCheckInView] 二次延迟刷新，美食券数量: \(self.appState.dessertVouchers.count)")
                        }
                    }
                    
                    // 打印一下所有ViewModel的状态
                    for i in 0...3 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)) {
                            DRDebug("[FoodCheckInView] ViewModel状态检查 \(i)秒后: 数据量\(self.viewModel.topDesserts.count), 美食券数量: \(self.appState.dessertVouchers.count)")
                        }
                    }
                    
                    // 仅当刚完成打卡时才显示动画
                    if appState.justCompletedWorkout, let latestRecord = viewModel.getSortedAllRecords().first {
                        DRDebug("[FoodCheckInView] 检测到新记录，准备显示动画")
                        // 将新记录ID存入状态变量
                        newRecordId = "\(latestRecord.id)"
                        
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
            } else {
                DRDebug("[FoodCheckInView] 视图已显示过，执行刷新，美食券数量: \(appState.dessertVouchers.count)")
                
                // 无论如何都重新加载美食券数据
                viewModel.loadDessertVouchers()
                
                // 短暂延迟后强制刷新UI
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.forceRefresh.toggle()
                }
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
            
            // 添加美食券数据更新通知的观察者
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("VouchersUpdated"),
                object: nil,
                queue: .main
            ) { _ in
                DRDebug("[FoodCheckInView] 收到美食券数据更新通知，当前美食券数量: \(self.appState.dessertVouchers.count)")
                // 强制刷新视图
                DispatchQueue.main.async {
                    self.forceRefresh.toggle()
                }
            }
            
            // 修改TopDessertsUpdated通知观察者，移除[weak self]
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("TopDessertsUpdated"),
                object: nil,
                queue: .main
            ) { notification in
                // 检查通知中的ViewModel实例
                if let notificationViewModel = notification.userInfo?["viewModel"] as? FoodCheckInViewModel {
                    let notificationViewModelAddress = Unmanaged.passUnretained(notificationViewModel).toOpaque()
                    let selfViewModelAddress = Unmanaged.passUnretained(self.viewModel).toOpaque()
                    
                    DRDebug("[FoodCheckInView] 收到排行榜数据更新通知，通知的ViewModel: \(notificationViewModelAddress)，当前ViewModel: \(selfViewModelAddress)")
                    
                    // 两个实例不同时，需要强制更新数据
                    if notificationViewModelAddress != selfViewModelAddress {
                        DRWarning("[FoodCheckInView] 检测到不同的ViewModel实例，强制同步数据")
                        if let items = notification.userInfo?["items"] as? [StatTopDessertItem], !items.isEmpty {
                            DispatchQueue.main.async {
                                // 直接从通知获取数据并更新
                                self.viewModel.topDesserts = items
                                self.forceRefresh.toggle()
                            }
                        }
                    }
                }
                
                // 无论如何只刷新一次UI
                self.forceRefresh.toggle()
                DRDebug("[FoodCheckInView] 强制刷新状态已切换: \(self.forceRefresh)")
            }
            
            // 修改RankingImageLoaded通知观察者，移除[weak self]
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("RankingImageLoaded"),
                object: nil,
                queue: .main
            ) { notification in
                // 收到图片加载完成的通知，强制刷新UI
                if let itemId = notification.object as? String {
                    DRDebug("[FoodCheckInView] 收到排行榜图片加载完成通知，项目ID: \(itemId)，强制刷新UI")
                } else {
                    DRDebug("[FoodCheckInView] 收到排行榜图片加载完成通知，强制刷新UI")
                }
                
                // 直接刷新UI，无需多次刷新
                self.forceRefresh.toggle()
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
            
            // 移除排行榜图片加载完成的观察者
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("RankingImageLoaded"),
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
                // 直接创建排行榜卡片，不使用计算属性
                VStack(spacing: 16) {
                    // 标题栏
                    HStack {
                        Text("美食排行榜")
                            .font(.system(size: 16, weight: .medium))
                        
                        Spacer()
                        
                        // 刷新按钮
                        Button(action: {
                            // 刷新排行榜数据
                            viewModel.loadTopDesserts(limit: 5)
                            DRDebug("[FoodCheckInView] 用户手动刷新排行榜")
                            
                            // 强制刷新UI
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                forceRefresh.toggle()
                                DRDebug("[FoodCheckInView] 刷新排行榜后强制刷新UI: \(viewModel.topDesserts.count)项")
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14))
                                .foregroundColor(viewModel.isLoadingTopDesserts ? .gray : .blue)
                        }
                        .disabled(viewModel.isLoadingTopDesserts)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
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
                        .frame(height: 120)
                    } else if viewModel.topDesserts.isEmpty {
                        // 空状态
                        HStack {
                            Spacer()
                            VStack {
                                Text("暂无记录")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .padding()
                            }
                            Spacer()
                        }
                        .frame(height: 120)
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
                            LazyHStack(spacing: 24) {
                                ForEach(viewModel.topDesserts.prefix(4), id: \.id) { dessert in
                                    VStack(spacing: 8) {
                                        ZStack(alignment: .top) {
                                            VStack {
                                                Spacer()
                                                
                                                // 使用CachedImage加载图片
                                                CachedImage(url: dessert.imageName, dessertId: dessert.dessertId)
                                                    .scaledToFit()
                                                    .frame(height: dessert.id == viewModel.topDesserts.first?.id ? 120 : 75)
                                                    .cornerRadius(8)
                                            }
                                            .frame(height: 120)
                                            
                                            if dessert.id == viewModel.topDesserts.first?.id {
                                                Image("crown")
                                                    .resizable()
                                                    .renderingMode(.original)
                                                    .scaledToFit()
                                                    .frame(width: 40, height: 40)
                                                    .offset(x: 10, y: -15)
                                            }
                                        }
                                        .onAppear {
                                            DRDebug("[FoodCheckInView] 渲染排行榜项目: \(dessert.name)")
                                        }
                                        
                                        Text("打卡\(dessert.count)次")
                                            .font(.system(size: 12))
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                        }
                        .onAppear {
                            DRDebug("[FoodCheckInView] 排行榜显示数据: \(viewModel.topDesserts.count)项")
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                .id("topDesserts-\(forceRefresh)")
                .onAppear {
                    DRDebug("[FoodCheckInView] 排行榜卡片出现，数据数量: \(viewModel.topDesserts.count)")
                }
                
                // 数据统计卡片行
                HStack(spacing: 16) {
                    foodCheckInCountCard
                    foodVarietyCard
                }
            }
        }
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
        // 创建时间戳到日期字符串的映射，用于正确排序
        var timestampToString = [TimeInterval: String]()
        // 创建日期字符串到时间戳的映射，用于后续排序
        var stringToTimestamp = [String: TimeInterval]()
        
        // 添加调试日志，查看美食券数据
        let vouchersCount = appState.dessertVouchers.count
        DRDebug("[FoodCheckInView] 过滤记录: 美食券数量=\(vouchersCount), 打卡记录数量=\(sortedRecords.count)")
        
        // 打印几个美食券样本，确认日期
        if !appState.dessertVouchers.isEmpty {
            for (index, voucher) in appState.dessertVouchers.prefix(3).enumerated() {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let createdDateStr = dateFormatter.string(from: voucher.createdAt)
                let timestamp = voucher.createdAt.timeIntervalSince1970
                DRDebug("[FoodCheckInView] 美食券样本[\(index)]: id=\(voucher.id), 创建日期=\(createdDateStr), 时间戳=\(timestamp), workoutRecordId=\(voucher.workoutRecordId ?? "nil")")
            }
        } else {
            DRDebug("[FoodCheckInView] 警告: 没有美食券数据!")
            // 尝试重新加载美食券数据
            DispatchQueue.main.async {
                self.viewModel.loadDessertVouchers()
            }
        }
        
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
        
        // FIXME: 修复了美食券列表按日期分组显示问题 - 2025/5/15
        // 原问题: 美食券列表中日期显示为固定的2025年5月14日，而不是实际的创建日期
        // 解决方案: 使用美食券的createdAt字段作为分组依据，而不是workoutRecord的date字段
        // 
        // FIXME: 修复了美食券日期排序问题 - 2025/5/16
        // 原问题: 美食券列表按照字符串而非时间戳排序，导致时间顺序错误(5.9显示在5.14前面)
        // 解决方案: 使用时间戳进行排序，确保最新日期显示在最前
        var recordsProcessed = 0
        for record in filteredList {
            // 查找对应的美食券
            if let voucher = appState.dessertVouchers.first(where: { $0.workoutRecordId == record.id }) {
                // 使用美食券的创建日期而不是记录日期
                let voucherDate = voucher.createdAt
                // 获取时间戳
                let timestamp = voucherDate.timeIntervalSince1970
                
                // 添加日期调试记录
                let debugDateFormatter = DateFormatter()
                debugDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let debugDateStr = debugDateFormatter.string(from: voucherDate)
                if recordsProcessed < 5 {
                    DRDebug("[FoodCheckInView] 美食券[\(voucher.id)]原始创建日期: \(debugDateStr), 时间戳: \(timestamp)")
                }
                
                // 使用年月日格式化为展示日期
                let dateString = dateFormatter.string(from: voucherDate)
                
                if recordsProcessed < 5 {
                    // 记录前几条数据的日期信息，用于调试
                    DRDebug("[FoodCheckInView] 记录[\(recordsProcessed)]: 美食券[\(voucher.id)] 格式化后日期=\(dateString), 时间戳=\(timestamp)")
                }
                
                if groupedRecords[dateString] == nil {
                    groupedRecords[dateString] = [record]
                } else {
                    groupedRecords[dateString]?.append(record)
                }
            } else {
                // 如果没有找到对应的美食券，则直接跳过该记录
                // 我们只显示有美食券的打卡记录
                if recordsProcessed < 5 {
                    DRDebug("[FoodCheckInView] 记录[\(recordsProcessed)]: 未找到美食券，跳过 id=\(record.id)")
                }
                continue
            }
            recordsProcessed += 1
        }
        
        // 记录分组后的结果 - 使用字符串排序只是用于调试显示
        let groupDates = groupedRecords.keys.sorted(by: >)
        DRDebug("[FoodCheckInView] 记录分组结果: 共\(groupDates.count)个日期组，日期: \(groupDates)")
        
        // 打印各个日期组的时间戳排序信息（用于调试）
        if !groupedRecords.isEmpty {
            var dateToTimestamp = [String: TimeInterval]()
            
            // 收集每个日期组的第一条记录时间戳
            for dateString in groupedRecords.keys {
                if let records = groupedRecords[dateString], 
                   let firstRecord = records.first, 
                   let voucher = appState.dessertVouchers.first(where: { $0.workoutRecordId == firstRecord.id }) {
                    let timestamp = voucher.createdAt.timeIntervalSince1970
                    dateToTimestamp[dateString] = timestamp
                    DRDebug("[FoodCheckInView] 日期组时间戳: 日期=\(dateString), 时间戳=\(timestamp)")
                }
            }
            
            // 按时间戳排序的日期
            let sortedByTimestamp = dateToTimestamp.sorted { $0.value > $1.value }.map { $0.key }
            DRDebug("[FoodCheckInView] 按时间戳排序的日期组顺序: \(sortedByTimestamp)")
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
                        VStack(alignment: .leading, spacing: 16) {
                            // 日期标题，增加上边距防止被卡片遮挡
                            Text(dateString)
                                .font(.system(size: 18, weight: .medium))
                                .padding(.leading, 4)
                                .padding(.top, 16)
                                .padding(.bottom, 8)
                            
                            // 当天的记录，按时间戳倒序排列
                            let sortedRecords = groupedRecords[dateString]!.sorted { record1, record2 in
                                // 获取关联的美食券时间戳
                                let voucher1 = appState.dessertVouchers.first(where: { $0.workoutRecordId == record1.id })
                                let voucher2 = appState.dessertVouchers.first(where: { $0.workoutRecordId == record2.id })
                                
                                // 获取时间戳进行比较，按时间戳倒序（新的在前）
                                let timestamp1 = voucher1?.createdAt.timeIntervalSince1970 ?? 0
                                let timestamp2 = voucher2?.createdAt.timeIntervalSince1970 ?? 0
                                
                                return timestamp1 > timestamp2
                            }
                            
                            ForEach(sortedRecords, id: \.id) { record in
                                // 检查是否是新记录
                                let isNewRecord = newRecordId == "\(record.id)" && dateString == sortedDates.first
                                
                                VStack {
                                    if isNewRecord && showNewRecordAnimation {
                                        // 为新记录显示动画效果，只有从顶部出现的动画
                                        DessertVoucherCardSimple(record: record)
                                            .environmentObject(appState)  // 显式传递AppState
                                            .padding(.horizontal, 12)  // 额外卡片内边距
                                            .transition(.move(edge: .top).combined(with: .opacity))
                                    } else {
                                        DessertVoucherCardSimple(record: record)
                                            .environmentObject(appState)  // 显式传递AppState
                                            .padding(.horizontal, 12)  // 额外卡片内边距
                                    }
                                }
                                .padding(.bottom, 12)  // 增加卡片底部边距
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
                                .frame(width: 36, height: 36)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .zIndex(1) // 确保关闭按钮在最上层
                
                // 美食券卡片（展开状态）- 尺寸更大
                DessertVoucherCardSimple(record: record, forceExpanded: true)
                    .frame(width: UIScreen.main.bounds.width - 40)  // 确保卡片宽度合适
                
                // 底部分享按钮 - 更新样式与Figma一致
                Button(action: {
                    // 分享逻辑
                    isShared = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                        
                        Text("分享可以获得5颗星星")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 32)
                    .frame(minWidth: 280)
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
                    .cornerRadius(30)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color.white.opacity(0))
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

