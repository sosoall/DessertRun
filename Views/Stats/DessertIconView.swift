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
                if let dessert = DessertData.getFoodsByCategory(category).first {
                    HStack {
                        Text(category.rawValue)
                            .frame(width: 80, alignment: .leading)
                        
                        DessertIconView(dessert: dessert, size: 24, color: .pink)
                    }
                }
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 