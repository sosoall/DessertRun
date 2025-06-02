import SwiftUI

/// 全屏展开美食券视图（简化版）
struct ExpandedVoucherFullScreenView: View {
    let voucher: DessertVoucher
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.8).ignoresSafeArea()
            VStack(spacing: 16) {
                Spacer()
                DessertVoucherCardSimple(voucher: voucher, forceExpanded: true)
                    .environmentObject(appState)
                    .padding()
                Spacer()
            }
            Button(action: {
                NotificationCenter.default.post(name: NSNotification.Name("ExpandedCardDismissed"), object: voucher)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
}

#Preview {
    ExpandedVoucherFullScreenView(voucher: DessertVoucher.createSample())
        .environmentObject(AppState.shared)
} 