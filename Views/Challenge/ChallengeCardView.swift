import SwiftUI

/// 挑战卡片视图
struct ChallengeCardView: View {
    // 挑战活动数据
    let challenge: ChallengeActivity
    
    // 是否已报名
    var isEnrolled: Bool = false
    
    // 卡片高度（瀑布流布局会使用）
    @State private var cardHeight: CGFloat = 250
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 挑战图片
            if let imageURL = challenge.imageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1.5, contentMode: .fit)
                            .cornerRadius(12)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 130)
                            .clipped()
                            .cornerRadius(12)
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1.5, contentMode: .fit)
                            .cornerRadius(12)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 130)
            } else {
                // 默认占位图
                Rectangle()
                    .fill(Color(hex: 0xF5F5F5))
                    .frame(height: 130)
                    .cornerRadius(12)
                    .overlay(
                        Image(systemName: "trophy")
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: 0xE0E0E0))
                    )
            }
            
            // 活动标签和状态栏
            HStack {
                // 活动类型标签
                Text(challenge.activityType == .free ? "免费" : "付费")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(challenge.activityType == .free ? Color(hex: 0x4CAF50) : Color(hex: 0xFF6B6B))
                    )
                
                Spacer()
                
                // 活动状态标签
                Text(challenge.statusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(getStatusColor(status: challenge.statusText))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(getStatusColor(status: challenge.statusText).opacity(0.1))
                    )
            }
            
            // 活动名称
            Text(challenge.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.black)
                .lineLimit(1)
            
            // 活动时间
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Text(challenge.formattedDuration)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            // 奖励信息
            HStack {
                Image(systemName: "gift")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Text(challenge.formattedReward)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            // 已报名标签（如果已报名）
            if isEnrolled {
                Text("已报名")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: 0xFE2D55))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: 0xFE2D55).opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(hex: 0xFE2D55), lineWidth: 1)
                    )
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: HeightPreferenceKey.self, value: geo.size.height)
            }
        )
        .onPreferenceChange(HeightPreferenceKey.self) { height in
            cardHeight = height
        }
    }
    
    // 根据状态文本获取颜色
    private func getStatusColor(status: String) -> Color {
        switch status {
        case "未上线":
            return Color.gray
        case "即将开始":
            return Color.blue
        case "进行中":
            return Color(hex: 0x4CAF50) // 绿色
        case "已结束":
            return Color.gray
        default:
            return Color.gray
        }
    }
}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    let challenge = ChallengeActivity(
        id: "1",
        name: "新人挑战：连续运动7天",
        description: "新人专属挑战，连续运动7天即可获得美食盲盒",
        requirement: "每日需完成至少一次运动打卡",
        activityType: .free,
        startDate: Date(),
        endDate: Date().addingTimeInterval(7*24*60*60),
        requiredCheckins: 7,
        requiredExerciseTypeId: nil,
        foodRestrictionType: "none",
        requiredFoodCategoryIds: nil,
        requiredFoodIds: nil,
        price: nil,
        vipOnly: false,
        rewardType: .dessertBox,
        rewardAmount: 1,
        rewardDescription: "随机美食盲盒一个",
        isActive: true,
        isForBeginner: true,
        createdAt: Date(),
        updatedAt: Date()
    )
    
    return ChallengeCardView(challenge: challenge, isEnrolled: true)
        .frame(width: 180)
        .padding()
        .background(Color(hex: 0xF5F5F5))
}