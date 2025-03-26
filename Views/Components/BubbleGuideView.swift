//
//  BubbleGuideView.swift
//  DessertRun
//
//  Created by Claude on 2023/3/24.
//

import SwiftUI

/// 布局参考线视图，帮助开发者可视化布局区域
struct BubbleGuideView: View {
    /// 布局配置
    let config: BubbleLayoutConfiguration
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 中心区域
                RoundedRectangle(cornerRadius: config.cornerRadius)
                    .stroke(Color.red, lineWidth: 1)
                    .frame(
                        width: config.xRadius * 2,
                        height: config.yRadius * 2
                    )
                
                // 过渡区域
                RoundedRectangle(
                    cornerRadius: config.cornerRadius + config.fringeWidth
                )
                .stroke(Color.blue, lineWidth: 1)
                .frame(
                    width: (config.xRadius + config.fringeWidth) * 2,
                    height: (config.yRadius + config.fringeWidth) * 2
                )
                
                // 坐标轴
                Path { path in
                    // 水平轴
                    path.move(to: CGPoint(x: -geometry.size.width/2, y: 0))
                    path.addLine(to: CGPoint(x: geometry.size.width/2, y: 0))
                    
                    // 垂直轴
                    path.move(to: CGPoint(x: 0, y: -geometry.size.height/2))
                    path.addLine(to: CGPoint(x: 0, y: geometry.size.height/2))
                }
                .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
            }
            .position(x: geometry.size.width/2, y: geometry.size.height/2)
        }
    }
} 