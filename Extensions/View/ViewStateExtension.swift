//
//  ViewStateExtension.swift
//  DessertRun
//
//  Created by Claude on 2025/4/3.
//

import SwiftUI

// MARK: - 视图状态管理扩展

extension View {
    /// 应用加载状态，当加载中时显示进度指示器
    /// - Parameters:
    ///   - isLoading: 是否正在加载
    ///   - loadingView: 可选的自定义加载视图
    /// - Returns: 修改后的视图
    func loading<LoadingView: View>(
        isLoading: Binding<Bool>,
        @ViewBuilder loadingView: @escaping () -> LoadingView = { ProgressView() }
    ) -> some View {
        ZStack {
            self
                .disabled(isLoading.wrappedValue)
                .blur(radius: isLoading.wrappedValue ? 2 : 0)
            
            if isLoading.wrappedValue {
                ZStack {
                    Color.black.opacity(0.4)
                    loadingView()
                }
            }
        }
    }
    
    /// 应用空状态处理，当数据为空时显示替代视图
    /// - Parameters:
    ///   - data: 要检查的数据集合
    ///   - placeholder: 当数据为空时显示的视图
    /// - Returns: 修改后的视图
    func withEmptyState<T, EmptyContent: View>(
        for data: [T],
        @ViewBuilder placeholder: @escaping () -> EmptyContent
    ) -> some View {
        ZStack {
            if data.isEmpty {
                placeholder()
            } else {
                self
            }
        }
    }
    
    /// 应用错误状态，当发生错误时显示错误信息
    /// - Parameters:
    ///   - error: 要显示的错误（可选）
    ///   - retryAction: 重试操作的回调
    /// - Returns: 修改后的视图
    func withErrorHandling<ErrorContent: View>(
        error: Binding<Error?>,
        retryAction: @escaping () -> Void,
        @ViewBuilder errorContent: @escaping (Error) -> ErrorContent
    ) -> some View {
        ZStack {
            self
            
            if let currentError = error.wrappedValue {
                ZStack {
                    Color.black.opacity(0.4)
                    errorContent(currentError)
                        .transition(.opacity)
                }
                .onTapGesture {
                    error.wrappedValue = nil
                }
            }
        }
    }
} 