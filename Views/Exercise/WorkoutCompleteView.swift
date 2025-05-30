import SwiftUI

/// 运动完成界面
/// - Parameters:
///   - record: 运动记录
///   - challengeProgress: 挑战进度信息（可选）
///   - isPresented: 是否展示
struct WorkoutCompleteView: View {
    // 传入参数：运动记录
    let record: WorkoutRecord
    
    // 传入参数：挑战进度信息（可选）
    let challengeProgress: ChallengeProgressInfo?
    
    // 环境对象
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var coordinator: WorkoutFlowCoordinator
    
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
    
    // 获取当前美食券 - 首选使用coordinator中的美食券，如果没有再从appState查找
    private var dessertVoucher: DessertVoucher? {
        // 首选使用coordinator中的美食券
        if let coordVoucher = coordinator.latestDessertVoucher {
            return coordVoucher
        }
        
        // 备选：从appState查找与运动记录ID匹配的美食券
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
                            
                            // 延迟触发美食券面板显示
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                coordinator.completeAndShowVoucherPanel()
                            }
                            
                            DRInfo("[WorkoutCompleteView] 运动完成页面关闭，准备显示美食券面板")
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
                    
                    // 根据是否有挑战进度信息显示不同内容
                    if let challengeProgress = challengeProgress {
                        if challengeProgress.isCompleted {
                            // 挑战已完成
                            Text("恭喜！美食券激活成功，挑战已完成！")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                        } else {
                            // 挑战未完成
                            Text("恭喜！美食券激活成功！已完成\(challengeProgress.completedCheckins)张任务卡！")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                        }
                    } else {
                        Text("恭喜获得美食券一张")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.bottom, 20)
                    }
                }
                
                // 美食券 - 设置为强制展开状态
                ZStack {
                    if showVoucher {
                        DessertVoucherCardSimple(voucher: dessertVoucher ?? DessertVoucher.empty, forceExpanded: true)
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

