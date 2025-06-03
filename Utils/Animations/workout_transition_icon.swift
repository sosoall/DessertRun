// 删除全部旧实现，替换为以下
//
//  workout_transition_icon.swift
//  DessertRun
//
//  使用 dotLottie-ios 以 SwiftUI 方式加载 json/.lottie 动画。
//  动画规则：先反向(1→0)播放一次，再正向(0→1)播放一次；两次完成后等待10秒继续循环。
//
import SwiftUI
import DotLottie

struct WorkoutIconView: View {
    private let animationName: String
    @StateObject private var animVM: DotLottieAnimation

    init(animationName: String) {
        self.animationName = animationName
        // 自动播放，循环，bounce模式(正向+反向)
        let vm = DotLottieAnimation(
            fileName: animationName,
            config: AnimationConfig(autoplay: true, loop: true, mode: .bounce)
        )
        _animVM = StateObject(wrappedValue: vm)
    }

    var body: some View {
        animVM.view()
    }

    // 已采用 bounce 自动往返，无需手动循环
}
