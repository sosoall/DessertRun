import SwiftUI

extension Font {
    /// 应用统一字体样式
    struct DessertRun {
        /// H1: PingFang SC Semibold 32 lineheight=40
        static var h1: Font {
            .system(size: 32, weight: .semibold)
        }
        
        /// H2: PingFang SC Semibold 20 lineheight=28
        static var h2: Font {
            .system(size: 20, weight: .semibold)
        }
        
        /// Title: PingFang SC Medium 16 lineheight=24
        static var title: Font {
            .system(size: 16, weight: .medium)
        }
        
        /// Body Bold: PingFang SC Medium 16 lineheight=24
        static var bodyBold: Font {
            .system(size: 16, weight: .medium)
        }
        
        /// Body: PingFang SC Regular 16 lineheight=24
        static var body: Font {
            .system(size: 16, weight: .regular)
        }
        
        /// Caption: PingFang SC Regular 14 lineheight=22
        static var caption: Font {
            .system(size: 14, weight: .regular)
        }
    }
}

// 文本样式修饰符，可以同时设置字体和行高
extension View {
    func textStyle(_ font: Font, fontSize: CGFloat, lineHeight: CGFloat) -> some View {
        self.font(font)
            .lineSpacing(lineHeight - fontSize)
            .padding(.vertical, (lineHeight - fontSize) / 2)
    }
    
    // 预设文本样式
    func h1Style() -> some View {
        self.font(Font.DessertRun.h1)
            .lineSpacing(8) // 40 - 32
    }
    
    func h2Style() -> some View {
        self.font(Font.DessertRun.h2)
            .lineSpacing(8) // 28 - 20
    }
    
    func titleStyle() -> some View {
        self.font(Font.DessertRun.title)
            .lineSpacing(8) // 24 - 16
    }
    
    func bodyBoldStyle() -> some View {
        self.font(Font.DessertRun.bodyBold)
            .lineSpacing(8) // 24 - 16
    }
    
    func bodyStyle() -> some View {
        self.font(Font.DessertRun.body)
            .lineSpacing(8) // 24 - 16
    }
    
    func captionStyle() -> some View {
        self.font(Font.DessertRun.caption)
            .lineSpacing(8) // 22 - 14
    }
} 