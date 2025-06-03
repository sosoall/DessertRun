import SwiftUI

/// 美食排行榜视图组件
struct DessertLeaderboardView: View {
    @StateObject private var viewModel = FoodCheckInViewModel.shared
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题栏
            HStack {
                Text("美食排行榜")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                // 刷新按钮
                Button(action: {
                    viewModel.loadTopDesserts(limit: 5, force: true)
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14))
                        .foregroundColor(viewModel.isLoadingTopDesserts ? .gray : Color(hex: "FE2D55"))
                }
                .disabled(viewModel.isLoadingTopDesserts)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // 排行榜内容
            if viewModel.isLoadingTopDesserts {
                // 加载中状态
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                        .padding()
                    Spacer()
                }
                .frame(height: 120)
            } else if viewModel.topDesserts.isEmpty {
                // 空状态
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                        Text("暂无排行榜数据")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding()
                    Spacer()
                }
                .frame(height: 120)
                .onAppear {
                    if viewModel.topDesserts.isEmpty && !viewModel.isLoadingTopDesserts {
                        viewModel.loadTopDesserts(limit: 5, force: true)
                    }
                }
            } else {
                // 有数据状态
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(Array(viewModel.topDesserts.enumerated()), id: \.element.id) { index, dessert in
                            VStack(spacing: 8) {
                                ZStack(alignment: .top) {
                                    VStack {
                                        Spacer()
                                        
                                        AsyncImage(url: URL(string: dessert.imageName)) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFit()
                                            default:
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.gray.opacity(0.1))
                                                    .overlay(
                                                        Image(systemName: "cup.and.saucer")
                                                            .font(.system(size: 24))
                                                            .foregroundColor(.gray)
                                                    )
                                            }
                                        }
                                        .frame(height: index == 0 ? 110 : 90)
                                        .cornerRadius(12)
                                    }
                                    .frame(height: index == 0 ? 120 : 100)
                                    
                                    // 第一名显示皇冠
                                    if index == 0 {
                                        Image("crown")
                                            .resizable()
                                            .renderingMode(.original)
                                            .scaledToFit()
                                            .frame(width: 32, height: 32)
                                            .offset(x: 10, y: -12)
                                    }
                                }
                                
                                // 排名
                                HStack(spacing: 4) {
                                    Text("#\(index + 1)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(index == 0 ? Color(hex: "FFD700") : Color(hex: "FE2D55"))
                                    
                                    Text("\(dessert.count)次")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                
                                // 美食名称
                                Text(dessert.name)
                                    .font(.system(size: 11))
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .frame(width: 80)
                            .id("leaderboard-item-\(dessert.id)")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .frame(height: 160)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onAppear {
            // 每次进入都强制刷新排行榜，确保账号切换后数据正确
            viewModel.loadTopDesserts(limit: 5, force: true)
        }
    }
}

#Preview {
    DessertLeaderboardView()
        .environmentObject(AppState.shared)
        .padding()
        .background(Color(hex: "fae8c8"))
} 