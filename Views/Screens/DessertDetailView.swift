//
//  DessertDetailView.swift
//  DessertRun
//
//  Created by Claude on 2023/3/24.
//

import SwiftUI

/// 甜品详情页面
struct DessertDetailView: View {
    /// 甜品数据
    let dessert: DessertItem
    
    /// 关闭回调
    var onClose: () -> Void = {}
    
    /// 环境中的应用状态
    @EnvironmentObject var appState: AppState
    
    /// 是否跳转到运动类型选择页面
    @State private var navigateToExerciseTypeSelection = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 顶部区域
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("甜品详情")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "heart")
                        .font(.title2)
                        .foregroundColor(.pink)
                }
            }
            .padding(.horizontal)
            
            // 甜品图片
            ZStack {
                Circle()
                    .fill(dessert.backgroundColor ?? Color.white)
                    .frame(width: 200, height: 200)
                
                Image(systemName: "cup.and.saucer.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: 100, height: 100)
            }
            .shadow(color: Color.black.opacity(0.1), radius: 5)
            
            // 甜品名称
            Text(dessert.name)
                .font(.title)
                .fontWeight(.bold)
            
            // 价格和卡路里
            HStack(spacing: 30) {
                VStack {
                    Text("价格")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(dessert.price)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack {
                    Text("卡路里")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(dessert.calories)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            
            // 描述
            VStack(alignment: .leading) {
                Text("关于这款甜品")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                Text("这是一款精心制作的\(dessert.name)，选用优质食材，口感细腻，甜度适中，香气四溢。是下午茶的绝佳选择，也适合作为餐后甜点。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // 底部按钮
            Button(action: {
                // 设置选中的甜品并导航到运动类型选择
                appState.selectedDessert = dessert
                navigateToExerciseTypeSelection = true
            }) {
                Text("开始运动")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "FE2D55"))
                    .cornerRadius(15)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(hex: "FAFAFA"))
        .cornerRadius(20)
        .edgesIgnoringSafeArea(.bottom)
        .navigationDestination(isPresented: $navigateToExerciseTypeSelection) {
            ExerciseTypeSelectionView()
        }
    }
}

#Preview {
    NavigationStack {
        DessertDetailView(dessert: DessertData.getSampleDesserts().first!)
            .environmentObject(AppState.shared)
    }
} 