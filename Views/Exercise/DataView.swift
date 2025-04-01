//
//  DataView.swift
//  DessertRun
//
//  Created by Claude on 2025/4/1.
//

import SwiftUI

/// 运动数据页面
struct DataView: View {
    /// 运动会话
    @ObservedObject var workoutSession: WorkoutSession
    
    /// 屏幕尺寸
    let screenSize: CGSize
    
    var body: some View {
        VStack(spacing: 25) {
            // 基本信息卡片
            VStack(spacing: 15) {
                // 甜品名称和运动类型
                HStack {
                    VStack(alignment: .leading) {
                        Text(workoutSession.targetDessert.name)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text(workoutSession.exerciseType.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 运动状态
                    Text(workoutStateText)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(workoutStateColor.opacity(0.2))
                        .foregroundColor(workoutStateColor)
                        .cornerRadius(10)
                }
                
                Divider()
                
                // 详细数据网格
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 20) {
                    // 时间
                    DataCell(
                        icon: "clock.fill",
                        iconColor: .orange,
                        value: formattedTime,
                        label: "总时间"
                    )
                    
                    // 卡路里
                    DataCell(
                        icon: "flame.fill",
                        iconColor: .red,
                        value: "\(Int(workoutSession.burnedCalories))",
                        label: "卡路里"
                    )
                    
                    // 完成度
                    DataCell(
                        icon: "chart.pie.fill",
                        iconColor: .blue,
                        value: "\(Int(workoutSession.completionPercentage))%",
                        label: "完成度"
                    )
                    
                    // 距离/次数
                    DataCell(
                        icon: workoutSession.exerciseType.requiresGPS ? "map.fill" : "repeat",
                        iconColor: .green,
                        value: distanceOrCount,
                        label: distanceOrCountLabel
                    )
                    
                    // 平均速度
                    if workoutSession.exerciseType.requiresGPS {
                        DataCell(
                            icon: "speedometer",
                            iconColor: .purple,
                            value: String(format: "%.1f", workoutSession.averageSpeed * 3.6), // 转换为km/h
                            label: "平均速度(km/h)"
                        )
                        
                        // 当前速度
                        DataCell(
                            icon: "hare.fill",
                            iconColor: .pink,
                            value: String(format: "%.1f", workoutSession.currentSpeed * 3.6), // 转换为km/h
                            label: "当前速度(km/h)"
                        )
                    } else {
                        // 平均频率 (模拟数据)
                        DataCell(
                            icon: "waveform.path.ecg",
                            iconColor: .purple,
                            value: String(format: "%.1f", Double.random(in: 15...25)),
                            label: "频率(次/分)"
                        )
                        
                        // 消耗率
                        DataCell(
                            icon: "bolt.fill",
                            iconColor: .pink,
                            value: String(format: "%.1f", workoutSession.exerciseType.caloriesPerMinute),
                            label: "消耗率(卡/分)"
                        )
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5)
            
            // 运动趋势图
            VStack(alignment: .leading, spacing: 10) {
                Text("运动趋势")
                    .font(.headline)
                    .padding(.leading)
                
                // 简单的线形图（占位）
                ZStack {
                    // 背景
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                    
                    // 模拟图表
                    VStack {
                        Text("趋势图将在这里显示")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // 模拟线条
                        GeometryReader { geometry in
                            Path { path in
                                let width = geometry.size.width
                                let height = geometry.size.height
                                
                                // 开始点
                                path.move(to: CGPoint(x: 0, y: height * 0.5))
                                
                                // 绘制一条波浪线
                                for i in 0...100 {
                                    let x = width * CGFloat(i) / 100
                                    let y = height * (0.5 + 0.3 * sin(Double(i) / 10 + Double(workoutSession.totalElapsedSeconds) / 10))
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "FE2D55"), Color(hex: "FF9901")]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 3
                            )
                        }
                        .frame(height: 120)
                        .padding()
                    }
                }
                .frame(height: 180)
                .shadow(color: Color.black.opacity(0.05), radius: 5)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.top)
    }
    
    /// 格式化的时间
    private var formattedTime: String {
        return workoutSession.formattedTotalTime
    }
    
    /// 运动状态文本
    private var workoutStateText: String {
        switch workoutSession.state {
        case .notStarted:
            return "未开始"
        case .active:
            return "进行中"
        case .paused:
            return "已暂停"
        case .completed:
            return "已完成"
        case .abandoned:
            return "已放弃"
        }
    }
    
    /// 运动状态颜色
    private var workoutStateColor: Color {
        switch workoutSession.state {
        case .notStarted:
            return .gray
        case .active:
            return .green
        case .paused:
            return .orange
        case .completed:
            return .blue
        case .abandoned:
            return .red
        }
    }
    
    /// 距离或次数显示
    private var distanceOrCount: String {
        if workoutSession.exerciseType.requiresGPS {
            // 显示距离（公里）
            return String(format: "%.2f", workoutSession.distanceInMeters / 1000)
        } else {
            // 显示次数 - 这里需要实际实现
            return "0"
        }
    }
    
    /// 距离或次数标签
    private var distanceOrCountLabel: String {
        if workoutSession.exerciseType.requiresGPS {
            return "距离(km)"
        } else {
            return "完成次数"
        }
    }
}

/// 数据单元格
struct DataCell: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
} 