import SwiftUI

/// 美食券卡片视图（简化版本）
struct DessertVoucherCardSimple: View {
    /// 打卡记录
    let record: WorkoutRecord
    
    /// 是否正在核销
    @State private var isRedeeming: Bool = false
    
    /// 核销相关错误
    @State private var redeemError: String? = nil
    
    /// 显示核销确认
    @State private var showRedeemConfirm: Bool = false
    
    /// 强制展开状态（用于弹窗展示）
    var forceExpanded: Bool = false
    
    /// 提供一个环境变量，用于触发弹窗展示
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // 卡片主体部分
            cardHeader
            
            // 底部操作区
            cardFooter
        }
        .onTapGesture {
            // 只有非强制展开状态下才触发弹窗展示
            if !forceExpanded {
                // 通知父视图显示弹窗
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowExpandedCard"),
                    object: record
                )
            }
        }
        .alert("确认核销", isPresented: $showRedeemConfirm) {
            Button("取消", role: .cancel) {}
            Button("确认核销") {
                redeemVoucher()
            }
        } message: {
            Text("确定要核销这张美食券吗？\n只有VIP用户才能核销美食券。\n核销后无法恢复。")
        }
        .alert("核销失败", isPresented: Binding<Bool>(
            get: { redeemError != nil },
            set: { if !$0 { redeemError = nil } }
        )) {
            Button("确定", role: .cancel) {
                redeemError = nil
            }
        } message: {
            Text(redeemError ?? "未知错误")
        }
    }
    
    // MARK: - 卡片主体部分
    private var cardHeader: some View {
        ZStack(alignment: .center) {
            // 1. 背景渐变 - 放在最底层
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "#FF9D0B"), location: 0),
                    .init(color: Color(hex: "#FFEAC5"), location: 0.44),
                    .init(color: Color(hex: "#FFE5EC"), location: 1)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .cornerRadius(20, corners: [.topLeft, .topRight])
            
            // 2. 白色边框 - 只在上边加圆角
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white, lineWidth: 1)
                .cornerRadius(20, corners: [.topLeft, .topRight])
            
            // 3. 内容布局 - 使用HStack将所有内容放在同一层
            HStack(spacing: 0) {
                // 左侧奶茶图标 - 贴边显示
                Image("milktea_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                
                // 食物信息 - 右对齐
                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "%.1fx", record.equivalentDessertCount))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "#FE5C72"))
                    
                    Text(record.dessert.name)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(hex: "#FE5C72"))
                }
                .padding(.leading, 10)
                
                // 中间分隔线 - 固定高度70
                Rectangle()
                    .fill(Color(hex: "#D7B8BE"))
                    .frame(width: 1, height: 70)
                    .padding(.horizontal, 15)
                
                // 右侧内容区域 - 左对齐
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.exerciseType.name)
                        .font(.system(size: 20, weight: .semibold))
                    
                    if forceExpanded {
                        // 运动标签文本
                        Text(record.displayWorkoutTag)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#F8A41C"))
                            .padding(.top, 4)
                        
                        // 展开时显示运动详情
                        VStack(alignment: .leading, spacing: 8) {
                            // 运动距离
                            HStack(spacing: 8) {
                                Image(systemName: "figure.walk")
                                    .foregroundColor(Color(hex: "#FF7B15"))
                                
                                if let distance = record.distance {
                                    Text(String(format: "%.1f公里", distance / 1000))
                                        .font(.system(size: 16, weight: .medium))
                                } else {
                                    Text("--")
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                            
                            // 消耗热量
                            HStack(spacing: 8) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.red)
                                
                                Text("\(Int(record.caloriesBurned))卡路里")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            
                            // 日期时间
                            Text(formattedDateTime(record.date))
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(hex: "#919191"))
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.trailing, 0)
                
                Spacer()
                
                // 右侧甜品图像 - 贴边显示
                Image("dessert_background")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
            }
            .frame(height: 100)
        }
        .frame(height: 100)
    }
    
    // 日期格式化函数
    private func formattedDateTime(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd\nHH:mm"
        return dateFormatter.string(from: date)
    }
    
    // MARK: - 卡片底部部分
    private var cardFooter: some View {
        // 底部核销区域
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    if forceExpanded {
                        Text("美食券")
                            .font(.system(size: 16, weight: .bold))
                    }
                    
                    // 剩余天数
                    Text("剩余29天")
                        .font(.system(size: 14, weight: .regular))
                }
                
                Spacer()
                
                // 核销按钮
                Button(action: {
                    showRedeemConfirm = true
                }) {
                    Text("立即核销")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 16)
                        .background(Color(hex: forceExpanded ? "#FF318D" : "#FE2D55"))
                        .cornerRadius(10)
                }
                .disabled(isRedeeming)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        Color.gray.opacity(0.5),
                        style: StrokeStyle(
                            lineWidth: 1,
                            dash: [5, 5]
                        )
                    )
                    .clipShape(RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight]))
            )
        }
        .frame(height: 45)
    }
    
    // MARK: - 核销操作
    private func redeemVoucher() {
        isRedeeming = true
        
        // 模拟核销请求 - 实际应用中应调用VoucherService
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isRedeeming = false
            
            // 这里应该有实际的核销逻辑
            // 例如：VoucherService.shared.redeemVoucher(id: record.id) { success, error in ... }
            
            // 模拟随机成功或失败
            let success = Bool.random()
            if !success {
                redeemError = "暂不支持核销功能，请稍后再试"
            }
        }
    }
}

// MARK: - 辅助扩展

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - 预览

struct DessertVoucherCardSimple_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // 收起状态
            DessertVoucherCardSimple(record: WorkoutRecord.createSample())
                .frame(width: 350)
            
            // 自定义样本 - 展开状态
            let sampleRecord = WorkoutRecord(
                id: UUID().uuidString,
                userId: UUID().uuidString,
                exerciseType: ExerciseType(
                    type: "walking",
                    name: "跑步",
                    description: "跑步是一种有氧运动",
                    iconName: "figure.run",
                    usesDistance: true,
                    backgroundColor: "#FF6B6B",
                    caloriesPerMinPerKg: 0.1,
                    caloriesPerKmPerKg: 0.7,
                    displayOrder: 1
                ),
                duration: 57,
                distance: 2500,
                caloriesBurned: 350,
                dessert: DessertItem(
                    id: 1, 
                    name: "芝芝奶茶", 
                    imageName: "dessert_01",
                    calories: "235",
                    category: .drink,
                    description: "",
                    backgroundColor: nil,
                    isFeatured: false,
                    relatedItems: [],
                    categoryId: 1,
                    categoryName: "饮品",
                    displayOrder: 1,
                    images: []
                ),
                date: Date(),
                workoutTag: "运动量super!",
                equivalentDessertCount: 1.3
            )
            
            // 展开状态预览
            DessertVoucherCardSimple(record: sampleRecord, forceExpanded: true)
                .frame(width: 350)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
} 