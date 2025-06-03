import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -100
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.05), Color.white.opacity(0.6), Color.white.opacity(0.05)]),
                        startPoint: .top,
                        endPoint: .bottom)
                        .rotationEffect(.degrees(70))
                        .offset(x: phase)
                        .frame(width: geo.size.width*1.5)
                }
                .clipped()
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        self.modifier(ShimmerModifier())
    }
} 