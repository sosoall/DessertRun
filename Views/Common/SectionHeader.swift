import SwiftUI

struct SectionHeader<Content: View>: View {
    let title: String
    var trailing: (() -> Content)? = nil
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
            Spacer()
            if let trailing = trailing {
                trailing()
            }
        }
    }
}

extension SectionHeader where Content == EmptyView {
    init(title: String) {
        self.title = title
        self.trailing = nil
    }
}

#Preview {
    SectionHeader(title: "示例标题")
        .padding()
} 