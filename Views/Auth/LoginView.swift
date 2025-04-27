import SwiftUI
import Combine

/// 扩展View添加点击背景隐藏键盘功能
extension View {
    func hideKeyboardWhenTappedAround() -> some View {
        return self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

/// 登录页面 - 提供账号密码登录及跳转到注册页面选项
struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @EnvironmentObject var appState: AppState
    @State private var isShowingUserInfoSetup = false
    @State private var isLoggingIn = false
    @State private var showLoginSuccess = false
    @State private var showingClearDataConfirm = false
    @State private var navigateToMainView = false
    @State private var showAlertLogin = false
    @State private var alertMessage = ""
    @State private var cancellables = Set<AnyCancellable>()
    
    // 定义输入焦点字段
    enum LoginField: Hashable {
        case phone, password, code
    }
    
    // 焦点状态
    @FocusState private var focusedField: LoginField?
    
    // 登录表单
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var isShowingRegister = false
    
    // 协议同意状态
    @State private var agreeToTerms = false
    @State private var showTermsAlert = false
    
    // 验证码登录相关状态
    @State private var loginMethod: LoginMethod = .verificationCode // 默认使用验证码登录
    @State private var verificationCode = ""
    @State private var isSendingCode = false
    @State private var codeTimeRemaining = 0
    @State private var codeWaitingTime = 60
    @State private var codeTimer: Timer? = nil
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showErrorMessage = false
    @State private var codeSent = false
    
    // 添加验证码输入步骤状态
    @State private var phoneVerifyStep: PhoneVerifyStep = .enterPhone
    
    enum PhoneVerifyStep {
        case enterPhone
        case enterCode
    }
    
    enum LoginMethod {
        case password
        case verificationCode
    }
    
    // 环境属性用于控制页面展示
    @Environment(\.dismiss) private var dismiss
    
    // 添加处理键盘消失的方法
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "FFA751"), Color(hex: "FFE259")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .hideKeyboardWhenTappedAround() // 点击背景隐藏键盘
            
            VStack(spacing: 30) {
                // 手机设备测试模式快速切换
                #if DEBUG
                HStack {
                    Spacer()
                    Menu {
                        ForEach(Config.API.ServerEnvironment.allCases, id: \.self) { env in
                            Button(action: {
                                Config.API.environment = env
                                // 更新环境后显示成功提示
                                withAnimation {
                                    alertMessage = "已切换到\(env.rawValue)：\(env.baseURL)"
                                    showAlertLogin = true
                                }
                            }) {
                                HStack {
                                    Text(env.rawValue)
                                    if Config.API.environment == env {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "network")
                                .font(.system(size: 14, weight: .bold))
                            Text("环境: \(Config.API.environment.rawValue)")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 1)
                        )
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 60) // 增加顶部间距，确保按钮在安全区域内可见
                #endif
                
                Spacer()
                
                // 应用标题
                Text("DessertRun")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
                
                // 登录方法选择
                HStack {
                    Text(loginMethod == .verificationCode ? "手机号登录或注册" : "密码登录")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // 密码登录链接
                    if loginMethod == .verificationCode {
                        Button("密码登录") {
                            loginMethod = .password
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                focusedField = .phone
                            }
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(12)
                    } else {
                        Button("验证码登录") {
                            loginMethod = .verificationCode
                            phoneVerifyStep = .enterPhone // 重置步骤
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                focusedField = .phone
                            }
                        }
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                if loginMethod == .password {
                    // 密码登录表单
                    VStack(spacing: 20) {
                        // 账号输入框
                        CustomTextField(
                            text: $phoneNumber,
                            placeholder: "手机号",
                            keyboardType: .phonePad,
                            returnKeyType: .next,
                            onSubmit: {
                                focusedField = .password
                            }
                        )
                        .frame(height: 50)
                        .cornerRadius(10)
                        .onChange(of: phoneNumber) { oldValue, newValue in
                            // 限制只能输入数字
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            if filtered != newValue {
                                phoneNumber = filtered
                            }
                        }
                        
                        // 密码输入框
                        SecureField("密码", text: $password)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .disableAutocorrection(true)
                            .submitLabel(.done)
                            .focused($focusedField, equals: .password)
                            .onSubmit {
                                dismissKeyboard() // 点击按钮时隐藏键盘
                                login()
                            }
                        
                        // 忘记密码链接
                        HStack {
                            Spacer()
                            
                            Button("忘记密码?") {
                                // 切换到验证码登录
                                loginMethod = .verificationCode
                                phoneVerifyStep = .enterPhone // 重置步骤
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    focusedField = .phone
                                }
                            }
                            .foregroundColor(.white)
                        }
                        .padding(.horizontal, 5)
                    }
                    .padding(.horizontal)
                } else {
                    // 验证码登录表单 - 分两步走
                    if phoneVerifyStep == .enterPhone {
                        // 第一步：输入手机号和获取验证码
                        VStack(spacing: 20) {
                            // 账号输入框
                            CustomTextField(
                                text: $phoneNumber,
                                placeholder: "手机号",
                                keyboardType: .phonePad,
                                returnKeyType: .done,
                                onSubmit: {
                                    if phoneNumber.count == 11 {
                                        // 如果已输入11位手机号，尝试发送验证码
                                        checkAgreementAndSendCode()
                                    }
                                }
                            )
                            .frame(height: 50)
                            .cornerRadius(10)
                            .onChange(of: phoneNumber) { oldValue, newValue in
                                // 限制只能输入数字
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered != newValue {
                                    phoneNumber = filtered
                                }
                                // 限制最多11位
                                if filtered.count > 11 {
                                    phoneNumber = String(filtered.prefix(11))
                                }
                            }
                            
                            // 获取验证码按钮
                            Button(action: {
                                checkAgreementAndSendCode()
                            }) {
                                if isSendingCode {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(Color.gray)
                                        .cornerRadius(10)
                                } else {
                                    Text("获取验证码")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                        .background(phoneNumber.count == 11 ? Color(hex: "FE2D55") : Color.gray)
                                        .cornerRadius(10)
                                }
                            }
                            .disabled(isSendingCode || phoneNumber.count != 11)
                            
                            // 协议同意区域 - 只在第一步显示
                            HStack(spacing: 8) {
                                // 增大勾选按钮的点击区域
                                Button(action: {
                                    agreeToTerms.toggle()
                                }) {
                                    Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                }
                                
                                Text("同意《用户协议》和《隐私政策》")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    // 为文本也添加点击事件
                                    .onTapGesture {
                                        agreeToTerms.toggle()
                                    }
                                
                                Spacer()
                            }
                            .padding(.top, 20)
                        }
                        .padding(.horizontal)
                    } else {
                        // 第二步：输入验证码
                        VStack(spacing: 20) {
                            // 返回按钮替代修改按钮
                            HStack {
                                Button(action: {
                                    phoneVerifyStep = .enterPhone
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 14))
                                        Text("返回")
                                            .font(.system(size: 14))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(16)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                            
                            // 显示已发送至的手机号
                            Text("验证码已发送至: \(phoneNumber)")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            
                            // 验证码输入框
                            VerificationCodeInputView(code: $verificationCode)
                                .frame(height: 60)
                                .padding(.vertical, 8)
                                .onAppear {
                                    // 自动激活验证码输入框
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        focusedField = .code
                                    }
                                }
                            
                            // 重新发送按钮
                            if codeTimeRemaining > 0 {
                                Text("\(codeTimeRemaining)秒后可重新发送")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                            } else {
                                Button("重新发送验证码") {
                                    sendVerificationCode()
                                }
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .disabled(isSendingCode)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // 登录按钮
                Button(action: {
                    dismissKeyboard()
                    
                    // 如果是验证码登录的输入验证码阶段，则执行登录
                    if loginMethod == .verificationCode && phoneVerifyStep == .enterCode {
                        login()
                    }
                    
                    // 如果是密码登录
                    if loginMethod == .password {
                        // 检查是否同意条款
                        if !agreeToTerms {
                            showTermsAlert = true
                        } else {
                            login()
                        }
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.white)
                            .frame(height: 56)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "FE2D55")))
                                .scaleEffect(1.2)
                        } else {
                            // 只在验证码输入页面显示登录按钮，手机号输入页面不显示这个按钮
                            if !(loginMethod == .verificationCode && phoneVerifyStep == .enterPhone) {
                                Text("登录")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color(hex: "FE2D55"))
                            } else {
                                // 手机号输入页面不显示任何文字，保持这个区域空白
                                EmptyView()
                            }
                        }
                    }
                }
                .disabled(isLoading || (loginMethod == .verificationCode && phoneVerifyStep == .enterPhone))
                .padding(.horizontal, 30)
                .padding(.top, 20)
                .opacity(loginMethod == .verificationCode && phoneVerifyStep == .enterPhone ? 0 : 1) // 手机号输入页不显示登录按钮
                
                // 错误信息显示
                if showErrorMessage {
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(Color.red.opacity(0.7))
                        .cornerRadius(5)
                }
                
                // 注册说明文本
                if loginMethod == .verificationCode {
                    Text("未注册手机号将自动完成注册")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 10)
                }
                
                // 协议同意区域 - 仅在密码登录时显示
                if loginMethod == .password {
                    HStack(spacing: 8) {
                        // 增大勾选按钮的点击区域
                        Button(action: {
                            agreeToTerms.toggle()
                        }) {
                            Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        
                        Text("同意《用户协议》和《隐私政策》")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            // 为文本也添加点击事件
                            .onTapGesture {
                                agreeToTerms.toggle()
                            }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                }
                
                // 开发测试工具按钮
                Button(action: {
                    showingClearDataConfirm = true
                }) {
                    Text("清除测试记录")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.vertical, 5)
                }
                .padding(.bottom, 30)
            }
            
            // 登录成功弹窗
            if showLoginSuccess {
                VStack {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "FE2D55"))
                            .padding(.top, 30)
                        
                        Text("登录成功")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text(authService.isNewUser ? "欢迎加入DessertRun!" : "欢迎回来!")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .padding(.bottom, 30)
                    }
                    .frame(width: 250)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    Spacer()
                }
                .background(Color.black.opacity(0.3).ignoresSafeArea())
                .transition(.opacity)
            }
        }
        .fullScreenCover(isPresented: $isShowingUserInfoSetup) {
            UserInfoSetupView()
        }
        .fullScreenCover(isPresented: $navigateToMainView) {
            // 显示主界面
            MainTabView()
        }
        .fullScreenCover(isPresented: $isShowingRegister) {
            RegisterView()
        }
        .alert("清除测试记录", isPresented: $showingClearDataConfirm) {
            Button("取消", role: .cancel) { }
            Button("确认清除", role: .destructive) {
                // 使用新方法彻底清除所有数据
                authService.resetAppToInitialState()
            }
        } message: {
            Text("这将清除所有用户数据，恢复应用到初始状态。")
        }
        .alert(isPresented: $showAlertLogin) {
            Alert(title: Text("登录成功"), message: Text(alertMessage), dismissButton: .default(Text("确定")) {
                // 如果是新用户，跳转到个人信息页
                if authService.isNewUser {
                    appState.isLoggedIn = true
                    isShowingUserInfoSetup = true
                    print("显示新用户注册页面")
                } else {
                    // 如果是老用户，直接进入首页
                    appState.isLoggedIn = true
                    appState.selectedTabIndex = 0
                    print("进入首页")
                }
            })
        }
        // 添加用户协议确认弹窗
        .alert("同意用户协议", isPresented: $showTermsAlert) {
            Button("不同意", role: .cancel) { }
            Button("同意并继续") {
                agreeToTerms = true
                // 直接发送验证码，不用再次点击获取验证码按钮
                sendVerificationCode()
            }
        } message: {
            Text("请同意《用户协议》和《隐私政策》继续操作")
        }
        .onAppear {
            // 如果已登录，自动跳转到首页
            if authService.isLoggedIn && authService.currentUser?.isProfileCompleted == true {
                appState.isLoggedIn = true
                appState.showLoginView = false
                appState.selectedTabIndex = 0
                print("已登录，自动跳转到首页")
            } else if !authService.isLoggedIn {
                // 确保登录状态一致
                appState.isLoggedIn = false
                appState.showLoginView = true
            }
        }
        .onChange(of: isShowingRegister) { oldValue, newValue in
            dismissKeyboard() // 切换到注册页面时隐藏键盘
        }
    }
    
    /// 处理登录业务逻辑
    func login() {
        // 先隐藏键盘
        dismissKeyboard()
        
        guard !phoneNumber.isEmpty else {
            errorMessage = "请输入手机号"
            showErrorMessage = true
            return
        }
        
        isLoading = true
        errorMessage = ""
        showErrorMessage = false
        
        if loginMethod == .verificationCode {
            guard !verificationCode.isEmpty else {
                errorMessage = "请输入验证码"
                showErrorMessage = true
                isLoading = false
                return
            }
            
            authService.loginWithVerificationCode(phoneNumber: phoneNumber, code: verificationCode) { success in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    if success {
                        successLogin()
                    } else {
                        errorMessage = authService.error ?? "登录失败，请检查验证码是否正确"
                        showErrorMessage = true
                    }
                }
            }
        } else { // 密码登录
            guard !password.isEmpty else {
                errorMessage = "请输入密码"
                showErrorMessage = true
                isLoading = false
                return
            }
            
            authService.loginWithPassword(phoneNumber: phoneNumber, password: password) { success in
                DispatchQueue.main.async {
                    isLoading = false
                    
                    if success {
                        successLogin()
                    } else {
                        errorMessage = authService.error ?? "登录失败，请检查账号密码是否正确"
                        showErrorMessage = true
                    }
                }
            }
        }
    }
    
    /// 登录成功后的处理
    func successLogin() {
        // 显示登录成功提示
        showLoginSuccess = true
        
        // 更新全局状态
        appState.updateLoginStatus()
        
        // 关闭登录页面标志
        appState.showLoginView = false
        
        // 检查是否为新用户，如果不是新用户则导航到主页
        if authService.isNewUser {
            // 新用户不自动导航，由DessertRunApp中的通知监听器处理
            showLoginSuccess = false
        } else {
            // 2秒后关闭登录成功提示并导航到主页
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showLoginSuccess = false
                navigateToMainView = true
            }
        }
    }
    
    /// 发送验证码
    func sendVerificationCode() {
        guard phoneNumber.count >= 11 else {
            errorMessage = "请输入有效的手机号码"
            showErrorMessage = true
            return
        }
        
        isLoading = true
        isSendingCode = true
        
        authService.sendVerificationCode(phoneNumber: phoneNumber) { success in
            DispatchQueue.main.async {
                isLoading = false
                isSendingCode = false
                
                if success {
                    // 切换到验证码输入界面
                    phoneVerifyStep = .enterCode
                    codeTimeRemaining = codeWaitingTime
                    startCodeTimer()
                } else {
                    errorMessage = authService.error ?? "验证码发送失败，请稍后再试"
                    showErrorMessage = true
                }
            }
        }
    }
    
    /// 开始验证码计时器
    func startCodeTimer() {
        codeTimer?.invalidate()
        codeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if codeTimeRemaining > 0 {
                codeTimeRemaining -= 1
            } else {
                timer.invalidate()
                codeTimer = nil
            }
        }
    }
    
    /// 检查协议并发送验证码的辅助方法
    func checkAgreementAndSendCode() {
        // 检查是否同意协议
        if !agreeToTerms {
            // 弹出用户协议同意确认框
            showTermsAlert = true
        } else {
            sendVerificationCode()
        }
    }
}

/// 注册视图 - 用户注册账号
struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    @State private var cancellables = Set<AnyCancellable>()
    
    // 定义输入焦点字段
    enum RegisterField: Hashable {
        case phone, code, nickname, password, confirmPassword
    }
    
    // 焦点状态
    @FocusState private var focusedField: RegisterField?
    
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var verificationCode = ""
    @State private var nickname = ""
    @State private var isRegistering = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSendingCode = false
    @State private var codeSent = false
    @State private var codeTimeRemaining = 0
    @State private var codeWaitingTime = 60
    @State private var codeTimer: Timer?
    @State private var agreeToTerms = false
    
    // 添加处理键盘消失的方法
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "FFA751"), Color(hex: "FFE259")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .hideKeyboardWhenTappedAround() // 点击背景隐藏键盘
            
            VStack(spacing: 30) {
                // 返回按钮
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .padding(.leading)
                    
                    Spacer()
                }
                .padding(.top)
                
                Text("创建账号")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // 注册表单
                VStack(spacing: 20) {
                    // 手机号输入框
                    CustomTextField(
                        text: $phoneNumber,
                        placeholder: "手机号",
                        keyboardType: .phonePad,
                        returnKeyType: .next,
                        onSubmit: {
                            focusedField = .code
                        }
                    )
                    .frame(height: 50)
                    .cornerRadius(10)
                    
                    // 验证码
                    HStack {
                        TextField("验证码", text: $verificationCode)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .disableAutocorrection(true)
                            .submitLabel(.next)
                            .focused($focusedField, equals: .code)
                            .onSubmit {
                                focusedField = .nickname
                            }
                        
                        Button(action: {
                            sendVerificationCode()
                        }) {
                            if codeTimeRemaining > 0 {
                                Text("\(codeTimeRemaining)s")
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .foregroundColor(.white)
                                    .background(Color.gray)
                                    .cornerRadius(8)
                            } else {
                                Text(codeSent ? "重新发送" : "发送验证码")
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .foregroundColor(.white)
                                    .background(Color(hex: "FE2D55"))
                                    .cornerRadius(8)
                            }
                        }
                        .disabled(isSendingCode || phoneNumber.count != 11 || codeTimeRemaining > 0)
                    }
                    
                    // 昵称
                    TextField("昵称", text: $nickname)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .disableAutocorrection(true)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .nickname)
                        .onSubmit {
                            focusedField = .password
                        }
                    
                    // 密码输入框
                    SecureField("设置密码", text: $password)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .disableAutocorrection(true)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .password)
                        .onSubmit {
                            focusedField = .confirmPassword
                        }
                    
                    // 确认密码输入框
                    SecureField("确认密码", text: $confirmPassword)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .disableAutocorrection(true)
                        .submitLabel(.done)
                        .focused($focusedField, equals: .confirmPassword)
                        .onSubmit {
                            dismissKeyboard() // 点击按钮时隐藏键盘
                            registerAction()
                        }
                }
                .padding(.horizontal)
                
                // 注册按钮
                Button(action: {
                    dismissKeyboard() // 点击按钮时隐藏键盘
                    registerAction()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.white)
                            .frame(height: 56)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        if isRegistering {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "FE2D55")))
                                .scaleEffect(1.2)
                        } else {
                            Text("注册")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "FE2D55"))
                        }
                    }
                }
                .disabled(isRegistering)
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                // 返回登录
                Button(action: {
                    dismiss()
                }) {
                    Text("已有账号？返回登录")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .underline()
                }
                .padding(.top, 10)
                
                Spacer()
                
                // 协议同意区域
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Button(action: {
                            agreeToTerms.toggle()
                        }) {
                            Image(systemName: agreeToTerms ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        
                        Text("同意《用户协议》和《隐私政策》")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("提示"), message: Text(alertMessage), dismissButton: .default(Text("确定")))
        }
    }
    
    /// 注册操作
    private func registerAction() {
        // 先隐藏键盘
        dismissKeyboard()
        
        // 验证输入
        guard !phoneNumber.isEmpty, !password.isEmpty, !confirmPassword.isEmpty, !verificationCode.isEmpty, !nickname.isEmpty else {
            alertMessage = "请填写所有字段"
            showAlert = true
            return
        }
        
        // 添加基本字符限制检查
        guard nickname.count >= 2 && nickname.count <= 20 else {
            alertMessage = "昵称长度应在2-20个字符之间"
            showAlert = true
            return
        }
        
        guard password.count >= 6 && password.count <= 20 else {
            alertMessage = "密码长度应在6-20个字符之间"
            showAlert = true
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = "两次输入的密码不一致"
            showAlert = true
            return
        }
        
        guard phoneNumber.count == 11 else {
            alertMessage = "请输入有效的手机号"
            showAlert = true
            return
        }
        
        guard agreeToTerms else {
            alertMessage = "请先同意用户协议和隐私政策"
            showAlert = true
            return
        }
        
        isRegistering = true
        
        APIService.shared.register(
            phone: phoneNumber,
            password: password,
            confirmPassword: confirmPassword,
            code: verificationCode,
            nickname: nickname
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                isRegistering = false
                alertMessage = "注册失败: \(error.errorMessage)"
                showAlert = true
            }
        }, receiveValue: { _ in
            isRegistering = false
            alertMessage = "注册成功，请返回登录"
            showAlert = true
            
            // 注册成功后延迟返回登录页
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
            }
        })
        .store(in: &cancellables)
    }
    
    /// 发送验证码
    private func sendVerificationCode() {
        guard phoneNumber.count == 11 else {
            alertMessage = "请输入有效的手机号"
            showAlert = true
            return
        }
        
        isSendingCode = true
        
        APIService.shared.getVerificationCode(phone: phoneNumber)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                isSendingCode = false
                switch completion {
                case .finished:
                    codeSent = true
                    alertMessage = "验证码已发送，请注意查收"
                    showAlert = true
                    startCodeTimer()
                case .failure(let error):
                    alertMessage = "发送验证码失败: \(error.errorMessage)"
                    showAlert = true
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    /// 开始验证码计时器
    private func startCodeTimer() {
        codeTimeRemaining = codeWaitingTime
        codeTimer?.invalidate()
        codeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if codeTimeRemaining > 0 {
                codeTimeRemaining -= 1
            } else {
                timer.invalidate()
                codeTimer = nil
            }
        }
    }
}

#Preview {
    LoginView()
} 