import SwiftUI

/// 瀑布流布局组件，基于PreferenceKey实现
struct WaterfallGrid<Data, Content>: View where Data: RandomAccessCollection, Data.Element: Identifiable, Content: View {
    // 数据源
    private let data: Data
    
    // 内容构建器
    private let content: (Data.Element) -> Content
    
    // 列数
    private let columns: Int
    
    // 水平间距
    private let horizontalSpacing: CGFloat
    
    // 垂直间距
    private let verticalSpacing: CGFloat
    
    // 每列中所有元素的高度
    @State private var columnHeights: [CGFloat]
    
    // 元素的尺寸信息
    @State private var itemsSize: [Data.Element.ID: CGSize] = [:]
    
    /// 初始化
    /// - Parameters:
    ///   - data: 数据源
    ///   - columns: 列数
    ///   - horizontalSpacing: 水平间距
    ///   - verticalSpacing: 垂直间距
    ///   - content: 内容构建器
    init(data: Data,
         columns: Int,
         horizontalSpacing: CGFloat = 10,
         verticalSpacing: CGFloat = 10,
         @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.content = content
        self.columns = max(1, columns)
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self._columnHeights = State(initialValue: Array(repeating: 0, count: Int(max(1, columns))))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // 预先计算每个项目的大小
                ForEach(data) { item in
                    content(item)
                        .fixedSize(horizontal: false, vertical: true)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(key: ItemSizePreferenceKey<Data.Element.ID>.self, value: [item.id: geo.size])
                            }
                        )
                        .opacity(0)  // 不可见，只用于测量
                }
                
                // 生成实际布局
                ForEach(data) { item in
                    content(item)
                        .frame(width: itemWidth(in: geometry))
                        .position(position(for: item.id, in: geometry))
                }
            }
            .onPreferenceChange(ItemSizePreferenceKey<Data.Element.ID>.self) { sizes in
                // 更新项目尺寸
                self.itemsSize.merge(sizes) { current, new in new }
                // 重新计算列高度
                calculateColumnHeights(in: geometry)
            }
        }
        .frame(height: maxColumnHeight + verticalSpacing)
    }
    
    // 计算项目宽度
    private func itemWidth(in geometry: GeometryProxy) -> CGFloat {
        let totalSpacing = horizontalSpacing * CGFloat(columns - 1)
        return (geometry.size.width - totalSpacing) / CGFloat(columns)
    }
    
    // 计算每列的高度
    private func calculateColumnHeights(in geometry: GeometryProxy) {
        // 重置列高度
        columnHeights = Array(repeating: 0, count: Int(columns))
        
        // 为每个项目分配列位置
        for item in data {
            guard let size = itemsSize[item.id] else { continue }
            
            // 寻找最短的列
            guard let minColumnIndex = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset else { continue }
            
            // 将项目添加到最短的列
            columnHeights[minColumnIndex] += size.height + verticalSpacing
        }
    }
    
    // 计算项目位置
    private func position(for itemId: Data.Element.ID, in geometry: GeometryProxy) -> CGPoint {
        guard let size = itemsSize[itemId] else { return .zero }
        
        let width = itemWidth(in: geometry)
        
        // 找出已放置的项目
        var placedItems = Set<Data.Element.ID>()
        var columnHeightsCopy = Array(repeating: CGFloat(0), count: Int(columns))
        
        for item in data {
            // 如果找到当前项目，停止搜索
            if item.id == itemId { break }
            
            guard let itemSize = itemsSize[item.id] else { continue }
            
            // 找到最短的列
            guard let minColumnIndex = columnHeightsCopy.enumerated().min(by: { $0.element < $1.element })?.offset else { continue }
            
            // 添加到已放置项目集合
            placedItems.insert(item.id)
            
            // 更新这一列的高度
            columnHeightsCopy[Int(minColumnIndex)] += itemSize.height + verticalSpacing
        }
        
        // 找到当前项目应该放置的列
        guard let columnIndex = columnHeightsCopy.enumerated().min(by: { $0.element < $1.element })?.offset else { return .zero }
        
        // 计算位置
        let x = CGFloat(columnIndex) * (width + horizontalSpacing) + width / 2
        let y = CGFloat(columnHeightsCopy[Int(columnIndex)]) + size.height / 2
        
        return CGPoint(x: x, y: y)
    }
    
    // 获取最大列高度
    private var maxColumnHeight: CGFloat {
        columnHeights.max() ?? 0
    }
}

// 用于保存项目大小的PreferenceKey
struct ItemSizePreferenceKey<ID: Hashable>: PreferenceKey {
    typealias Value = [ID: CGSize]
    static var defaultValue: Value { return [:] }
    
    static func reduce(value: inout [ID: CGSize], nextValue: () -> [ID: CGSize]) {
        value.merge(nextValue()) { _, new in new }
    }
}

// 示例预览
struct WaterfallGrid_Previews: PreviewProvider {
    struct Item: Identifiable {
        let id = UUID()
        let color: Color
        let height: CGFloat
    }
    
    static var previews: some View {
        let items = [
            Item(color: .red, height: 100),
            Item(color: .blue, height: 150),
            Item(color: .green, height: 120),
            Item(color: .orange, height: 180),
            Item(color: .purple, height: 130)
        ]
        
        return WaterfallGrid(data: items, columns: 2) { item in
            Rectangle()
                .fill(item.color)
                .frame(height: item.height)
                .cornerRadius(10)
        }
        .padding()
    }
} 
