import SwiftUI

/// 引导页 - 应用首次启动的欢迎页面
struct OnboardingView: View {
    @State private var showLoginView = false
    @State private var startFadeIn = false
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "FFA751"), Color(hex: "FFE259")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 内容
            VStack {
                Spacer()
                
                // 应用图标和标题
                VStack(spacing: 20) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.white)
                        .opacity(startFadeIn ? 1 : 0)
                        .animation(.easeInOut(duration: 1).delay(0.2), value: startFadeIn)
                    
                    Text("DessertRun")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(startFadeIn ? 1 : 0)
                        .animation(.easeInOut(duration: 1).delay(0.4), value: startFadeIn)
                    
                    Text("零负罪感的运动App")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(startFadeIn ? 1 : 0)
                        .animation(.easeInOut(duration: 1).delay(0.6), value: startFadeIn)
                }
                
                Spacer()
                
                // 开始使用按钮
                Button(action: {
                    showLoginView = true
                }) {
                    Text("开始体验")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: "FE2D55"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .cornerRadius(28)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 50)
                }
                .opacity(startFadeIn ? 1 : 0)
                .animation(.easeInOut(duration: 1).delay(0.8), value: startFadeIn)
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            startFadeIn = true
        }
        .fullScreenCover(isPresented: $showLoginView) {
            LoginView()
        }
    }
}

// MARK: - 预览
#Preview {
    OnboardingView()
} 