import SwiftUI
import Combine

// VIP会员页面
struct VIPMembershipView: View {
    @StateObject private var viewModel = VIPMembershipViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    // 选中的套餐ID
    @State private var selectedPackageID: String?
    
    // 确认购买对话框状态
    @State private var showPurchaseConfirm = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // VIP状态卡片
                vipStatusCard
                
                // VIP特权说明
                vipBenefitsSection
                
                // VIP套餐列表
                vipPackagesSection
            }
            .padding(.horizontal)
            .padding(.top, 16)
        }
        .background(Color(hex: "fae8c8").ignoresSafeArea())
        .navigationTitle("VIP会员")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchVIPInfo()
            viewModel.fetchVIPPackages()
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("出错了"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("确定"))
            )
        }
        .alert("确认购买", isPresented: $showPurchaseConfirm) {
            Button("取消", role: .cancel) { }
            Button("确认购买", role: .destructive) {
                if let packageID = selectedPackageID {
                    viewModel.purchaseVIP(packageID: packageID)
                }
            }
        } message: {
            Text("确认使用星币购买VIP套餐？")
        }
    }
    
    // VIP状态卡片
    private var vipStatusCard: some View {
        VStack(spacing: 10) {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
                    .padding()
            } else if let vipInfo = viewModel.vipInfo {
                // 会员等级和图标
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 30))
                        .foregroundColor(vipInfo.isVIP ? Color.yellow : Color.gray)
                    
                    Text(vipInfo.isVIP ? "VIP会员" : "普通用户")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(vipInfo.isVIP ? Color(hex: "61462C") : Color.gray)
                }
                .padding(.bottom, 5)
                
                // 会员状态和到期日期
                VStack(spacing: 8) {
                    if vipInfo.isVIP {
                        Text("会员有效期")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Text("剩余\(vipInfo.remainingDays ?? 0)天")
                            .font(.headline)
                            .foregroundColor(Color(hex: "FE2D55"))
                        
                        Text("到期日期: \(vipInfo.expireDate ?? "未知")")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("成为VIP会员，享受更多特权")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            } else {
                Text("获取VIP信息失败")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // VIP特权说明
    private var vipBenefitsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("VIP特权")
                .font(.headline)
                .foregroundColor(Color(hex: "61462C"))
            
            VStack(spacing: 12) {
                benefitRow(icon: "checkmark.circle.fill", title: "无广告体验", description: "享受无广告纯净体验")
                
                Divider()
                    .padding(.leading, 35)
                
                benefitRow(icon: "star.fill", title: "每日奖励翻倍", description: "每日运动奖励星币翻倍")
                
                Divider()
                    .padding(.leading, 35)
                
                benefitRow(icon: "lock.open.fill", title: "专属运动数据", description: "解锁更多专业运动分析")
                
                Divider()
                    .padding(.leading, 35)
                
                benefitRow(icon: "flame.fill", title: "专属挑战", description: "参与VIP专属活动和挑战")
            }
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
    
    // 特权行
    private func benefitRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "FE2D55"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color(hex: "61462C"))
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
    
    // VIP套餐列表
    private var vipPackagesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("VIP套餐")
                .font(.headline)
                .foregroundColor(Color(hex: "61462C"))
            
            if viewModel.isLoading && viewModel.packages.isEmpty {
                loadingView
            } else if viewModel.packages.isEmpty {
                Text("暂无可用套餐")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.packages) { package in
                        packageRow(package: package)
                    }
                }
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
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
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color.white)
        .cornerRadius(15)
    }
    
    // 套餐行
    private func packageRow(package: VIPPackage) -> some View {
        Button(action: {
            selectedPackageID = package.id
            showPurchaseConfirm = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(package.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(package.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 5) {
                    Text("\(package.starPrice) 星币")
                        .font(.headline)
                        .foregroundColor(Color(hex: "FE2D55"))
                    
                    Text("\(package.durationDays) 天")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.horizontal)
        .buttonStyle(PlainButtonStyle())
    }
}

// VIP会员视图模型
class VIPMembershipViewModel: ObservableObject {
    @Published var vipInfo: VIPInfo?
    @Published var packages: [VIPPackage] = []
    
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    // 获取VIP信息
    func fetchVIPInfo() {
        isLoading = true
        APIService.shared.getVIPInfo()
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
                receiveValue: { [weak self] vipInfo in
                    guard let self = self else { return }
                    self.vipInfo = vipInfo
                }
            )
            .store(in: &cancellables)
    }
    
    // 获取VIP套餐
    func fetchVIPPackages() {
        isLoading = true
        APIService.shared.getVIPPackages()
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
                receiveValue: { [weak self] packages in
                    guard let self = self else { return }
                    self.packages = packages
                }
            )
            .store(in: &cancellables)
    }
    
    // 购买VIP
    func purchaseVIP(packageID: String) {
        isLoading = true
        APIService.shared.purchaseVIP(packageID: packageID)
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
                receiveValue: { [weak self] success in
                    guard let self = self else { return }
                    if success {
                        // 购买成功，刷新VIP信息
                        self.fetchVIPInfo()
                    }
                }
            )
            .store(in: &cancellables)
    }
}

// 预览
struct VIPMembershipView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VIPMembershipView()
        }
    }
} 