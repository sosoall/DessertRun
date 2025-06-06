import SwiftUI
import ConfettiSwiftUI

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
    @State private var showVoucher = false
    @State private var showVoucherFullScreen = false
    @State private var voucherScale: CGFloat = 0.8
    @State private var voucherOpacity: Double = 0
    @State private var bottomTextOpacity: Double = 0
    @State private var isShared: Bool = false
    @State private var confettiCounter: Int = 0
    
    // 分享相关状态
    @StateObject private var shareManager = VoucherShareManager()
    
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
                        // 动态提示：消耗掉 X 个美食
                        Text("恭喜消耗掉\(String(format: "%.1f", record.equivalentDessertCount))个\(record.dessert.name)")
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
                
                // 底部分享按钮（模仿FoodCheckIn中的样式）
                if showVoucher && !showVoucherFullScreen {
                    Button(action: {
                        if let voucher = dessertVoucher {
                            shareManager.shareVoucher(voucher)
                        }
                    }) {
                        HStack {
                            if shareManager.isGenerating {
                                // 替换UIKit的ProgressView为纯SwiftUI动画
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                        .frame(width: 16, height: 16)
                                    
                                    Circle()
                                        .trim(from: 0, to: 0.8)
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 16, height: 16)
                                        .rotationEffect(.degrees(shareManager.isGenerating ? 360 : 0))
                                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: shareManager.isGenerating)
                                }
                                .scaleEffect(0.8)
                                
                                Text("生成中...")
                                    .font(.system(size: 14, weight: .medium))
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 16))
                                
                                Text("分享")
                                    .font(.system(size: 14, weight: .medium))
                            }
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
                    .disabled(shareManager.isGenerating)
                    .padding(.top, 12)
                }
                
                Spacer()
            }
            .padding()
            
            // 彩带动画 (ConfettiSwiftUI)
            Color.clear // 占位，用于挂载修饰符
                .confettiCannon(trigger: $confettiCounter, num: 45, colors: [.red, .yellow, .blue, .green, .pink], radius: 350)
            
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
            
            // 统一的分享图片预览界面
            if shareManager.showSharePreview, let voucher = dessertVoucher {
                UnifiedSharePreviewView(voucher: voucher, shareManager: shareManager)
                    .zIndex(1000) // 确保在最上层
            }
        }
        // 添加防止点击穿透的修饰器
        .contentShape(Rectangle())
        .onTapGesture {} // 空的点击手势来捕获所有点击事件
        // 分享错误提示
        .alert("分享失败", isPresented: Binding<Bool>(
            get: { shareManager.shareError != nil },
            set: { if !$0 { shareManager.shareError = nil } }
        )) {
            Button("确定", role: .cancel) {
                shareManager.shareError = nil
            }
        } message: {
            Text(shareManager.shareError ?? "未知错误")
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
                
                // 触发一次彩带
                confettiCounter += 1
            }
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    WorkoutCompleteView(
        record: WorkoutRecord(
            id: "preview-id",
            userId: "preview-user",
            exerciseType: APIExerciseType(
                id: "preview-exercise-id",
                type: "running",
                name: "跑步",
                description: "跑步运动",
                iconName: "figure.run",
                usesDistance: true,
                backgroundColor: "#FF6B6B",
                caloriesPerMinPerKg: 0.1,
                caloriesPerKmPerKg: 0.8,
                displayOrder: 1
            ),
            duration: 30.0,
            distance: 3000.0,
            caloriesBurned: 200.0,
            dessert: DessertItem(
                id: "preview-dessert",
                name: "巧克力蛋糕",
                imageName: "ChocolateCake",
                calories: "200",
                category: .cake,
                description: "美味蛋糕",
                backgroundColor: nil,
                isFeatured: false,
                relatedItems: [],
                categoryId: "2",
                categoryName: "蛋糕",
                displayOrder: 1,
                images: [DessertImage(id: "1", url: "ChocolateCake", type: "regular", displayOrder: 1)]
            ),
            date: Date(),
            workoutTag: "运动量super!",
            equivalentDessertCount: 1.0
        ),
        challengeProgress: nil,
        isPresented: $isPresented
    )
    .environmentObject(AppState.shared)
    .environmentObject(WorkoutFlowCoordinator.shared)
}

