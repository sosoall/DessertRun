//
//  ColorExtension.swift
//  DessertRun
//
//  Created by Claude on 2025/4/3.
//

import SwiftUI

// MARK: - 颜色扩展

extension Color {
    /// 根据16进制字符串创建颜色
    init(hex: String) {
        let scanner = Scanner(string: hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
    
    /// DessertRun 主题颜色
    struct DessertRun {
        /// 主要强调色 #FE2D55
        static let accent = Color(hex: "FE2D55")
        
        /// 金色强调色 #FFD12C
        static let accentGold = Color(hex: "FFD12C")
        
        /// 主要背景色 #FFFFFF
        static let background = Color.white
        
        /// 次要背景色 #FAF0DD
        static let backgroundSecondary = Color(hex: "FAF0DD")
        
        /// 主要文本色 #000000
        static let textPrimary = Color.black
        
        /// 次要文本色 #757575
        static let textSecondary = Color(hex: "757575")
        
        /// 边框颜色 #EEEEEE
        static let border = Color(hex: "EEEEEE")
        
        /// 阴影颜色 rgba(0,0,0,0.1)
        static let shadow = Color.black.opacity(0.1)
        
        /// 成功色 #4CD964
        static let success = Color(hex: "4CD964")
        
        /// 渐变 - 粉色到金色
        static let gradientPinkGold = LinearGradient(
            gradient: Gradient(colors: [Color(hex: "FF329A"), Color(hex: "FFD12C")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        /// 渐变 - 粉色到红色
        static let gradientPinkRed = LinearGradient(
            gradient: Gradient(colors: [Color(hex: "FF329A"), Color(hex: "FF2C3E")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// 注册颜色资源到应用Assets
extension Color {
    /// 根据名称获取颜色，兼容Assets颜色资源
    static func appColor(_ name: String) -> Color {
        if #available(iOS 15.0, *) {
            return Color(name)
        } else {
            // 对于iOS 15以下，提供直接映射
            switch name {
            case "AccentColor": return Color.DessertRun.accent
            case "TextPrimary": return Color.DessertRun.textPrimary
            case "TextSecondary": return Color.DessertRun.textSecondary
            case "BackgroundSecondary": return Color.DessertRun.backgroundSecondary
            default: return Color(name)
            }
        }
    }
}

extension Color {
    /// 将颜色转换为十六进制字符串
    var hexString: String {
        let components = UIColor(self).cgColor.components
        let r = components?[0] ?? 0
        let g = components?[1] ?? 0
        let b = components?[2] ?? 0

        return String(
            format: "%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
    }
    
    /// 估算颜色的亮度
    var brightness: CGFloat {
        // 将颜色转换为UIColor以便访问其组件
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // 使用相对亮度公式: 0.2126*R + 0.7152*G + 0.0722*B
        // 这是人眼对不同颜色感知亮度的标准权重
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue
    }
    
    /// 获取对比色（白色或黑色）
    var contrastingColor: Color {
        return brightness > 0.5 ? .black : .white
    }
} 