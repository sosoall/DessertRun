import SwiftUI

/// 展开美食券全屏视图
struct ExpandedVoucherFullScreen: View {
    let voucher: DessertVoucher
    @Binding var isPresented: Bool
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            // 顶部祝贺文案，悬浮于卡片之上
            if voucher.voucherStatus == .active {
                VStack {
                    Spacer().frame(height: 180)
                    Text("恭喜您已解锁美食券！")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .allowsHitTesting(false)
                .zIndex(10)
            }

            ExpandedCardView(voucher: voucher, isShowing: $isPresented, preloadedImageInfo: nil)
                .environmentObject(appState)
                .padding(.horizontal, 20)
                .zIndex(20)
        }
    }
}

#Preview {
    ExpandedVoucherFullScreen(
        voucher: DessertVoucher(
            id: "preview",
            userId: "user123",
            dessertId: "dessert123",
            dessertName: "巧克力蛋糕",
            equivalentDessertCount: 1.0,
            caloriesValue: 300.0,
            workoutRecordId: "workout123",
            status: "active",
            createdAt: Date(),
            updatedAt: Date(),
            expireAt: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            imageId: "image123",
            imageURL: "https://example.com/image.jpg",
            exerciseType: "run",
            exerciseName: "跑步",
            challengeEnrollmentId: "challenge123"
        ),
        isPresented: .constant(true)
    )
    .environmentObject(AppState.shared)
} 