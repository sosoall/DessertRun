import SwiftUI

/// 新手引导 - 登录/注册之前的 5 页流程
struct OnboardingGuideView: View {
    /// 当前页索引（0~4）
    @State private var pageIndex: Int = 0
    /// 是否跳转到登录页
    @State private var showLoginView: Bool = false
    /// 全局应用状态
    @EnvironmentObject private var appState: AppState
    
    // MARK: - 布局常量
    /// 页面左右留白
    private let sidePadding: CGFloat = 24
    /// 全局标题字体大小
    private let titleFontSize: CGFloat = 30
    /// 统一标题占位高度，便于对齐
    private let titleHeight: CGFloat = 100
    /// bodyPrefix 高度（副标题占位）
    private let prefixHeight: CGFloat = 26
    /// 插图容器高度
    private let illustrationHeight: CGFloat = 320

    var body: some View {
        ZStack {
            // 统一的白色背景
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部区域：Logo + 进度点
                headerSection
                
                Spacer(minLength: 20)

                // 中部内容区域
                contentSection

                Spacer()

                // 底部按钮区域
                footerSection
            }
        }
        // 跳转到登录/注册页
        .fullScreenCover(isPresented: $showLoginView) {
            LoginView()
        }
    }

    // MARK: - 顶部区域
    @ViewBuilder
    private var headerSection: some View {
        if pageIndex == 2 {
            // 欢迎页不显示顶部
            Color.clear.frame(height: 80)
        } else {
            VStack(spacing: 8) {
                Image("brand_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140)

                // 圆点进度指示器
                dotIndicator
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
        }
    }

    // MARK: - 中部内容区域
    @ViewBuilder
    private var contentSection: some View {
        if pageIndex == 2 {
            // 欢迎页：完全居中
            VStack {
                Spacer()
                VStack(spacing: 16) {
                    Text("欢迎来到")
                        .font(.system(size: titleFontSize, weight: .bold))
                        .foregroundColor(Color(hex: "212121"))
                        .multilineTextAlignment(.center)
                    
                    Image("brand_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                    
                    Text(bodyText(for: pageIndex) ?? "")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "555555"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, sidePadding)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
        } else {
            // 其他页面：标准布局
            VStack(spacing: 24) {
                // 插图区域
                illustrationSection
                
                // 副标题区域
                prefixSection
                
                // 标题区域
                titleSection
                
                // 正文区域
                bodySection
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - 插图区域
    @ViewBuilder
    private var illustrationSection: some View {
        ZStack(alignment: .bottom) {
            if let imageName = imageName(for: pageIndex) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageWidth(for: pageIndex))
            }
        }
        .frame(height: illustrationHeight, alignment: .bottom)
    }

    // MARK: - 副标题区域
    @ViewBuilder
    private var prefixSection: some View {
        if let prefix = prefixText(for: pageIndex) {
            Text(prefix)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "555555"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, sidePadding)
        } else {
            Color.clear.frame(height: prefixHeight)
        }
    }

    // MARK: - 标题区域
    @ViewBuilder
    private var titleSection: some View {
        Text(titleText(for: pageIndex))
            .font(.system(size: titleFontSize, weight: .bold))
            .foregroundColor(Color(hex: "212121"))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, sidePadding)
    }

    // MARK: - 正文区域
    @ViewBuilder
    private var bodySection: some View {
        if let body = bodyText(for: pageIndex) {
            Text(body)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "555555"))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, sidePadding)
        }
    }

    // MARK: - 底部按钮区域
    @ViewBuilder
    private var footerSection: some View {
        VStack(spacing: 16) {
            switch pageIndex {
            case 0:
                dualButtons(primary: "是的", secondary: "我不怕胖")
            case 1:
                dualButtons(primary: "是的", secondary: "不是")
            case 2:
                singleButton(title: "开始体验！", isPrimary: true)
            case 3:
                dualButtons(primary: "下一页", secondary: "上一页")
            case 4:
                dualButtons(primary: "开始！", secondary: "上一页")
            default:
                EmptyView()
            }
        }
        .padding(.horizontal, sidePadding)
        .padding(.bottom, 32)
    }

    // MARK: - 按钮组件
    @ViewBuilder
    private func singleButton(title: String, isPrimary: Bool) -> some View {
        Button(action: {
            handleButtonAction(title: title, isPrimary: isPrimary)
        }) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "212121"))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color(hex: "FFE5B4"))
                .cornerRadius(20)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private func dualButtons(primary: String, secondary: String) -> some View {
        HStack(spacing: 12) {
            // 次按钮（左）
            Button(action: {
                handleButtonAction(title: secondary, isPrimary: false)
            }) {
                Text(secondary)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "212121"))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(hex: "FFE5B4"), lineWidth: 2)
                    )
            }
            .buttonStyle(ScaleButtonStyle())

            // 主按钮（右）
            Button(action: {
                handleButtonAction(title: primary, isPrimary: true)
            }) {
                Text(primary)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "212121"))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color(hex: "FFE5B4"))
                    .cornerRadius(20)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    // MARK: - 圆点进度指示器
    @ViewBuilder
    private var dotIndicator: some View {
        if pageIndex <= 1 {
            // 前两页：问答页
            DotIndicator(total: 2, current: pageIndex)
        } else if pageIndex >= 3 {
            // 后两页：产品介绍页
            DotIndicator(total: 2, current: pageIndex - 3)
        } else {
            // 欢迎页不显示
            EmptyView()
        }
    }

    // MARK: - 按钮行为处理
    private func handleButtonAction(title: String, isPrimary: Bool) {
        if pageIndex == 4 && title.contains("开始") {
            // 完成引导，进入登录/注册
            completeOnboarding()
        } else if title.contains("上一页") {
            previousPage()
        } else {
            nextPage()
        }
    }

    private func nextPage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            pageIndex = min(pageIndex + 1, 4)
        }
    }

    private func previousPage() {
        withAnimation(.easeInOut(duration: 0.3)) {
            pageIndex = max(pageIndex - 1, 0)
        }
    }

    private func completeOnboarding() {
        appState.completeOnboarding()
        showLoginView = true
    }

    // MARK: - 数据源
    private func imageName(for index: Int) -> String? {
        switch index {
        case 0: return "guidance1"
        case 1: return "guidance2"
        case 3: return "guidance4"
        case 4: return "guidance5"
        default: return nil
        }
    }

    private func imageWidth(for index: Int) -> CGFloat {
        switch index {
        case 0: return 200
        case 1: return 300
        case 3: return 300
        case 4: return 300
        default: return 200
        }
    }

    private func titleText(for index: Int) -> String {
        switch index {
        case 0:
            return "你是否怕长胖，\n而不敢吃小蛋糕，喝奶茶？"
        case 1:
            return "你是否算不清楚吃了多少\n卡路里？"
        case 2:
            return "欢迎来到该吃吃"
        case 3:
            return "你只管好好吃，\n不用精确计算卡路里"
        case 4:
            return "只要动起来，做家务、\n遛狗都可以消耗热量"
        default:
            return ""
        }
    }

    private func bodyText(for index: Int) -> String? {
        switch index {
        case 1:
            return "比如：喜茶的芝芝多肉葡萄少少甜，有多少热量？"
        case 2:
            return "我是一款\"美食↔运动\"计算器，\n帮你把美食直接变成运动量\n\n希望帮助大家不长胖！"
        case 3:
            return "我帮你直接计算运动量，不用全天复杂的卡路里监控"
        case 4:
            return "从简单的运动开始，遛弯2公里就可以消耗一根甜筒的热量！"
        default:
            return nil
        }
    }

    private func prefixText(for index: Int) -> String? {
        switch index {
        case 3, 4:
            return "在该吃吃："
        default:
            return nil
        }
    }
}

// MARK: - 圆点进度指示器组件
private struct DotIndicator: View {
    let total: Int
    let current: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Circle()
                    .fill(index == current ? Color(hex: "FFDA6C") : Color(hex: "EAEAEA"))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

// MARK: - 预览
#Preview {
    OnboardingGuideView()
        .environmentObject(AppState.shared)
} 