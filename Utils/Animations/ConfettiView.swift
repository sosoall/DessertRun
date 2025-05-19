import SwiftUI

/// 彩带动画视图，用于庆祝效果
struct ConfettiView: View {
    @State private var isAnimating = false
    
    // 彩带类型及颜色
    let confettiTypes = ["square", "circle", "triangle"]
    let colors: [Color] = [.red, .blue, .green, .yellow, .pink, .purple, .orange]
    
    // 彩带数量和持续时间
    var confettiCount: Int = 50
    var animationDuration: Double = 3.0
    
    var body: some View {
        ZStack {
            ForEach(0..<confettiCount, id: \.self) { index in
                ConfettiPiece(
                    color: colors[index % colors.count],
                    type: confettiTypes[index % confettiTypes.count],
                    startPosition: randomStartPosition(),
                    animationDuration: animationDuration + Double.random(in: -1.0...1.0)
                )
                .opacity(isAnimating ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
        }
    }
    
    // 生成随机起始位置
    private func randomStartPosition() -> CGPoint {
        let screenWidth = UIScreen.main.bounds.width
        return CGPoint(
            x: CGFloat.random(in: 0...screenWidth),
            y: -50 // 屏幕上方
        )
    }
}

/// 单个彩带片
struct ConfettiPiece: View {
    let color: Color
    let type: String
    let startPosition: CGPoint
    let animationDuration: Double
    
    @State private var position: CGPoint
    @State private var rotation = 0.0
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 1.0
    
    init(color: Color, type: String, startPosition: CGPoint, animationDuration: Double) {
        self.color = color
        self.type = type
        self.startPosition = startPosition
        self.animationDuration = animationDuration
        
        // 创建状态的初始值
        _position = State(initialValue: startPosition)
    }
    
    var body: some View {
        confettiShape
            .position(x: position.x, y: position.y)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                // 开始动画
                animateConfetti()
            }
    }
    
    // 彩带形状
    private var confettiShape: some View {
        Group {
            switch type {
            case "square":
                Rectangle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(color)
            case "circle":
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(color)
            case "triangle":
                Triangle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(color)
            default:
                Rectangle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(color)
            }
        }
    }
    
    // 彩带动画
    private func animateConfetti() {
        // 随机生成终点位置（屏幕下方）
        let screenHeight = UIScreen.main.bounds.height
        let endX = startPosition.x + CGFloat.random(in: -100...100)
        let endY = screenHeight + 50
        
        // 动画旋转
        withAnimation(
            Animation
                .linear(duration: animationDuration)
                .repeatForever(autoreverses: false)
        ) {
            rotation = Double.random(in: 0...1440) // 0-4圈
        }
        
        // 动画缩放
        withAnimation(
            Animation
                .easeOut(duration: 0.5)
        ) {
            scale = CGFloat.random(in: 0.4...1.0)
        }
        
        // 动画位置
        withAnimation(
            Animation
                .easeIn(duration: animationDuration)
        ) {
            position = CGPoint(x: endX, y: endY)
        }
        
        // 延迟消失
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration - 0.5) {
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 0
            }
        }
    }
}

/// 三角形形状
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct ConfettiView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
            ConfettiView()
        }
    }
} 