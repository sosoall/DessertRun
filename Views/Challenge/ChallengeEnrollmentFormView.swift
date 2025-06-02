import SwiftUI

/// 挑战报名信息完善页面
struct ChallengeEnrollmentFormView: View {
    let challenge: ChallengeActivity
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ChallengeEnrollmentFormViewModel()
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 导航栏
                headerView
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 预计发货提示
                        if challenge.activityType != .free {
                            deliveryNoticeView
                        }
                        
                        // 选择挑战活动
                        challengeSelectionView
                        
                        // 选择奖励
                        rewardSelectionView
                        
                        // 收货地址（仅付费活动显示）
                        if challenge.activityType != .free {
                            shippingAddressView
                        }
                        
                        // 服务协议
                        agreementView
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
                
                // 底部价格和报名按钮
                bottomActionView
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.challenge = challenge
        }
    }
    
    // MARK: - 头部导航
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("完善报名信息")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 占位，保持标题居中
                Color.clear
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - 发货提示
    private var deliveryNoticeView: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.fill")
                .font(.system(size: 16))
                .foregroundColor(.orange)
            
            Text("预计完赛后 5 个工作日内发货")
                .font(.system(size: 14))
                .foregroundColor(.orange)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - 选择挑战活动
    private var challengeSelectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("选择挑战活动")
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // 挑战图标
                    AsyncImage(url: URL(string: challenge.imageURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // 选中标识
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green, lineWidth: 2)
                )
            }
        }
    }
    
    // MARK: - 选择奖励
    private var rewardSelectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("选择奖励")
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // 奖励图标
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "gift.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.formattedReward)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // 选中标识
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green, lineWidth: 2)
                )
            }
        }
    }
    
    // MARK: - 收货地址
    private var shippingAddressView: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("收货地址")
            
            if viewModel.hasShippingAddress {
                // 显示地址信息
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("收件人：")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Text(viewModel.recipientName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            
                            HStack {
                                Text("电话：")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Text(viewModel.phoneNumber)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            
                            HStack(alignment: .top) {
                                Text("收货地址：")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Text(viewModel.fullAddress)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .onTapGesture {
                    viewModel.showAddressEdit = true
                }
            } else {
                // 显示添加地址按钮
                Button(action: {
                    viewModel.showAddressEdit = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                        
                        Text("添加收货地址")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .sheet(isPresented: $viewModel.showAddressEdit) {
            AddressEditView(
                recipientName: $viewModel.recipientName,
                phoneNumber: $viewModel.phoneNumber,
                province: $viewModel.province,
                city: $viewModel.city,
                district: $viewModel.district,
                detailAddress: $viewModel.detailAddress,
                onSave: {
                    viewModel.saveAddress()
                }
            )
        }
    }
    
    // MARK: - 协议勾选
    private var agreementView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                viewModel.isAgreementAccepted.toggle()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.isAgreementAccepted ? "checkmark.square.fill" : "square")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.isAgreementAccepted ? .green : .gray)
                    
                    HStack(spacing: 4) {
                        Text("我已经阅读并同意")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                        
                        Button("线上挑战服务协议") {
                            viewModel.showAgreement = true
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .sheet(isPresented: $viewModel.showAgreement) {
            ServiceAgreementView()
        }
    }
    
    // MARK: - 底部操作区
    private var bottomActionView: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                if challenge.activityType != .free {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("总计")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .bottom, spacing: 4) {
                            Text("¥")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                            
                            Text("\(challenge.price ?? 0)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.enrollChallenge()
                }) {
                    Text("去报名")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(height: 44)
                        .frame(minWidth: 120)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(viewModel.canEnroll ? Color.green : Color.gray)
                        )
                }
                .disabled(!viewModel.canEnroll)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - 辅助方法
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.primary)
    }
}

// MARK: - ViewModel
class ChallengeEnrollmentFormViewModel: ObservableObject {
    @Published var challenge: ChallengeActivity?
    @Published var recipientName: String = ""
    @Published var phoneNumber: String = ""
    @Published var province: String = ""
    @Published var city: String = ""
    @Published var district: String = ""
    @Published var detailAddress: String = ""
    @Published var provinceCode: String = ""
    @Published var cityCode: String = ""
    @Published var districtCode: String = ""
    @Published var isAgreementAccepted: Bool = false
    @Published var showAgreement: Bool = false
    @Published var isEnrolling: Bool = false
    @Published var showAddressEdit: Bool = false
    
    var canEnroll: Bool {
        guard let challenge = challenge else { return false }
        
        let basicRequirements = isAgreementAccepted
        
        if challenge.activityType == .free {
            return basicRequirements
        } else {
            return basicRequirements && hasShippingAddress
        }
    }
    
    var hasShippingAddress: Bool {
        !recipientName.isEmpty && !phoneNumber.isEmpty && !fullAddress.isEmpty
    }
    
    var fullAddress: String {
        var components = [String]()
        if !province.isEmpty { components.append(province) }
        if !city.isEmpty { components.append(city) }
        if !district.isEmpty { components.append(district) }
        if !detailAddress.isEmpty { components.append(detailAddress) }
        return components.joined(separator: " ")
    }
    
    // 兼容旧的shippingAddress字段
    var shippingAddress: String {
        get { fullAddress }
        set { 
            // 解析地址字符串（简单实现）
            detailAddress = newValue
        }
    }
    
    func enrollChallenge() {
        guard canEnroll else { return }
        
        isEnrolling = true
        
        // TODO: 实现实际的报名逻辑
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isEnrolling = false
            // 报名成功后的处理
        }
    }
    
    func saveAddress() {
        // 实现保存地址的逻辑
        showAddressEdit = false
    }
}

// MARK: - 服务协议页面
struct ServiceAgreementView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 标题
                    Text("\"该吃吃\"线上挑战服务协议")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.bottom, 10)
                    
                    // 协议内容
                    VStack(alignment: .leading, spacing: 16) {
                        // 风险提示
                        agreementSection(
                            title: "风险提示：",
                            content: """
                            1、本协议是用户与"该吃吃"软件就参与"该吃吃"线上挑战活动达成的权利义务约定。用户点击"去报名"按钮即视为签署本协议，协议自报名成功时生效。
                            
                            2、您在参加「"该吃吃"线上挑战活动」(以下简称"挑战活动")前，请确认系您本人自愿参加本赛事，您已全面了解并同意遵守"该吃吃"(以下亦可称为"我们")所制定的各项挑战活动规则、规定、要求及采取的紧急措施。
                            
                            3、请确保您的身体状况适合参加此赛事，不存在会影响参加本次赛事的疾病，并已为参加本次赛事做好了充分的准备。您应为您参加线上赛事过程中的个人安全负责，并对赛事中可能发生的风险和意外做了全面、审慎的评估。因参加此赛事而引起的一切风险、损害及责任等，需由您自行承担，"该吃吃"将不承担赔偿及其他法律责任。
                            """
                        )
                        
                        // 一、服务条款的确认、接受及变更
                        agreementSection(
                            title: "一、服务条款的确认、接受及变更",
                            content: """
                            1、您点击同意本条款前，需确认自己已满足《中华人民共和国民法典》的规定，具有合法的主体资格：
                            
                            （1）年满18周岁，精神健康、智力健全，具有完全民事行为能力，可以独立进行民事活动，独立承担法律责任；或
                            （2）16周岁以上不满18周岁的公民，以自己的劳动收入为主要生活来源，精神健康、智力健全的，可以独立进行民事活动，独立承担法律责任；或
                            （3）未满16周岁，精神健康、智力健全的限制民事行为能力人，必须在父母或监护人的全程监护陪同下参与，其父母和监护人能够承担相应的法律责任。
                            
                            2、您同意本条款并完成报名程序后，即成为本挑战活动的参与者。您即确认本条款是处理双方权利义务的契约，始终有效，法律另有强制性规定或双方另有特别约定的，依其规定。
                            
                            3、根据国家法律法规的更新及网站运营需要，"该吃吃"有权对本条款不时地进行修改，以为您提供更好的服务体验。修改后的服务条款一经发布，即发生效力，并代替原条款。您可随时登录查阅最新的条款内容。如您不同意更新后的条款，应立即停止使用此服务；如您继续使用此服务，即视为同意更新后的条款。我们建议您在参与本挑战活动之前阅读本条款及其他相关公告。如果本条款中任何一条被视为废止、无效或因任何理由不可执行，该条应视为可分的且并不影响任何其余条款的有效性和可执行性。
                            """
                        )
                        
                        // 二、报名规则与费用
                        agreementSection(
                            title: "二、报名规则与费用",
                            content: """
                            1、报名与费用
                            
                            （1）付费挑战一经报名成功，费用不予退还，报名信息不可修改，且不可申请退赛。
                            （2）免费挑战仅提供虚拟奖励，付费挑战提供实体奖励（美食盲盒或餐饮优惠券），具体内容以对应挑战详情页公示为准。
                            
                            2、完成挑战标准
                            
                            （1）各挑战的完成条件（如 "有效打卡 3 次、每次≥15 分钟"）、奖励内容及特殊规则，均在挑战详情页的《挑战奖励》和《挑战要求》中明确说明。
                            （2）请注意，如果一个挑战有多个任务，请在规定时间内完成所有任务才能算作完成挑战。如果仅完成部分任务，并不认为完成挑战，也不会发放任何奖励。
                            
                            3、用户个人信息收集
                            
                            （1）对于付费的挑战，您在报名期间，我们需要收集您的姓名、电话、收货地址等信息，以便向您邮寄活动实体奖励。您在此知晓并同意我们向您收取前述信息，且授权我们将您的该类信息提供给为我们提供产品供应和发货服务的第三方，以便完成发货。我们承诺会按照法律规定对您提供的该类信息予以安全保护，且仅用于"该吃吃"线上活动产品邮寄使用，未经您的另行授权同意，我们不会将该类信息用于任何其他目的。若您不提供前述信息，将无法使用本线上赛事服务。
                            
                            4、退费与发货规则
                            
                            （1）关于退费：本活动暂不支持取消报名，也不支持退费，一经报名无法退出，请谨慎选择。
                            （2）发货规则：实体挑战奖励将于您完成挑战后的10个工作日内，按照您提供的地址发货（如遇特殊情况无法在约定时间内发货的，我们将另行向您发送通知以告知发货时间）。如您的挑战奖励中包含虚拟奖励的，您可以在完赛后通过"该吃吃"App-【我的】-【徽章】-查询您的虚拟奖励，也可在【我的挑战】-【该挑战】-【查看奖励】中查看。
                            """
                        )
                        
                        // 三、实体奖励特别约定
                        agreementSection(
                            title: "三、实体奖励特别约定",
                            content: """
                            1、供应商资质与售后
                            
                            （1）食物类实体奖励由具备合法资质的供应商提供（供应商名称及《食品经营许可证》编号见附件），平台已尽到形式审查义务。用户收到食品后应立即检查，如发现变质、过期等问题，可从软件内联系我们。
                            
                            2、风险提示与用户义务
                            
                            （1）食品可能含有过敏原（如乳制品、坚果等），用户应自行评估食用风险。因个人体质导致的不良反应，由用户自行承担。
                            （2）用户需在收到食品后 48 小时内反馈质量问题，逾期视为验收合格。
                            （3）平台将在挑战详情页及邮寄包裹中，以加粗字体或图标明确标注需冷藏 / 特殊保存的食品要求（如"需冷藏保存，保质期3天"）。用户参与挑战即视为已充分知晓并认可食品的保存方法及注意事项。若因用户怠于履行保存义务（如未按标注要求冷藏、超保质期食用等）导致食品变质、损坏的，我们不承担任何赔偿责任，相关风险由用户自行承担。
                            """
                        )
                        
                        // 四、其他事项
                        agreementSection(
                            title: "四、其他事项",
                            content: """
                            1、您在参与本挑战活动过程中，应遵守法律法规及社会公序良俗。"该吃吃"保留对您活动参与行为进行监督的权利，若"该吃吃"发现您在参与挑战活动的过程中有违反国家法律法规或社会公序良俗的情况，有权取消您参加本次挑战活动的权利；或您在挑战过程中有涉及违法行为，"该吃吃"将保留举报和向您追究法律责任的权利；若因您存在上述行为而给"该吃吃"造成损失的，"该吃吃"有权要求您赔偿全部损失。
                            
                            2、禁止任何用户以不正当手段参与"该吃吃"的赛事活动，包括但不限于强制修改页面参数、以任何机器人软件、蜘蛛软件、爬虫软件、刷屏软件、任务平台或任何其他非人工方式参与赛事活动、基于程序漏洞获取挑战奖励等。一经发现，"该吃吃"有权在不事先通知的情况下取消该用户参与挑战活动的资格，并有权将该用户于对应挑战活动中获得的挑战奖励、徽章等实体和虚拟权益全部收回。如因用户的不正当行为给"该吃吃"造成损失的，"该吃吃"有权要求其赔偿全部损失，且"该吃吃"保留向有关机关举报、进一步追究该用户其他法律责任的权利。
                            
                            3、挑战活动涉及的合作方、供应商、物流服务商等第三方主体，由其独立承担相应责任。若因第三方原因导致您受损，您应直接向该第三方主张权利。平台将提供必要的协助，但不承担连带责任。
                            
                            4、挑战活动期间，因您操作不当或您所在地区网络故障、电信运营商故障等非"该吃吃"所能控制的原因导致您无法参与活动或参与失败的，请您规范操作或联系当地电信运营商解决。
                            
                            5、挑战活动期间，如出现不可抗力或其他特殊情况导致活动需要调整或提前终止的，"该吃吃"有权暂停或提前终止本次活动而无需向您进行任何赔偿或补偿。
                            """
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("关闭") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // 协议段落组件
    private func agreementSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 8)
    }
}

#Preview {
    let sampleChallenge = ChallengeActivity(
        id: "sample",
        name: "每天都要city walk",
        description: "走路也能兑换美食！三次轻松步行，换取美味水果甜点，健康与美味兼得。",
        requirement: "每天步行30分钟",
        activityType: .paid,
        startDate: Date(),
        endDate: Date().addingTimeInterval(86400 * 7),
        requiredCheckins: 3,
        requiredExerciseTypeId: nil,
        requiredExerciseTypeName: nil,
        foodRestrictionType: "none",
        requiredFoodCategoryIds: nil,
        requiredFoodCategoryNames: nil,
        requiredFoodIds: nil,
        requiredFoodNames: nil,
        requiredDifferentFoodTypes: false,
        requiredDifferentExerciseTypes: false,
        completionDaysLimit: 7,
        minDistancePerCheckin: nil,
        minDurationPerCheckin: 30,
        minEquivalentDessertPerCheckin: nil,
        displayOrder: 1,
        price: 49,
        vipOnly: false,
        rewardType: .dessertBox,
        rewardAmount: 1,
        rewardDescription: "美食盲盒",
        isActive: true,
        isForBeginner: false,
        createdAt: Date(),
        updatedAt: Date()
    )
    
    ChallengeEnrollmentFormView(challenge: sampleChallenge)
} 