import SwiftUI
import DotLottie

/// LOGO 动画视图：载入 main bundle 中的 brand_icon.json / brand_icon.lottie，自动循环播放
struct BrandIconView: View {
    // DotLottie 的动画对象必须存成 @StateObject，否则 SwiftUI 每次刷新都会重新创建导致无法播放
    @StateObject private var vm = DotLottieAnimation(
        fileName: "brand_icon",                     // 资源无扩展名
        config: AnimationConfig(autoplay: true, loop: true, mode: .bounce)
    )

    var body: some View {
        vm.view()
    }
}