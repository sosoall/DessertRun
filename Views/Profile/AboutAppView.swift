import SwiftUI

/// 关于DessertRun页面
struct AboutAppView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showingImageViewer = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // 顶部标题和icon
                    VStack(spacing: 16) {
                        // App图标 - 修复变形问题
                        Image("brand_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 30)
                        
                        Text("Version 1.0")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // 主要介绍文案
                    VStack(alignment: .leading, spacing: 16) {
                        Text("感谢使用该吃吃！")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "FE2D55"))
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("这个app是我在减肥的时候制作的，每次吃完小蛋糕我都有负罪感，我就想用运动去消抵消掉热量。")
                                .font(.body)
                                .lineSpacing(4)
                            
                            Text("但是市面上的app都是直接告诉我蛋糕是多少卡路里，但是不会告诉我需要跑步多久才能消耗掉。所以我做了这么一个app，可以进行美食和运动量的换算。")
                                .font(.body)
                                .lineSpacing(4)
                        }
                        .foregroundColor(.primary)
                    }
                    .padding()
                    .background(Color(hex: "FFF8E9"))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "FFDF99").opacity(0.3), lineWidth: 2)
                    )
                    
                    // 联系方式部分
                    VStack(spacing: 16) {
                        Text("联系我")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        
                        Text("欢迎关注我的小红书！有什么想聊的随时可以在小红书找到我！")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .foregroundColor(.primary)
                        
                        // 小红书二维码 - 增大尺寸并添加简单的点击查看功能
                        VStack(spacing: 12) {
                            Button(action: {
                                showingImageViewer = true
                            }) {
                                Image("redbook")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 250, height: 250) // 增大尺寸
                                    .cornerRadius(12)
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(Color(hex: "FE2D55"))
                                    .font(.caption)
                                Text("扫码关注小红书")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    }
                    
                    // 底部信息
                    VStack(spacing: 8) {
                        Text("开发者：胖雯儿和Cursor")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("© 2025 gaichichi")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                        .frame(height: 30)
                }
                .padding(.horizontal)
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color(hex: "FE2D55"))
                }
            }
            .fullScreenCover(isPresented: $showingImageViewer) {
                ImageViewerView(imageName: "redbook")
            }
        }
    }
}

/// 简化的全屏图片查看器（无保存功能）
struct ImageViewerView: View {
    @Environment(\.presentationMode) var presentationMode
    let imageName: String
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // 顶部工具栏 - 只保留关闭按钮
                HStack {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                    .font(.body)
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // 图片显示
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
                
                Spacer()
            }
        }
        .onTapGesture {
            // 点击空白区域也可以关闭
            presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    AboutAppView()
} 