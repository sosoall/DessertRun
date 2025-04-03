//
//  ContentView.swift
//  DessertRun
//
//  Created by Claude on 2025/3/24.
//  注意：这个文件已被MainTabView替代，保留此文件仅用于兼容性和预览目的。
//  实际的应用入口点在MainTabView中。

import SwiftUI
import SwiftData

struct ContentView: View {
    // 创建动画状态对象
    @StateObject private var animationState = TransitionAnimationState()
    
    var body: some View {
        // 使用甜品网格视图作为主内容
        DessertGridView(animationState: animationState)
            .environmentObject(AppState.shared)
    }
}

#Preview {
    ContentView()
}
