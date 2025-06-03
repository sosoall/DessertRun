import SwiftUI
import DotLottie

struct SplashScreenView: View {
    @State private var fadeOut = false
    @StateObject private var animationVM = DotLottieAnimation(
        fileName: "BubbleTea",
        config: AnimationConfig(autoplay: true, loop: true)
    )
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                // 产品名称
                Text("DessertRun")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundColor(Color(hex: "FE2D55"))
                // slogan
                Text("该吃吃，该喝喝，热量别往肚里搁")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                // 动画
                animationVM.view()
                    .frame(width: 120, height: 120)
                Spacer()
            }
            .opacity(fadeOut ? 0 : 1)
            .scaleEffect(fadeOut ? 0.9 : 1)
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