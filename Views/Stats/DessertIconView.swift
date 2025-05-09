import SwiftUI

/// 甜品图标视图组件
struct DessertIconView: View {
    let dessert: DessertItem
    let size: CGFloat
    let color: Color
    
    init(dessert: DessertItem, size: CGFloat = 20, color: Color = .white) {
        self.dessert = dessert
        self.size = size
        self.color = color
    }
    
    var body: some View {
        Group {
            switch dessert.category {
            case .cake:
                Image("cake", bundle: nil)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(color)
                
            case .dessert:
                Image(systemName: "cup.and.saucer.fill")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(color)
                
            case .iceCream:
                Image("icecream", bundle: nil)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(color)
                
            case .drink:
                Image("drink", bundle: nil)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(color)
                
            case .coffee:
                Image(systemName: "cup.and.saucer.fill")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(color)
                
            case .bread:
                Image(systemName: "circle.grid.2x1.fill")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(color)
                
            case .snack:
                Image(systemName: "fork.knife")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(color)
                
            case .chocolate:
                Image(systemName: "square.grid.2x2.fill")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(color)
            }
        }
        .frame(width: size, height: size)
        .aspectRatio(contentMode: .fit)
    }
}

struct DessertIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ForEach(FoodCategory.allCases, id: \.self) { category in
                HStack {
                    Text(category.rawValue)
                        .frame(width: 80, alignment: .leading)
                    
                    // 使用示例数据
                    DessertIconView(
                        dessert: DessertItem(
                            id: "1",
                            name: "示例甜点",
                            imageName: "example",
                            calories: "100",
                            category: category,
                            description: "示例描述",
                            isFeatured: false,
                            categoryId: "1",
                            categoryName: category.rawValue,
                            displayOrder: 1,
                            images: []
                        ),
                        size: 24,
                        color: .pink
                    )
                }
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 