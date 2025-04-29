import SwiftUI

/// 美食图片视图，用于加载和显示美食图片
struct DessertImageView: View {
    // 美食数据
    let dessert: DessertItem
    
    // 图片类型
    let type: DessertItem.ImageType
    
    // 显示大小
    var size: CGFloat?
    
    // 图片加载状态
    @State private var image: UIImage?
    @State private var isLoading: Bool = true
    @State private var loadFailed: Bool = false
    
    var body: some View {
        ZStack {
            if let loadedImage = image {
                // 显示加载的图片
                Image(uiImage: loadedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .transition(.opacity)
            } else if isLoading {
                // 加载中显示骨架屏
                SkeletonView()
                    .opacity(0.7)
            } else if loadFailed {
                // 加载失败显示占位图标
                fallbackView
            }
        }
        // 仅当size有值时设置frame
        .modifier(OptionalFrameModifier(size: size))
        .onAppear {
            loadImage()
        }
    }
    
    /// 加载图片
    private func loadImage() {
        isLoading = true
        loadFailed = false
        
        dessert.loadImage(type: type) { loadedImage in
            // 在主线程更新UI
            DispatchQueue.main.async {
                withAnimation(.easeIn(duration: 0.2)) {
                    if let loadedImage = loadedImage {
                        self.image = loadedImage
                        self.loadFailed = false
                    } else {
                        self.loadFailed = true
                    }
                    self.isLoading = false
                }
            }
        }
    }
    
    /// 骨架屏视图
    private struct SkeletonView: View {
        @State private var isAnimating = false
        
        var body: some View {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.gray.opacity(0.2),
                            Color.gray.opacity(0.3),
                            Color.gray.opacity(0.2)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.5),
                            Color.white.opacity(0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: isAnimating ? 200 : -200)
                )
                .mask(RoundedRectangle(cornerRadius: 10))
                .onAppear {
                    withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }
        }
    }
    
    /// 失败时的占位视图
    private var fallbackView: some View {
        VStack {
            Image(systemName: dessert.category.icon)
                .resizable()
                .scaledToFit()
                .foregroundColor(.gray.opacity(0.7))
                .padding()
            
            Text(dessert.category.rawValue)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(minWidth: 50, minHeight: 50)
    }
}

/// 可选frame修饰器
struct OptionalFrameModifier: ViewModifier {
    let size: CGFloat?
    
    func body(content: Content) -> some View {
        if let size = size {
            content.frame(width: size, height: size)
        } else {
            content // 不设置frame，依赖外部约束
        }
    }
}

// 预览
struct DessertImageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 使用本地示例数据
            DessertImageView(
                dessert: DessertItem(
                    id: 1,
                    name: "示例甜点",
                    imageName: "MilkTea",
                    calories: "100",
                    category: .drink,
                    description: "示例描述",
                    isFeatured: false,
                    categoryId: 1,
                    categoryName: "饮品",
                    displayOrder: 1,
                    images: [
                        DessertImage(id: 1, url: "https://example.com/images/dessert.jpg", type: "regular", displayOrder: 1)
                    ]
                ),
                type: .regular,
                size: 150
            )
            
            // 不指定大小的示例（由外部约束控制）
            DessertImageView(
                dessert: DessertItem(
                    id: 2,
                    name: "示例甜点2",
                    imageName: "IceCream",
                    calories: "200",
                    category: .iceCream,
                    description: "示例描述",
                    isFeatured: false,
                    categoryId: 3,
                    categoryName: "冰品",
                    displayOrder: 1,
                    images: []
                ),
                type: .regular
            )
            .frame(width: 100, height: 100)
            .background(Color.yellow.opacity(0.3))
            
            // 占位图
            DessertImageView(
                dessert: DessertItem(
                    id: 3,
                    name: "示例甜点3",
                    imageName: "IceCream",
                    calories: "200",
                    category: .iceCream,
                    description: "示例描述",
                    isFeatured: false,
                    categoryId: 3,
                    categoryName: "冰品",
                    displayOrder: 1,
                    images: []
                ),
                type: .regular,
                size: 150
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
} 