import SwiftUI

/// 用户信息设置页面 - 新用户注册后的信息收集
struct UserInfoSetupView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var viewModel = UserInfoSetupViewModel()
    @EnvironmentObject var appState: AppState
    @State private var currentStep: Int
    @State private var showSuccessMessage = false
    @State private var navigateToMainView = false
    
    // 是否为模态方式显示（用于单独编辑某个页面）
    var isModal: Bool
    var onDismiss: (() -> Void)?
    
    private let totalSteps = 3 // 修改总步骤数：1.昵称和性别 2.身高和体重 3.运动习惯
    
    // 初始化方法
    init(initialStep: Int = 0, isModal: Bool = false, onDismiss: (() -> Void)? = nil) {
        _currentStep = State(initialValue: initialStep)
        self.isModal = isModal
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if navigateToMainView {
                    MainTabView()
                        .environmentObject(appState)
                } else {
                    VStack(spacing: 0) {
                        // 进度条 - 非模态模式才显示
                        if !isModal {
                            StepProgressBar(currentStep: currentStep, totalSteps: totalSteps)
                                .padding(.top, 20)
                                .padding(.horizontal, 30)
                        }
                        
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
                    .onAppear {
                        // 如果是模态模式，从API获取用户信息
                        if isModal {
                            loadCurrentUserInfo()
                        }
                    }
                    
                    // 显示完成动画
                    if showSuccessMessage {
                        SuccessMessageView(message: "个人信息已设置完成！")
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: isModal ? nil : backButton)
        }
    }
    
    // 加载当前用户信息
    private func loadCurrentUserInfo() {
        if let user = authService.currentUser {
            // 从用户模型更新视图模型
            viewModel.user.nickname = user.nickname
            viewModel.user.gender = user.gender
            viewModel.user.height = user.height
            viewModel.user.weight = user.weight
            viewModel.user.hasExerciseHabit = user.hasExerciseHabit
            viewModel.nickname = user.nickname ?? ""
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
                            get: { Int(viewModel.user.bodyData?.height ?? 170) },
                            set: { viewModel.user.bodyData?.height = Double($0) }
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
                            get: { Int(viewModel.user.bodyData?.weight ?? 60) },
                            set: { viewModel.user.bodyData?.weight = Double($0) }
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
                            viewModel.user.exerciseHabit?.hasExerciseHabit = true
                            // 强制视图刷新
                            viewModel.objectWillChange.send()
                        }
                    }) {
                        Text("是")
                            .font(.headline)
                            .foregroundColor(viewModel.user.exerciseHabit?.hasExerciseHabit == true ? .white : .primary)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(viewModel.user.exerciseHabit?.hasExerciseHabit == true ? Color.blue : Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle()) // 添加这一行解决按钮不响应问题
                    .id("yesButton-\(viewModel.user.exerciseHabit?.hasExerciseHabit == true)") // 添加动态ID，强制视图刷新
                    
                    Button(action: {
                        print("否按钮被点击") // 添加调试日志
                        dismissKeyboard() // 首先隐藏键盘
                        withAnimation {
                            viewModel.user.exerciseHabit?.hasExerciseHabit = false
                            // 强制视图刷新
                            viewModel.objectWillChange.send()
                        }
                    }) {
                        Text("否")
                            .font(.headline)
                            .foregroundColor(viewModel.user.exerciseHabit?.hasExerciseHabit == false ? .white : .primary)
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                            .background(viewModel.user.exerciseHabit?.hasExerciseHabit == false ? Color.blue : Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle()) // 添加这一行解决按钮不响应问题
                    .id("noButton-\(viewModel.user.exerciseHabit?.hasExerciseHabit == false)") // 添加动态ID，强制视图刷新
                }
            }
            
        default:
            EmptyView()
        }
    }
    
    // 底部按钮区域
    @ViewBuilder
    private func bottomButtons() -> some View {
        VStack(spacing: 15) {
            // 下一步按钮
            if isModal {
                // 模态模式下，只显示保存按钮
                Button(action: {
                    saveCurrentStepInfo()
                }) {
                    Text("保存")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "FE2D55"))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                
                if let onDismiss = onDismiss {
                    Button(action: {
                        onDismiss()
                    }) {
                        Text("取消")
                            .font(.headline)
                            .foregroundColor(Color(hex: "FE2D55"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hex: "FE2D55"), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                }
            } else {
                // 非模态模式下，显示下一步或完成按钮
                Button(action: {
                    if currentStep < totalSteps - 1 {
                        // 保存当前步骤数据并转到下一步
                        saveCurrentStepInfo()
                        currentStep += 1
                    } else {
                        // 最后一步，保存所有数据并完成设置
                        saveAllUserInfo()
                    }
                }) {
                    Text(currentStep < totalSteps - 1 ? "下一步" : "完成")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "FE2D55"))
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                
                // 跳过按钮（仅在非模态模式且非最后一步时显示）
                if currentStep < totalSteps - 1 {
                    Button(action: {
                        // 标记资料完整
                        saveAllUserInfo()
                    }) {
                        Text("跳过，稍后设置")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "FE2D55"))
                    }
                    .padding(.bottom, 10)
                }
            }
        }
        .padding(.vertical, 20)
        .background(
            Rectangle()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -5)
        )
    }
    
    // 保存当前步骤信息
    private func saveCurrentStepInfo() {
        // 根据当前步骤调用对应的API
        switch currentStep {
        case 0:
            // 第一步：昵称和性别 - 调用基本信息API
            let basicInfo = UpdateBasicInfoRequest(
                nickname: viewModel.nickname.isEmpty ? nil : viewModel.nickname,
                avatar: nil,
                gender: viewModel.user.gender?.toApiValue,
                birthYear: viewModel.user.birthYear
            )
            
            APIService.shared.updateUserBasicInfo(info: basicInfo)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            print("更新基本信息失败: \(error.errorMessage)")
                        }
                        
                        // 如果是模态模式，更新完成后关闭页面
                        if isModal, let onDismiss = onDismiss {
                            onDismiss()
                        }
                    },
                    receiveValue: { response in
                        print("更新基本信息成功: \(response.nickname ?? "未设置昵称")")
                        
                        // 更新本地用户数据
                        if let user = authService.currentUser {
                            user.nickname = response.nickname
                            user.gender = response.gender.flatMap { User.Gender.fromApiString($0) }
                            user.birthYear = response.birthYear
                            
                            // 保存到本地存储
                            authService.saveUserToStorage()
                        }
                        
                        // 显示成功消息
                        if isModal {
                            showSuccessMessage = true
                            // 2秒后关闭成功消息并返回
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSuccessMessage = false
                                if let onDismiss = onDismiss {
                                    onDismiss()
                                }
                            }
                        }
                    }
                )
                .store(in: &authService.cancellables)
            
        case 1:
            // 第二步：身高和体重 - 调用身体数据API
            let bodyData = UpdateBodyDataRequest(
                height: viewModel.user.bodyData?.height,
                weight: viewModel.user.bodyData?.weight
            )
            
            APIService.shared.updateUserBodyData(bodyData: bodyData)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            print("更新身体数据失败: \(error.errorMessage)")
                        }
                        
                        // 如果是模态模式，更新完成后关闭页面
                        if isModal, let onDismiss = onDismiss {
                            onDismiss()
                        }
                    },
                    receiveValue: { response in
                        print("更新身体数据成功: 身高=\(response.height ?? 0), 体重=\(response.weight ?? 0)")
                        
                        // 更新本地用户数据
                        if let user = authService.currentUser {
                            // 如果没有身体数据对象，创建一个
                            if user.bodyData == nil {
                                user.bodyData = BodyData()
                            }
                            
                            // 更新身体数据
                            user.bodyData?.height = response.height
                            user.bodyData?.weight = response.weight
                            
                            // 保存到本地存储
                            authService.saveUserToStorage()
                        }
                        
                        // 显示成功消息
                        if isModal {
                            showSuccessMessage = true
                            // 2秒后关闭成功消息并返回
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSuccessMessage = false
                                if let onDismiss = onDismiss {
                                    onDismiss()
                                }
                            }
                        }
                    }
                )
                .store(in: &authService.cancellables)
            
        case 2:
            // 第三步：运动习惯 - 调用运动习惯API
            let exerciseHabit = UpdateExerciseHabitRequest(
                hasExerciseHabit: viewModel.user.exerciseHabit?.hasExerciseHabit,
                exerciseFrequency: nil, // 这里暂时没有收集这些数据
                exerciseDuration: nil
            )
            
            APIService.shared.updateUserExerciseHabit(exerciseHabit: exerciseHabit)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case let .failure(error) = completion {
                            print("更新运动习惯失败: \(error.errorMessage)")
                        }
                        
                        // 如果是模态模式，更新完成后关闭页面
                        if isModal, let onDismiss = onDismiss {
                            onDismiss()
                        }
                    },
                    receiveValue: { response in
                        print("更新运动习惯成功: 是否有运动习惯=\(response.hasExerciseHabit ?? false)")
                        
                        // 更新本地用户数据
                        if let user = authService.currentUser {
                            // 如果没有运动习惯对象，创建一个
                            if user.exerciseHabit == nil {
                                user.exerciseHabit = ExerciseHabit()
                            }
                            
                            // 更新运动习惯
                            user.exerciseHabit?.hasExerciseHabit = response.hasExerciseHabit
                            user.exerciseHabit?.exerciseFrequency = response.exerciseFrequency
                            user.exerciseHabit?.exerciseDuration = response.exerciseDuration
                            
                            // 保存到本地存储
                            authService.saveUserToStorage()
                        }
                        
                        // 显示成功消息
                        if isModal {
                            showSuccessMessage = true
                            // 2秒后关闭成功消息并返回
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showSuccessMessage = false
                                if let onDismiss = onDismiss {
                                    onDismiss()
                                }
                            }
                        }
                    }
                )
                .store(in: &authService.cancellables)
            
        default:
            return
        }
    }
    
    // 保存所有用户信息
    private func saveAllUserInfo() {
        // 更新本地用户模型
        if let user = authService.currentUser {
            // 更新用户信息
            user.nickname = viewModel.nickname.isEmpty ? nil : viewModel.nickname
            user.gender = viewModel.user.gender
            
            // 确保身体数据对象存在
            if user.bodyData == nil {
                user.bodyData = BodyData()
            }
            user.bodyData?.height = viewModel.user.bodyData?.height
            user.bodyData?.weight = viewModel.user.bodyData?.weight
            
            // 确保运动习惯对象存在
            if user.exerciseHabit == nil {
                user.exerciseHabit = ExerciseHabit()
            }
            user.exerciseHabit?.hasExerciseHabit = viewModel.user.exerciseHabit?.hasExerciseHabit
            
            user.isProfileCompleted = true
            
            // 保存到本地存储
            authService.saveUserToStorage()
        }
        
        // 分步骤调用API更新所有数据
        let group = DispatchGroup()
        var hasError = false
        
        // 1. 更新基本信息
        group.enter()
        let basicInfo = UpdateBasicInfoRequest(
            nickname: viewModel.nickname.isEmpty ? nil : viewModel.nickname,
            avatar: nil,
            gender: viewModel.user.gender?.toApiValue,
            birthYear: viewModel.user.birthYear
        )
        
        APIService.shared.updateUserBasicInfo(info: basicInfo)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("更新基本信息失败: \(error.errorMessage)")
                        hasError = true
                    }
                    group.leave()
                },
                receiveValue: { _ in
                    print("更新基本信息成功")
                }
            )
            .store(in: &authService.cancellables)
        
        // 2. 更新身体数据
        group.enter()
        let bodyData = UpdateBodyDataRequest(
            height: viewModel.user.bodyData?.height,
            weight: viewModel.user.bodyData?.weight
        )
        
        APIService.shared.updateUserBodyData(bodyData: bodyData)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("更新身体数据失败: \(error.errorMessage)")
                        hasError = true
                    }
                    group.leave()
                },
                receiveValue: { _ in
                    print("更新身体数据成功")
                }
            )
            .store(in: &authService.cancellables)
        
        // 3. 更新运动习惯
        group.enter()
        let exerciseHabit = UpdateExerciseHabitRequest(
            hasExerciseHabit: viewModel.user.exerciseHabit?.hasExerciseHabit,
            exerciseFrequency: nil,
            exerciseDuration: nil
        )
        
        APIService.shared.updateUserExerciseHabit(exerciseHabit: exerciseHabit)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("更新运动习惯失败: \(error.errorMessage)")
                        hasError = true
                    }
                    group.leave()
                },
                receiveValue: { _ in
                    print("更新运动习惯成功")
                }
            )
            .store(in: &authService.cancellables)
        
        // 所有API调用完成后的处理
        group.notify(queue: .main) {
            if hasError {
                print("部分信息更新失败")
            } else {
                print("所有信息更新成功")
            }
            
            // 显示成功消息，然后导航到主页
            showSuccessMessage = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSuccessMessage = false
                // 如果是模态模式，关闭页面；否则导航到主页
                if isModal, let onDismiss = onDismiss {
                    onDismiss()
                } else {
                    navigateToMainView = true
                }
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
            
            // 确保身体数据和运动习惯对象存在
            if self.user.bodyData == nil {
                self.user.bodyData = BodyData(height: 170.0, weight: 60.0)
            } else if self.user.bodyData?.height == nil {
                self.user.bodyData?.height = 170.0
            }
            
            if self.user.bodyData?.weight == nil {
                self.user.bodyData?.weight = 60.0
            }
            
            if self.user.exerciseHabit == nil {
                self.user.exerciseHabit = ExerciseHabit(hasExerciseHabit: false)
            }
        } else {
            // Fallback to a new User instance if somehow no current user exists
            self.user = User(phoneNumber: "")
            self.nickname = ""
            
            // 创建默认的身体数据和运动习惯
            self.user.bodyData = BodyData(height: 170.0, weight: 60.0)
            self.user.exerciseHabit = ExerciseHabit(hasExerciseHabit: false)
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
        
        // 如果已经通过API登录，分别更新各部分用户资料到服务器
        if user.apiUserId != nil {
            let group = DispatchGroup()
            var hasError = false
            
            // 1. 更新基本信息
            group.enter()
            let basicInfoRequest = user.prepareBasicInfoUpdateRequest()
            
            APIService.shared.updateUserBasicInfo(info: basicInfoRequest)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { result in
                        if case let .failure(error) = result {
                            print("更新基本信息失败: \(error.errorMessage)")
                            hasError = true
                        }
                        group.leave()
                    },
                    receiveValue: { _ in
                        print("基本信息更新成功")
                    }
                )
                .store(in: &AuthService.shared.cancellables)
            
            // 2. 更新身体数据
            group.enter()
            let bodyDataRequest = user.prepareBodyDataUpdateRequest()
            
            APIService.shared.updateUserBodyData(bodyData: bodyDataRequest)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { result in
                        if case let .failure(error) = result {
                            print("更新身体数据失败: \(error.errorMessage)")
                            hasError = true
                        }
                        group.leave()
                    },
                    receiveValue: { _ in
                        print("身体数据更新成功")
                    }
                )
                .store(in: &AuthService.shared.cancellables)
            
            // 3. 更新运动习惯
            group.enter()
            let exerciseHabitRequest = user.prepareExerciseHabitUpdateRequest()
            
            APIService.shared.updateUserExerciseHabit(exerciseHabit: exerciseHabitRequest)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { result in
                        if case let .failure(error) = result {
                            print("更新运动习惯失败: \(error.errorMessage)")
                            hasError = true
                        }
                        group.leave()
                    },
                    receiveValue: { _ in
                        print("运动习惯更新成功")
                    }
                )
                .store(in: &AuthService.shared.cancellables)
            
            // 所有API调用完成后的处理
            group.notify(queue: .main) {
                if hasError {
                    print("部分信息更新失败，但继续完成注册流程")
                } else {
                    print("所有信息已同步到服务器")
                }
                // 无论成功或失败都调用完成回调
                completion()
            }
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
    UserInfoSetupView(initialStep: 0, isModal: false)
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
