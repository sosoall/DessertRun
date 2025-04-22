import SwiftUI

/// 数据结构 - 日历日期项
struct CalendarDateItem {
    let day: Int
    let isCurrentMonth: Bool
    let isToday: Bool
    let hasData: Bool
    let burnedCalories: Double
    let targetCalories: Double
    let isGoalAchieved: Bool
}

/// 数据结构 - 周数据点
struct WeeklyDataPoint: Identifiable {
    let id: Int
    let weekday: String
    let burnedCalories: Double
    let targetCalories: Double
    let isGoalAchieved: Bool
}

/// 数据结构 - 顶级甜品项
struct TopDessertItem: Identifiable {
    let id: String
    let name: String
    let imageName: String
    let calories: Double
    let count: Int
    let totalCalories: Double
    
    // 获取完整图片名称
    func getFullImageName(for style: FoodImageStyle = .regular) -> String {
        return "\(imageName)_regular"
    }
}

/// 主统计页面 - 包含甜品打卡和运动记录两个标签页
struct StatsView: View {
    @ObservedObject var viewModel: StatsViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标签选择器
            HStack(spacing: 0) {
                // 甜品打卡标签
                Button(action: {
                    withAnimation {
                        selectedTab = 0
                    }
                }) {
                    Text("甜品打卡")
                        .font(.system(size: 16, weight: selectedTab == 0 ? .bold : .medium))
                        .foregroundColor(selectedTab == 0 ? .black : .gray)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                }
                .background(
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(selectedTab == 0 ? Color.orange : Color.clear)
                            .frame(height: 3)
                    }
                )
                
                // 运动记录标签
                Button(action: {
                    withAnimation {
                        selectedTab = 1
                    }
                }) {
                    Text("运动记录")
                        .font(.system(size: 16, weight: selectedTab == 1 ? .bold : .medium))
                        .foregroundColor(selectedTab == 1 ? .black : .gray)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                }
                .background(
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(selectedTab == 1 ? Color.orange : Color.clear)
                            .frame(height: 3)
                    }
                )
            }
            .background(Color.white)
            
            // 标签页内容
            TabView(selection: $selectedTab) {
                // 甜品打卡标签页
                FoodCheckInView(viewModel: viewModel)
                    .tag(0)
                
                // 运动记录标签页
                ExerciseRecordView(viewModel: viewModel)
                    .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    StatsView(viewModel: StatsViewModel(appState: AppState.shared))
} 
