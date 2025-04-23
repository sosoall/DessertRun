import SwiftUI

/// 登录/注册页面
struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    // 电话号码（模拟）
    @State private var phoneNumber = "150****9342"
    @State private var isLoading = false
    @State private var agreementChecked = true
    
    // 控制是否应显示用户信息设置页面
    @State private var shouldShowUserSetup = false
    
    // 渐变背景颜色 - 使用绿色调，类似Keep
    private let backgroundGradient = LinearGradient(
        colors: [Color(hex: "32db8a"), Color(hex: "1acb7c")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // 按钮渐变颜色
    private let buttonGradient = LinearGradient(
        colors: [Color(hex: "32db8a"), Color(hex: "1acb7c")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    var body: some View {
        ZStack {
            // 背景
            backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部右侧其他登录方式按钮
                HStack {
                    Spacer()
                    Button(action: {
                        // 显示其他登录方式
                    }) {
                        Text("其他手机号登录")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
                
                Spacer().frame(height: 80)
                
                // 应用Logo
                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .padding(.bottom, 30)
                
                // 应用名称
                Text("甜品跑")
                    .font(.system(size:
                    40, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 50)
                
                // 手机号显示
                Text(phoneNumber)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
                
                // 提示文本
                Text("中国联通提供认证服务")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 50)
                
                // 一键登录按钮
                Button(action: {
                    handleQuickLogin()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white)
                            .frame(height: 56)
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "1acb7c")))
                                .scaleEffect(1.2)
                        } else {
                            Text("一键登录/注册")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color(hex: "1acb7c"))
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .disabled(isLoading || !agreementChecked)
                
                // 随便逛逛
                Button(action: {
                    // 跳过登录，直接进入应用
                    dismiss()
                }) {
                    Text("随便逛逛")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                Spacer()
                
                // 第三方登录
                VStack(spacing: 10) {
                    Text("其他登录方式")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 30) {
                        // 微信登录
                        LoginMethodButton(icon: "paperplane.fill", name: "微信", action: {
                            // 微信登录处理
                            print("用户点击了微信登录")
                        })
                        
                        // 苹果登录
                        LoginMethodButton(icon: "apple.logo", name: "Apple", action: {
                            // 苹果登录处理
                            print("用户点击了苹果登录")
                        })
                        
                        // 短信登录
                        LoginMethodButton(icon: "message.fill", name: "短信", action: {
                            // 短信验证码登录
                            print("用户点击了短信登录")
                        })
                        
                        // 更多登录方式
                        LoginMethodButton(icon: "ellipsis", name: "更多", action: {
                            // 显示更多登录方式
                            print("用户点击了更多登录方式")
                        })
                    }
                }
                .padding(.bottom, 30)
                
                // 协议勾选
                HStack(alignment: .top, spacing: 5) {
                    Button(action: {
                        agreementChecked.toggle()
                    }) {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 1)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Group {
                                    if agreementChecked {
                                        Circle()
                                            .fill(Color.white)
                                            .padding(4)
                                    }
                                }
                            )
                    }
                    
                    Group {
                        Text("同意")
                            .font(.system(size: 12))
                            .foregroundColor(.white) +
                        Text("《服务协议》")
                            .font(.system(size: 12))
                            .foregroundColor(.white) +
                        Text("和")
                            .font(.system(size: 12))
                            .foregroundColor(.white) +
                        Text("《隐私政策》")
                            .font(.system(size: 12))
                            .foregroundColor(.white) +
                        Text("并使用本机号码登录")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $shouldShowUserSetup) {
            // 登录成功后，如果是首次登录，显示用户信息设置页面
            UserInfoSetupView()
        }
    }
    
    // 处理一键登录
    private func handleQuickLogin() {
        guard agreementChecked, !isLoading else { return }
        
        // 开始加载
        isLoading = true
        
        // 尝试登录
        appState.quickLogin(phoneNumber: phoneNumber.replacingOccurrences(of: "*", with: "0")) { isFirstLogin in
            // 登录成功
            isLoading = false
            
            if isFirstLogin {
                // 首次登录，需要设置用户信息
                shouldShowUserSetup = true
            } else {
                // 非首次登录，直接进入应用
                dismiss()
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState.shared)
}

// 在文件末尾添加这个辅助视图
struct LoginMethodButton: View {
    let icon: String
    let name: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    )
                
                Text(name)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
} 