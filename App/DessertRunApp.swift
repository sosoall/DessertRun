//
//  DessertRunApp.swift
//  DessertRun
//
//  Created by Claude on 2025/3/24.
//

import SwiftUI

@main
struct DessertRunApp: App {
    // 应用全局状态
    @StateObject private var appState = AppState.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
        }
    }
}
