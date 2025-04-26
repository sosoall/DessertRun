import SwiftUI

/// 用户信息设置页面 - 新用户注册后的信息收集
struct UserInfoSetupView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var viewModel = UserInfoSetupViewModel()
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var showSuccessMessage = false
    @State private var navigateToMainView = false
    
    private let totalSteps = 6
    
    var body: some View {
        NavigationStack {
            ZStack {
                if navigateToMainView {
                    MainTabView()
                        .environmentObject(appState)
                } else {
                    VStack(spacing: 0) {
                        // 进度条
                        StepProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                            .padding(.top, 20)
                            .padding(.horizontal, 30)
                        
                        // 内容区域
                        ScrollView {
                            VStack(alignment: .leading, spacing: 25) {
                                // 标题
                                setupTitle()
                                    .padding(.top, 20)
                                
                                // 表单内容
                                VStack(alignment: .leading, spacing: 30) {
                                    formContent()
                                }
                                .padding(.top, 5)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                        }
                        
                        // 底部按钮区域
                        bottomButtons()
                    }
                    
                    // 显示完成动画
                    if showSuccessMessage {
                        SuccessMessageView(message: "个人信息已设置完成！")
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: backButton)
        }
    }
    
    // 返回按钮
    private var backButton: some View {
        Button(action: {
            if currentStep > 0 {
                currentStep -= 1
            }
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.primary)
                .padding(10)
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                )
        }
        .opacity(currentStep > 0 ? 1 : 0)
        .disabled(currentStep == 0)
    }
    
    // 标题部分
    @ViewBuilder
    private func setupTitle() -> some View {
        switch currentStep {
        case 0:
            stepTitle("设置个人资料", subtitle: "请设置您的昵称")
        case 1:
            stepTitle("设置个人资料", subtitle: "请选择您的性别")
        case 2:
            stepTitle("身体数据", subtitle: "请输入您的身高")
        case 3:
            stepTitle("身体数据", subtitle: "请输入您的体重")
        case 4:
            stepTitle("运动习惯", subtitle: "您是否有运动习惯？")
        case 5:
            stepTitle("运动习惯", subtitle: "您平均每周运动几次？")
        default:
            stepTitle("设置完成", subtitle: "您的个人资料已设置完成")
        }
    }
    
    // 标题组件
    private func stepTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // 表单内容区域
    @ViewBuilder
    private func formContent() -> some View {
        switch currentStep {
        case 0:
            // 昵称设置
            VStack(alignment: .leading, spacing: 10) {
                Text("昵称")
                    .font(.headline)
                
                TextField("请输入昵称", text: $viewModel.nickname)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
        case 1:
            // 性别选择
            VStack(alignment: .leading, spacing: 20) {
                Text("性别")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    GenderOptionButton(title: "男", isSelected: viewModel.user.gender == .male) {
                        viewModel.user.gender = .male
                    }
                    
                    GenderOptionButton(title: "女", isSelected: viewModel.user.gender == .female) {
                        viewModel.user.gender = .female
                    }
                }
            }
            
        case 2:
            // 身高设置
            VStack(alignment: .leading, spacing: 10) {
                Text("身高（厘米）")
                    .font(.headline)
                
                HStack {
                    Slider(value: Binding(
                        get: { viewModel.user.height ?? 170 },
                        set: { viewModel.user.height = $0 }
                    ), in: 140...220, step: 1)
                    
                    Text("\(Int(viewModel.user.height ?? 170))")
                        .font(.headline)
                        .frame(width: 50)
                }
            }
            
        case 3:
            // 体重设置
            VStack(alignment: .leading, spacing: 10) {
                Text("体重（公斤）")
                    .font(.headline)
                
                HStack {
                    Slider(value: Binding(
                        get: { viewModel.user.weight ?? 60 },
                        set: { viewModel.user.weight = $0 }
                    ), in: 30...150, step: 1)
                    
                    Text("\(Int(viewModel.user.weight ?? 60))")
                        .font(.headline)
                        .frame(width: 50)
                }
            }
            
        case 4:
            // 是否有运动习惯
            VStack(alignment: .leading, spacing: 20) {
                Text("您是否有运动习惯？")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    ExerciseHabitButton(title: "是", isSelected: viewModel.user.hasExerciseHabit == true) {
                        viewModel.user.hasExerciseHabit = true
                    }
                    
                    ExerciseHabitButton(title: "否", isSelected: viewModel.user.hasExerciseHabit == false) {
                        viewModel.user.hasExerciseHabit = false
                    }
                }
            }
            
        case 5:
            // 运动频率
            VStack(alignment: .leading, spacing: 20) {
                Text("您的运动频率是？")
                    .font(.headline)
                
                VStack(spacing: 15) {
                    FrequencyOptionButton(
                        title: "不经常运动",
                        isSelected: viewModel.user.exerciseFrequency == User.ExerciseFrequency.none
                    ) {
                        viewModel.user.exerciseFrequency = User.ExerciseFrequency.none
                    }
                    
                    FrequencyOptionButton(
                        title: "每周1-2次",
                        isSelected: viewModel.user.exerciseFrequency == .oneToTwo
                    ) {
                        viewModel.user.exerciseFrequency = .oneToTwo
                    }
                    
                    FrequencyOptionButton(
                        title: "每周3-5次",
                        isSelected: viewModel.user.exerciseFrequency == .threeToFive
                    ) {
                        viewModel.user.exerciseFrequency = .threeToFive
                    }
                    
                    FrequencyOptionButton(
                        title: "几乎每天",
                        isSelected: viewModel.user.exerciseFrequency == .daily
                    ) {
                        viewModel.user.exerciseFrequency = .daily
                    }
                }
            }
            
        default:
            EmptyView()
        }
    }
    
    // 底部按钮区域
    private func bottomButtons() -> some View {
        VStack {
            Button(action: {
                if currentStep < totalSteps - 1 {
                    currentStep += 1
                } else {
                    // 完成按钮操作
                    finishAction()
                }
            }) {
                Text(currentStep < totalSteps - 1 ? "下一步" : "完成")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .disabled(currentStep == 0 && viewModel.nickname.isEmpty)
        }
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
                .edgesIgnoringSafeArea(.bottom)
        )
    }
    
    // 完成按钮操作
    private func finishAction() {
        // 显示完成动画
        showSuccessMessage = true
        
        // 保存用户信息
        viewModel.saveUserInfo {
            // 标记用户已登录
            appState.isLoggedIn = true
            
            // 2秒后跳转到主页
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSuccessMessage = false
                navigateToMainView = true
            }
        }
    }
}

// MARK: - 辅助视图组件

struct GenderOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(10)
        }
    }
}

struct ExerciseHabitButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(10)
        }
    }
}

struct FrequencyOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .foregroundColor(isSelected ? .white : .primary)
            .frame(height: 50)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

struct StepProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景条
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 6)
                    .cornerRadius(3)
                
                // 进度条
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: self.progress(in: geometry.size.width), height: 6)
                    .cornerRadius(3)
            }
        }
        .frame(height: 6)
    }
    
    private func progress(in width: CGFloat) -> CGFloat {
        let progress = min(CGFloat(currentStep + 1) / CGFloat(totalSteps), 1.0)
        return progress * width
    }
}

class UserInfoSetupViewModel: ObservableObject {
    @Published var user: User
    @Published var nickname: String
    
    init() {
        // Default initialization with the existing User model from AuthService
        if let currentUser = AuthService.shared.currentUser {
            self.user = currentUser
            self.nickname = currentUser.nickname ?? ""
        } else {
            // Fallback to a new User instance if somehow no current user exists
            self.user = User(phoneNumber: "")
            self.nickname = ""
        }
    }
    
    func saveUserInfo(completion: @escaping () -> Void) {
        // 更新用户昵称
        user.nickname = nickname
        
        // 标记个人资料已完成
        user.isProfileCompleted = true
        
        // 将用户数据保存到AuthService
        AuthService.shared.currentUser = user
        AuthService.shared.isLoggedIn = true
        AuthService.shared.isNewUser = false
        
        // 保存到本地存储
        AuthService.shared.saveUserToStorage()
        
        // 如果已经通过API登录，更新用户资料到服务器
        if let userId = user.apiUserId {
            // 准备更新请求
            let updateRequest = user.prepareProfileUpdateRequest()
            
            // 调用API更新用户资料
            APIService.shared.updateUserProfile(profile: updateRequest)
                .sink(
                    receiveCompletion: { completion in
                        // 处理可能的错误
                        if case let .failure(error) = completion {
                            print("更新用户资料失败: \(error.errorMessage)")
                        }
                    },
                    receiveValue: { _ in
                        print("用户资料已同步到服务器")
                        completion()
                    }
                )
                .store(in: &AuthService.shared.cancellables)
        }
    }
}

struct SuccessMessageView: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 70, height: 70)
                    .foregroundColor(.green)
                
                Text(message)
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            .padding(30)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 10)
        }
    }
}

#Preview {
    UserInfoSetupView()
        .environmentObject(AppState.shared)
} 