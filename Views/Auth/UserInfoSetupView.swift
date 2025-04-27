import SwiftUI

/// 用户信息设置页面 - 新用户注册后的信息收集
struct UserInfoSetupView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var viewModel = UserInfoSetupViewModel()
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var showSuccessMessage = false
    @State private var navigateToMainView = false
    
    private let totalSteps = 3 // 修改总步骤数：1.昵称和性别 2.身高和体重 3.运动习惯
    
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
                        .onTapGesture {
                            dismissKeyboard()
                        }
                        
                        // 底部按钮区域
                        bottomButtons()
                    }
                    // 添加背景点击隐藏键盘
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissKeyboard()
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
            stepTitle("设置个人资料", subtitle: "请设置您的昵称和性别")
        case 1:
            stepTitle("身体数据", subtitle: "请输入您的身高和体重")
        case 2:
            stepTitle("运动习惯", subtitle: "您是否有运动习惯？")
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
            // 昵称和性别设置
            VStack(alignment: .leading, spacing: 20) {
                // 昵称设置
                VStack(alignment: .leading, spacing: 10) {
                    Text("昵称")
                        .font(.headline)
                    
                    TextField("请输入昵称", text: $viewModel.nickname)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                // 性别选择
                VStack(alignment: .leading, spacing: 10) {
                    Text("性别")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            print("男性按钮被点击") // 添加调试日志
                            dismissKeyboard() // 首先隐藏键盘
                            withAnimation {
                                viewModel.user.gender = .male
                                // 强制视图刷新
                                viewModel.objectWillChange.send()
                            }
                        }) {
                            Text("男")
                                .font(.headline)
                                .foregroundColor(viewModel.user.gender == .male ? .white : .primary)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(viewModel.user.gender == .male ? Color.blue : Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle()) // 添加这一行解决按钮不响应问题
                        .id("maleButton-\(viewModel.user.gender == .male)") // 添加动态ID，强制视图刷新
                        
                        Button(action: {
                            print("女性按钮被点击") // 添加调试日志
                            dismissKeyboard() // 首先隐藏键盘
                            withAnimation {
                                viewModel.user.gender = .female
                                // 强制视图刷新
                                viewModel.objectWillChange.send()
                            }
                        }) {
                            Text("女")
                                .font(.headline)
                                .foregroundColor(viewModel.user.gender == .female ? .white : .primary)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(viewModel.user.gender == .female ? Color.blue : Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        .buttonStyle(PlainButtonStyle()) // 添加这一行解决按钮不响应问题
                        .id("femaleButton-\(viewModel.user.gender == .female)") // 添加动态ID，强制视图刷新
                    }
                }
            }
            
        case 1:
            // 身高和体重设置
            VStack(alignment: .leading, spacing: 30) {
                // 身高设置
                VStack(alignment: .leading, spacing: 10) {
                    Text("身高（厘米）")
                        .font(.headline)
                    
                    HStack {
                        Picker("", selection: Binding(
                            get: { Int(viewModel.user.height ?? 170) },
                            set: { viewModel.user.height = Double($0) }
                        )) {
                            ForEach(100...220, id: \.self) { height in
                                Text("\(height)").tag(height)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 150)
                        .clipped()
                        
                        Text("厘米")
                            .padding(.leading, 10)
                    }
                }
                
                // 体重设置
                VStack(alignment: .leading, spacing: 10) {
                    Text("体重（公斤）")
                        .font(.headline)
                    
                    HStack {
                        Picker("", selection: Binding(
                            get: { Int(viewModel.user.weight ?? 60) },
                            set: { viewModel.user.weight = Double($0) }
                        )) {
                            ForEach(35...150, id: \.self) { weight in
                                Text("\(weight)").tag(weight)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 150)
                        .clipped()
                        
                        Text("公斤")
                            .padding(.leading, 10)
                    }
                }
            }
            
        case 2:
            // 是否有运动习惯
            VStack(alignment: .leading, spacing: 20) {
                Text("您是否有运动习惯？")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    Button(action: {
                        print("是按钮被点击") // 添加调试日志
                        dismissKeyboard() // 首先隐藏键盘
                        withAnimation {
                            viewModel.user.hasExerciseHabit = true
                            // 强制视图刷新
                            viewModel.objectWillChange.send()
                        }
                    }) {
                        Text("是")
                            .font(.headline)
                            .foregroundColor(viewModel.user.hasExerciseHabit == true ? .white : .primary)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(viewModel.user.hasExerciseHabit == true ? Color.blue : Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle()) // 添加这一行解决按钮不响应问题
                    .id("yesButton-\(viewModel.user.hasExerciseHabit == true)") // 添加动态ID，强制视图刷新
                    
                    Button(action: {
                        print("否按钮被点击") // 添加调试日志
                        dismissKeyboard() // 首先隐藏键盘
                        withAnimation {
                            viewModel.user.hasExerciseHabit = false
                            // 强制视图刷新
                            viewModel.objectWillChange.send()
                        }
                    }) {
                        Text("否")
                            .font(.headline)
                            .foregroundColor(viewModel.user.hasExerciseHabit == false ? .white : .primary)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(viewModel.user.hasExerciseHabit == false ? Color.blue : Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle()) // 添加这一行解决按钮不响应问题
                    .id("noButton-\(viewModel.user.hasExerciseHabit == false)") // 添加动态ID，强制视图刷新
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
                print("底部按钮被点击") // 添加调试日志
                dismissKeyboard() // 点击按钮时隐藏键盘
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
                    .background(isNextButtonDisabled() ? Color.gray : Color.blue)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle()) // 添加这一行解决按钮不响应问题
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .disabled(isNextButtonDisabled())
        }
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
                .edgesIgnoringSafeArea(.bottom)
        )
    }
    
    // 判断下一步按钮是否应该禁用
    private func isNextButtonDisabled() -> Bool {
        switch currentStep {
        case 0:
            // 第一步：昵称和性别必须填写
            return viewModel.nickname.isEmpty || viewModel.user.gender == nil
        case 1:
            // 第二步：身高和体重已经有默认值，所以不需要禁用
            return false
        case 2:
            // 第三步：运动习惯必须选择
            return viewModel.user.hasExerciseHabit == nil
        default:
            return false
        }
    }
    
    // 完成按钮操作
    private func finishAction() {
        // 显示完成动画
        showSuccessMessage = true
        
        // 保存用户信息
        viewModel.saveUserInfo {
            // 标记用户已登录
             // 设置首页为"运动"标签
            appState.selectedTabIndex = 0
            
            // 2秒后跳转到主页
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSuccessMessage = false
                navigateToMainView = true
            }
        }
    }
    
    // 添加隐藏键盘的方法
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
            
            // 确保身高体重初始值设置，即使未滚动拨盘
            if self.user.height == nil {
                self.user.height = 170.0
            }
            if self.user.weight == nil {
                self.user.weight = 60.0
            }
        } else {
            // Fallback to a new User instance if somehow no current user exists
            self.user = User(phoneNumber: "")
            self.nickname = ""
            // 设置默认身高体重
            self.user.height = 170.0
            self.user.weight = 60.0
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
        if user.apiUserId != nil {
            // 准备更新请求
            let updateRequest = user.prepareProfileUpdateRequest()
            
            // 调用API更新用户资料
            APIService.shared.updateUserProfile(profile: updateRequest)
                .receive(on: DispatchQueue.main) // 确保在主线程接收结果
                .sink(
                    receiveCompletion: { result in
                        // 处理可能的错误
                        if case let .failure(error) = result {
                            print("更新用户资料失败: \(error.errorMessage)")
                        }
                        // 无论成功或失败都调用完成回调
                        completion()
                    },
                    receiveValue: { _ in
                        print("用户资料已同步到服务器")
                    }
                )
                .store(in: &AuthService.shared.cancellables)
        } else {
            // 如果没有API用户ID，直接完成
            completion()
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

// MARK: - 扩展视图隐藏键盘功能
extension View {
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
} 
