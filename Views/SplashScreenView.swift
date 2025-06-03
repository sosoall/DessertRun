import SwiftUI
import DotLottie

/// 应用启动页
struct SplashScreenView: View {
    @State private var fadeOut = false
    @StateObject private var animationVM = DotLottieAnimation(
        fileName: "BubbleTea",
        config: AnimationConfig(autoplay: true, loop: true)
    )

    var body: some View {
        ZStack {
            // 活力渐变背景（沿用挑战页样式）
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "FFF8E1"), Color(hex: "F5F5F5")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                // Slogan
                Text("\"该吃吃，该喝喝，\n热量别往肚里搁\"")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color(hex: "FE2D55"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // 可爱的动画
                animationVM.view()
                    .frame(width: 200, height: 200)
            }
            .opacity(fadeOut ? 0 : 1)
            .scaleEffect(fadeOut ? 0.92 : 1)
            .animation(.easeOut(duration: 0.6), value: fadeOut)
        }
        .onAppear {
            // 3.5 秒后淡出
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation {
                    fadeOut = true
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
} 