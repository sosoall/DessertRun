import SwiftUI

/// 周视图加载时的骨架屏：7 个等高柱子 + 文字图例
struct WeeklyBarSkeleton: View {
    private let barCount = 7
    private let barWidth: CGFloat = 14
    private let barMaxHeight: CGFloat = 120
    var body: some View {
        VStack(spacing: 12) {
            // 柱状图骨架
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(0..<barCount, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: barWidth, height: barMaxHeight * 0.6)
                        .shimmering()
                }
            }
            // 横坐标
            HStack(spacing: 12) {
                let weekdaySymbols = ["一","二","三","四","五","六","日"]
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .frame(width: barWidth)
                }
            }
            // 图例
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(Color(hex: "FE2D55")).frame(width: 8, height: 8)
                    Text("已运动").font(.caption2).foregroundColor(.gray)
                }
                HStack(spacing: 4) {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                    Text("运动目标").font(.caption2).foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 24)
    }
}

#Preview {
    WeeklyBarSkeleton()
        .padding()
} 