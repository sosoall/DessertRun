import SwiftUI
import Combine

// 星币钱包页面
struct StarWalletView: View {
    @StateObject private var viewModel = StarWalletViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    // 分页控制
    @State private var currentPage = 1
    @State private var isLoadingMore = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 余额卡片
                balanceCard
                
                // 统计卡片
                statsCard
                
                // 交易记录
                transactionsSection
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
        .background(Color(hex: "fae8c8").ignoresSafeArea())
        .navigationTitle("星币钱包")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchWalletInfo()
            viewModel.fetchTransactions(page: 1)
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("出错了"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("确定"))
            )
        }
    }
    
    // 余额卡片
    private var balanceCard: some View {
        VStack(spacing: 12) {
            Text("星币余额")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Text("\(viewModel.wallet?.stars ?? 0)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                Button(action: {
                    // 充值操作
                }) {
                    Text("充值")
                        .font(.headline)
                        .foregroundColor(Color(hex: "FE2D55"))
                        .frame(width: 100)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(20)
                }
                
                NavigationLink(destination: VIPMembershipView()) {
                    Text("兑换VIP")
                        .font(.headline)
                        .foregroundColor(Color(hex: "FE2D55"))
                        .frame(width: 100)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(20)
                }
            }
            .padding(.top, 8)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(gradient: Gradient(colors: [Color(hex: "FE2D55"), Color(hex: "FF6E53")]), startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    // 统计卡片
    private var statsCard: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 4) {
                Text("\(viewModel.wallet?.totalEarned ?? 0)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "61462C"))
                
                Text("累计获得")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 30)
            
            VStack(spacing: 4) {
                Text("\(viewModel.wallet?.totalSpent ?? 0)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(hex: "61462C"))
                
                Text("累计消费")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .padding(.vertical, 15)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // 交易记录部分
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("交易记录")
                .font(.headline)
                .foregroundColor(Color(hex: "61462C"))
            
            if viewModel.isLoading && viewModel.transactions.isEmpty {
                loadingView
            } else if viewModel.transactions.isEmpty {
                emptyTransactionsView
            } else {
                transactionsList
            }
        }
    }
    
    // 加载中视图
    private var loadingView: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
                .padding()
            
            Text("加载中...")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(Color.white)
        .cornerRadius(15)
    }
    
    // 空交易记录视图
    private var emptyTransactionsView: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.bottom, 10)
            
            Text("暂无交易记录")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("完成运动打卡可以获得星币哦~")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(Color.white)
        .cornerRadius(15)
    }
    
    // 交易列表
    private var transactionsList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.transactions) { transaction in
                transactionRow(transaction: transaction)
                
                if transaction.id != viewModel.transactions.last?.id {
                    Divider()
                        .padding(.leading, 60)
                }
            }
            
            if viewModel.hasMorePages {
                loadMoreButton
            }
        }
        .background(Color.white)
        .cornerRadius(15)
    }
    
    // 交易记录行
    private func transactionRow(transaction: Transaction) -> some View {
        HStack(spacing: 15) {
            // 图标
            ZStack {
                Circle()
                    .fill(transaction.amount > 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .frame(width: 45, height: 45)
                
                Image(systemName: transaction.amount > 0 ? "arrow.down" : "arrow.up")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(transaction.amount > 0 ? .green : .red)
            }
            
            // 描述和时间
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.description)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(formatDate(transaction.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 金额
            Text(transaction.amount > 0 ? "+\(transaction.amount)" : "\(transaction.amount)")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(transaction.amount > 0 ? .green : .red)
        }
        .padding()
    }
    
    // 加载更多按钮
    private var loadMoreButton: some View {
        Button(action: {
            loadMoreTransactions()
        }) {
            HStack {
                Text(isLoadingMore ? "加载中..." : "加载更多")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if isLoadingMore {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.7)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .disabled(isLoadingMore)
    }
    
    // 加载更多交易记录
    private func loadMoreTransactions() {
        guard !isLoadingMore else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        viewModel.fetchTransactions(page: currentPage) {
            isLoadingMore = false
        }
    }
    
    // 格式化日期
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// 星币钱包视图模型
class StarWalletViewModel: ObservableObject {
    // 钱包信息
    @Published var wallet: UserWallet?
    
    // 交易记录
    @Published var transactions: [Transaction] = []
    @Published var hasMorePages = false
    @Published var totalTransactions = 0
    
    // 加载状态
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    // 取消令牌
    private var cancellables = Set<AnyCancellable>()
    
    // 获取钱包信息
    func fetchWalletInfo() {
        isLoading = true
        APIService.shared.getWalletInfo()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    if case let .failure(error) = completion {
                        self.showError = true
                        self.errorMessage = error.errorMessage
                    }
                },
                receiveValue: { [weak self] wallet in
                    guard let self = self else { return }
                    self.wallet = wallet
                }
            )
            .store(in: &cancellables)
    }
    
    // 获取交易记录
    func fetchTransactions(page: Int, completion: (() -> Void)? = nil) {
        isLoading = true
        APIService.shared.getTransactions(page: page)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false
                    if case let .failure(error) = completion {
                        self.showError = true
                        self.errorMessage = error.errorMessage
                    }
                    if let completionHandler = completion {
                        completionHandler()
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    
                    if page == 1 {
                        // 第一页，替换数据
                        self.transactions = response.transactions
                    } else {
                        // 追加数据
                        self.transactions.append(contentsOf: response.transactions)
                    }
                    
                    self.totalTransactions = response.total
                    self.hasMorePages = self.transactions.count < response.total
                    
                    if let completionHandler = completion {
                        completionHandler()
                    }
                }
            )
            .store(in: &cancellables)
    }
}

// 预览
struct StarWalletView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StarWalletView()
        }
    }
} 