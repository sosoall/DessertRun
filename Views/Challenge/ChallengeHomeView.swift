import SwiftUI

/// 挑战首页视图
struct ChallengeHomeView: View {
    // 环境对象
    @EnvironmentObject var appState: AppState
    
    // 视图模型
    @StateObject private var viewModel = ChallengeViewModel(appState: AppState.shared)
    
    // 屏幕尺寸
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // UI状态
    @State private var showUserEnrollments = false
    @State private var selectedFilter: String = "all" // "all", "free", "paid"
    
    var body: some View {
        ZStack {
            // 背景色
            Color(hex: "F5F5F5")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航区域
                topNavigationArea
                
                // 筛选器区域
                filterArea
                
                // 内容区域
                ScrollView {
                    // 留出距离顶部的间距
                    LazyVStack(spacing: 0) {
                        // 主要内容
                        contentArea
                    }
                    .padding(.horizontal, 16)
                }
                .refreshable {
                    // 下拉刷新
                    viewModel.loadChallenges()
                    viewModel.loadEnrollments()
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
            
            // 加载中指示器
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
            
            // 错误提示
            if let errorMessage = viewModel.errorMessage {
                VStack {
                    Text("出错了")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                    
                    Button("重试") {
                        viewModel.loadChallenges()
                        viewModel.loadEnrollments()
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.DessertRun.accent)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.1))
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showUserEnrollments) {
            EnrolledChallengeView()
                .environmentObject(appState)
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
                    .shadow(color: Color.black.opacity(0.1), radius: 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Color.white)
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
                
                // 可以添加更多筛选器...
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
    }
    
    // 主要内容区域
    private var contentArea: some View {
        Group {
            if viewModel.filteredActivities.isEmpty {
                // 空状态
                if viewModel.isLoading {
                    // 正在加载中，显示空白
                    Color.clear
                        .frame(height: 300)
                } else {
                    // 没有数据
                    VStack(spacing: 16) {
                        Image(systemName: "trophy")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("暂无挑战活动")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Button("刷新") {
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
            } else {
                // 挑战列表（使用瀑布流布局）
                WaterfallGrid(
                    data: viewModel.filteredActivities,
                    columns: horizontalSizeClass == .regular ? 3 : 2,
                    horizontalSpacing: 12,
                    verticalSpacing: 12
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
                .padding(.top, 12)
                .padding(.bottom, 100) // 添加底部空间，避免内容被遮挡
            }
        }
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
        ChallengeHomeView()
            .environmentObject(AppState.shared)
    }
} 