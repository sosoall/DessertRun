//
//  ColorExtension.swift
//  DessertRun
//
//  Created by Claude on 2025/4/3.
//

import SwiftUI

// MARK: - 颜色扩展

extension Color {
    /// 从十六进制字符串创建颜色
    /// - Parameter hex: 十六进制颜色代码，如"FF0000"
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
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