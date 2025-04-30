import SwiftUI

/// 甜品打卡标签页
struct FoodCheckInView: View {
    @ObservedObject var viewModel: StatsViewModel
    @State private var newRecordId: String? = nil
    @State private var showNewRecordAnimation: Bool = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 美食记录卡片
                foodRecordCard
                    .padding(.horizontal)
                
                // 所有美食打卡记录（直接显示，不需要点击按钮）
                foodRecordsList
                    .padding(.horizontal)
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGray6))
        .onAppear {
            // 仅当刚完成打卡时才显示动画（通过检查应用状态中的标记来判断）
            if appState.justCompletedWorkout, let latestRecord = viewModel.getSortedAllRecords().first {
                // 将新记录ID存入状态变量
                newRecordId = "\(latestRecord.id)"
                
                // 延迟一点，确保视图已经加载
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showNewRecordAnimation = true
                    }
                    
                    // 3秒后重置状态，但不需要消失动画
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        // 没有动画效果，只重置状态
                        showNewRecordAnimation = false
                        newRecordId = nil
                        appState.justCompletedWorkout = false
                    }
                }
            }
        }
    }
    
    // 美食记录卡片
    private var foodRecordCard: some View {
        VStack(spacing: 24) {
            // 标题
            VStack(spacing: 8) {
                HStack {
                    Text("美食记录")
                        .font(.system(size: 22, weight: .semibold))
                    
                    Spacer()
                }
            }
            
            // 美食排行榜和记录卡片
            VStack(spacing: 20) {
                foodRankingCard
                
                // 数据统计卡片行
                HStack(spacing: 16) {
                    foodCheckInCountCard
                    foodVarietyCard
                }
            }
        }
    }
    
    // 美食排行榜卡片
    private var foodRankingCard: some View {
        VStack(spacing: 16) {
            // 美食排行榜水平布局
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    if let topDesserts = viewModel.getAllTopDesserts(count: 4) {
                            
                        ForEach(Array(topDesserts.enumerated()), id: \.element.id) { index, dessert in
                            VStack(spacing: 8) {
                                ZStack(alignment: .top) {
                                    VStack {
                                        Spacer()
                                        Image(dessert.getFullImageName(for: .regular))
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: index == 0 ? 120 : 75)
                                            .cornerRadius(8)
                                    }
                                    .frame(height: 120)
                                    
                                    if index == 0 {
                                        Image("crown")
                                            .resizable()
                                            .renderingMode(.original)
                                            .scaledToFit()
                                            .frame(width: 40, height: 40)
                                            .offset(x: 10, y: -15)
                                    }
                                }
                                
                                Text("打卡\(dessert.count)次")
                                    .font(.system(size: 12))
                                    .foregroundColor(.black)
                            }
                        }
                    } else {
                        Text("暂无记录")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    // 美食打卡次数卡片
    private var foodCheckInCountCard: some View {
        HStack(spacing: 12) {
            Image("Number_of_check_in")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 24, height: 24)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(viewModel.totalFoodCheckInCount)")
                    .font(.system(size: 20, weight: .semibold))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text("次美食打卡")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 2, y: 2)
    }
    
    // 美食种类卡片
    private var foodVarietyCard: some View {
        HStack(spacing: 12) {
            Image("Number_of_sort")
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .frame(width: 24, height: 24)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(viewModel.allUniqueDessertTypes)")
                    .font(.system(size: 20, weight: .semibold))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                Text("种美食")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 2, y: 2)
    }
    
    // 所有美食打卡记录列表
    private var foodRecordsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Text("全部打卡记录")
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
            }
            .padding(.top, 8)
            
            // 所有打卡记录
            allFoodRecords
        }
    }
    
    // 所有美食打卡记录
    private var allFoodRecords: some View {
        VStack(spacing: 16) {
            if appState.workoutRecords.isEmpty {
                emptyRecordsView
            } else {
                // 获取按时间倒序排列的所有记录
                let sortedRecords = viewModel.getSortedAllRecords()
                
                ForEach(Array(sortedRecords.enumerated()), id: \.element.id) { index, record in
                    // 检查是否是新记录
                    let isNewRecord = newRecordId == "\(record.id)" && index == 0
                    
                    if isNewRecord && showNewRecordAnimation {
                        // 为新记录显示动画效果，只有从顶部出现的动画
                        FoodRecordCard(record: record)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    } else {
                        FoodRecordCard(record: record)
                    }
                }
            }
        }
    }
    
    // 空记录视图
    private var emptyRecordsView: some View {
        VStack {
            Image(systemName: "tray.fill")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
                .padding()
            
            Text("暂无美食打卡记录")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// 单个美食打卡记录卡片
struct FoodRecordCard: View {
    let record: WorkoutRecord
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部日期
            HStack {
                Text(record.formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // 目标状态指示器
                if record.caloriesBurned >= (Double(record.dessert.calories) ?? 0) {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 14, height: 14)
                        
                        Text("已达成")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: 14, height: 14)
                        
                        Text("未达成")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Divider()
            
            // 左右分栏内容
            HStack(alignment: .center, spacing: 12) {
                // 左侧 - 美食信息
                HStack(alignment: .center, spacing: 12) {
                    // 美食图片
                    Image(record.dessert.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // 美食名称
                        Text(record.dessert.name)
                            .font(.headline)
                        
                        // 美食热量
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Text("\(record.dessert.calories) 卡路里")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)
                
                // 分隔线
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 60)
                
                // 右侧 - 运动信息
                VStack(alignment: .leading, spacing: 6) {
                    // 运动类型标签
                    Label(record.exerciseType.name, systemImage: record.exerciseType.iconName)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(record.exerciseType.color)
                        .cornerRadius(12)
                    
                    // 时间/距离信息
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if let distance = record.distance, record.exerciseType.usesDistance {
                            Text("\(String(format: "%.1f", distance/1000))公里")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text(record.formattedDuration)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // 卡路里消耗
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        Text("\(Int(record.caloriesBurned)) 卡")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - 动画修饰器
struct NewRecordAnimation: ViewModifier {
    let isNewRecord: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isNewRecord ? 0 : 1) // 初始设为透明
            .animation(.easeIn(duration: 0.3).delay(isNewRecord ? 0.2 : 0), value: isNewRecord)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.clear, lineWidth: 2)
            )
            .scaleEffect(1.0) // 移除缩放效果
            .onAppear {
                if isNewRecord {
                    withAnimation(.easeInOut(duration: 0.5).delay(0.3)) {
                        // 淡入效果
                    }
                }
            }
    }
} 