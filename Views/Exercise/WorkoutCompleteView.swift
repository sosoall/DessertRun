import SwiftUI

/// 打卡完成后展示美食券的页面
struct WorkoutCompleteView: View {
    // 传入参数：运动记录
    let record: WorkoutRecord
    
    // 环境对象
    @EnvironmentObject var appState: AppState
    
    // 状态变量
    @State private var showConfetti = true
    @State private var showVoucher = false
    @State private var showVoucherFullScreen = false
    @State private var voucherScale: CGFloat = 0.8
    @State private var voucherOpacity: Double = 0
    @State private var bottomTextOpacity: Double = 0
    @State private var isShared: Bool = false
    
    // 用于导航的状态
    @Binding var isPresented: Bool
    @Binding var showFoodCheckInView: Bool
    
    // 获取当前美食券
    private var dessertVoucher: DessertVoucher? {
        return appState.dessertVouchers.first(where: { $0.workoutRecordId == record.id })
    }
    
    var body: some View {
        ZStack {
            // 半透明背景以防止点击穿透
            Color.black.opacity(0.01)
                .edgesIgnoringSafeArea(.all)
            
            // 背景渐变 - 修改为半透明黑色背景
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // 标题和关闭按钮
                HStack {
                    Spacer()
                    
                    if !showVoucherFullScreen {
                        Button(action: {
                            // 关闭当前页面
                            isPresented = false
                            
                            // 修改为使用WorkoutFlowCoordinator控制导航
                            // 确保中间页完全关闭后再跳转到美食打卡页
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                // 设置TabBar索引，切换到美食打卡页
                                appState.selectedTabIndex = 1
                                
                                // 延迟加载美食打卡页数据，确保页面转场完成后再加载
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    WorkoutFlowCoordinator.shared.completeAndNavigateToFoodCheckIn()
                                    DRInfo("[WorkoutCompleteView] 中间页关闭后打开美食打卡页")
                                }
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white) // 修改颜色为白色以配合黑色背景
                                .padding()
                        }
                    }
                }
                
                Spacer()
                
                // 成功文字
                if !showVoucherFullScreen {
                    Text("打卡成功！")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white) // 修改为白色以适应深色背景
                        .padding(.bottom, 20)
                    
                    Text("恭喜获得美食券一张")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.9)) // 修改为白色以适应深色背景
                        .padding(.bottom, 40)
                }
                
                // 美食券 - 设置为强制展开状态
                ZStack {
                    if showVoucher {
                        DessertVoucherCardSimple(record: record, forceExpanded: true)
                            .environmentObject(appState)
                            .scaleEffect(voucherScale)
                            .opacity(voucherOpacity)
                            .onTapGesture {
                                // 点击美食券后全屏展示
                                withAnimation(.spring()) {
                                    showVoucherFullScreen = true
                                    voucherScale = 1.0
                                }
                            }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: showVoucherFullScreen ? 400 : 300) // 增加高度以适应展开状态
                
                Spacer()
                
                // 底部分享按钮（模仿FoodCheckIn中的样式）
                if showVoucher && !showVoucherFullScreen {
                    Button(action: {
                        // 分享逻辑
                        isShared = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                            
                            Text("分享可以获得5颗星星")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 28)
                        .frame(minWidth: 260)
                        .background(
                            LinearGradient(
                                gradient: Gradient(
                                    colors: [
                                        Color(hex: "#FE2D55"),
                                        Color(hex: "#FF896E")
                                    ]
                                ),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .padding(.bottom, 20)
                }
                
                // 底部文字
                if !showVoucherFullScreen {
                    Text("点击美食券查看详情")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8)) // 修改为半透明白色以适应深色背景
                        .opacity(bottomTextOpacity)
                        .padding(.bottom, 30)
                }
            }
            .padding()
            
            // 彩带动画
            if showConfetti {
                ConfettiView(confettiCount: 80, animationDuration: 4.0)
                    .allowsHitTesting(false)
            }
            
            // 全屏美食券的返回按钮
            if showVoucherFullScreen {
                VStack {
                    HStack {
                        Button(action: {
                            // 返回到普通视图
                            withAnimation(.spring()) {
                                showVoucherFullScreen = false
                                voucherScale = 0.8
                            }
                        }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding(.leading, 20)
                                .padding(.top, 20)
                        }
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        // 添加防止点击穿透的修饰器
        .contentShape(Rectangle())
        .onTapGesture {} // 空的点击手势来捕获所有点击事件
        .sheet(isPresented: $isShared) {
            // 分享视图
            VStack {
                Text("分享美食券")
                    .font(.system(size: 18, weight: .medium))
                    .padding()
                
                Text("分享\(record.dessert.name)的美食打卡记录")
                    .font(.system(size: 16))
                    .padding()
                
                Button("关闭") {
                    isShared = false
                }
                .padding()
            }
        }
        .onAppear {
            // 按顺序执行动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 0.8)) {
                    showVoucher = true
                    voucherOpacity = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeIn(duration: 0.5)) {
                        bottomTextOpacity = 1.0
                    }
                }
                
                // 5秒后自动停止彩带
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    showConfetti = false
                }
            }
        }
    }
}

