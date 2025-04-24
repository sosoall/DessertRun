import SwiftUI

/// 登录页面 - 提供一键登录及其他登录选项
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
    
    // 环境属性用于控制页面展示
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "FFA751"), Color(hex: "FFE259")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // 手机号显示区域
                VStack(spacing: 16) {
                    Text("150****9342")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("中国联通提供认证服务")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                
                Spacer()
                
                // 一键登录按钮
                Button(action: {
                    loginAction()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.white)
                            .frame(height: 56)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        if isLoggingIn {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "FE2D55")))
                                .scaleEffect(1.2)
                        } else {
                            Text("一键登录/注册")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: "FE2D55"))
                        }
                    }
                }
                .disabled(isLoggingIn)
                .padding(.horizontal, 30)
                
                // 其他登录选项
                HStack(spacing: 40) {
                    loginOptionButton(image: "applelogo", name: "Apple")
                    loginOptionButton(image: "ellipsis", name: "更多")
                }
                
                // 协议同意区域
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        
                        Text("同意《中国联通服务与隐私协议条款》")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 4) {
                        Text("和")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        
                        Text("《用户协议》")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                            .underline()
                        
                        Text("、")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        
                        Text("《隐私政策》")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                            .underline()
                        
                        Text("并使用本机号码登录")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 20)
                
                // 随便逛逛按钮（跳过登录）
                Button(action: {
                    navigateToMainView = true
                }) {
                    Text("随便逛逛")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                }
                .padding(.top, 10)
                
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
        .alert("清除测试记录", isPresented: $showingClearDataConfirm) {
            Button("取消", role: .cancel) { }
            Button("确认清除", role: .destructive) {
                authService.clearTestUserData()
            }
        } message: {
            Text("这将清除当前登录的测试用户数据，下次登录时将作为新用户。")
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
        .onAppear {
            // 如果已登录，自动跳转到首页
            if authService.isLoggedIn && authService.currentUser?.isProfileCompleted == true {
                appState.isLoggedIn = true
                appState.selectedTabIndex = 0
                print("已登录，自动跳转到首页")
            }
        }
    }
    
    /// 创建登录选项按钮
    private func loginOptionButton(image: String, name: String) -> some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color.white)
                .frame(width: 50, height: 50)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .overlay(
                    Image(systemName: image)
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "FE2D55"))
                )
            
            Text(name)
                .font(.system(size: 12))
                .foregroundColor(.white)
        }
    }
    
    /// 登录操作
    private func loginAction() {
        isLoggingIn = true
        
        // 模拟网络延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let loginResult = authService.oneClickLogin()
            
            // 不管是否为新用户，都直接登录成功
            // 如果是新用户，自动填充基本信息
            if authService.isNewUser {
                authService.autoFillUserProfile()
            }
            
            // 显示登录成功提示
            showLoginSuccess = true
            
            // 更新全局状态
            appState.updateLoginStatus()
            
            // 2秒后关闭登录成功提示并导航到主页
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showLoginSuccess = false
                isLoggingIn = false
                navigateToMainView = true
            }
        }
    }
    
    // 一键登录弹窗
    private var loginSuccessAlert: Alert {
        Alert(
            title: Text("登录成功"),
            message: Text(authService.isNewUser ? "欢迎加入甜品跑步！\n请完善您的个人信息以获得更好的体验。" : "欢迎回来!"),
            dismissButton: .default(Text("确定")) {
                withAnimation {
                    // 更新应用状态
                    appState.isLoggedIn = true
                    
                    if authService.isNewUser {
                        // 为新用户自动填充个人信息
                        authService.autoFillUserProfile()
                        // 登录后直接进入主页
                        appState.selectedTabIndex = 0
                    } else {
                        // 登录后直接进入主页
                        appState.selectedTabIndex = 0
                    }
                }
            }
        )
    }
}

#Preview {
    LoginView()
} 