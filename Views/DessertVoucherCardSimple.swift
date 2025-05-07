import SwiftUI

/// 美食券卡片视图（简化版本）
struct DessertVoucherCardSimple: View {
    /// 打卡记录
    let record: WorkoutRecord
    
    /// 是否展开详情
    @State private var isExpanded: Bool = false
    
    /// 是否正在核销
    @State private var isRedeeming: Bool = false
    
    /// 核销相关错误
    @State private var redeemError: String? = nil
    
    /// 显示核销确认
    @State private var showRedeemConfirm: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 卡片主体部分
            cardHeader
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }
            
            // 底部操作区
            cardFooter
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
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "#FFE5ED"), location: 0),
                    .init(color: Color(hex: "#FFEAC0"), location: 0.59),
                    .init(color: Color(hex: "#FF9901"), location: 1)
                ]),
                startPoint: .trailing,
                endPoint: .leading
            )
            .cornerRadius(20, corners: [.topLeft, .topRight])
            
            // 白色边框
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white, lineWidth: 1)
                .cornerRadius(20, corners: [.topLeft, .topRight])
            
            // 主要内容
            HStack(spacing: 0) {
                // 左侧 - 美食相关信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1fx", record.equivalentDessertCount))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(hex: "#FE5C72"))
                    
                    Text(record.dessert.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#FE5C72"))
                    
                    Spacer()
                    
                    // 左下方奶茶图标
                    Image("milktea_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .padding(.bottom, 8)
                }
                .frame(width: UIScreen.main.bounds.width / 2 - 32, alignment: .leading)
                .padding(.leading, 16)
                .padding(.top, 16)
                
                // 中间分隔线
                Rectangle()
                    .fill(Color(hex: "#D7B8BE"))
                    .frame(width: 1, height: 70)
                    .padding(.vertical, 15)
                
                // 右侧 - 运动相关信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.exerciseType.name)
                        .font(.system(size: 32, weight: .bold))
                    
                    if isExpanded {
                        // 运动标签文本
                        Text(record.displayWorkoutTag)
                            .font(.system(size: 16, weight: .bold))
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
                            Text(formattedDateTime(record.completionDate))
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(hex: "#919191"))
                        }
                        .padding(.top, 8)
                    } else {
                        Spacer()
                        
                        // 右侧背景图像占位，靠右对齐
                        Image("dessert_background")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                    }
                }
                .frame(width: UIScreen.main.bounds.width / 2 - 32, alignment: .leading)
                .padding(.leading, 12)
                .padding(.trailing, 16)
                .padding(.top, 16)
            }
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
                    if isExpanded {
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
                        .background(Color(hex: isExpanded ? "#FF318D" : "#FE2D55"))
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
                dessert: DessertItem(
                    id: 1, 
                    name: "芝芝奶茶", 
                    imageName: "dessert_01",
                    calories: "235",
                    category: .drink,
                    categoryId: 1,
                    categoryName: "饮品",
                    displayOrder: 1,
                    images: []
                ),
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
                completionDate: Date(),
                duration: 57,
                caloriesBurned: 350,
                equivalentDessertCount: 1.3,
                distance: 2500,
                workoutTag: "运动量super!"
            )
            
            // 展开状态预览
            DessertVoucherCardSimple(record: sampleRecord)
                .frame(width: 350)
                .onAppear {
                    // 模拟展开状态
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if let preview = Mirror(reflecting: DessertVoucherCardSimple(record: sampleRecord)).descendant("_isExpanded") as? Binding<Bool> {
                            preview.wrappedValue = true
                        }
                    }
                }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
} 