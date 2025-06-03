import SwiftUI

struct PlaceholderImageView: View {
    var size: CGFloat = 60
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(UIColor.systemGray4))
            .frame(width: size, height: size)
            .shimmering()
    }
}

#Preview {
    PlaceholderImageView()
} 