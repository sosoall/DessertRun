import SwiftUI

/// 关于我们页面
struct AboutView: View {
    // 应用版本
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    
    // 应用构建版本
    private let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // 关于项目
    private let aboutItems: [(icon: String, title: String, action: () -> Void)] = [
        ("doc.text", "隐私政策", { print("用户点击了隐私政策") }),
        ("doc.plaintext", "用户协议", { print("用户点击了用户协议") }),
        ("star", "给我们评分", { 
            // 打开App Store评分页面
            if let url = URL(string: "https://apps.apple.com") {
                UIApplication.shared.open(url)
            }
        }),
        ("envelope", "联系我们", { print("用户点击了联系我们") }),
        ("square.and.arrow.up", "分享应用", { 
            // 分享应用 - 注意：这里的实现在实际运行时会由ShareLink控件替代
            print("用户点击了分享应用")
        })
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 应用Logo和名称
                AppLogoView(appVersion: appVersion, buildVersion: buildVersion)
                
                // 关于项目列表
                AboutItemsListView(items: aboutItems)
                
                // 应用介绍
                AppDescriptionView()
                
                // 版权信息
                Text("© 2025 DessertRun Team. All rights reserved.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
            }
        }
        .background(Color(UIColor.systemGray6))
    }
}

// MARK: - 子视图组件

/// 应用Logo视图
struct AppLogoView: View {
    let appVersion: String
    let buildVersion: String
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "figure.run.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "FE2D55"))
            
            Text("甜品跑")
                .font(.title)
                .fontWeight(.bold)
            
            Text("版本 \(appVersion) (\(buildVersion))")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
}

/// 关于项目列表视图
struct AboutItemsListView: View {
    let items: [(icon: String, title: String, action: () -> Void)]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<items.count, id: \.self) { index in
                AboutItemRow(item: items[index], isLast: index == items.count - 1)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

/// 单个关于项目行
struct AboutItemRow: View {
    let item: (icon: String, title: String, action: () -> Void)
    let isLast: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: item.action) {
                HStack {
                    // 图标
                    Image(systemName: item.icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "FE2D55"))
                        .frame(width: 30, height: 30)
                    
                    // 标题
                    Text(item.title)
                        .font(.body)
                        .foregroundColor(Color(hex: "333333"))
                    
                    Spacer()
                    
                    // 对于分享按钮使用特殊处理
                    if item.title == "分享应用" {
                        Button(action: {
                            // 使用UIActivityViewController来处理分享
                            let shareText = "甜品跑 - 零负罪感的运动App"
                            // 在实际应用中应该通过UIApplication.shared.windows.first等方式获取根控制器
                            print("分享应用: \(shareText)")
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    } else {
                        // 箭头
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white)
            }
            
            if !isLast {
                Divider()
                    .padding(.leading, 56)
            }
        }
    }
}

/// 应用介绍视图
struct AppDescriptionView: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("DessertRun是一款为运动初学者准备的运动App")
                .font(.body)
                .multilineTextAlignment(.center)
            
            Text("核心理念是“零负罪感的运动App”")
                .font(.body)
                .multilineTextAlignment(.center)
            
            Text("通过运动换取喜爱的甜品，让运动变得更有趣")
                .font(.body)
                .multilineTextAlignment(.center)
        }
        .padding()
        .foregroundColor(Color(hex: "666666"))
    }
}

#Preview {
    NavigationView {
        AboutView()
    }
} 