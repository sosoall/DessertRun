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

/// 统计视图，包含食物统计和运动记录
struct StatsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel: StatsViewModel
    
    init() {
        // 注意：StatsViewModel不使用@StateObject初始化的原因是需要传入AppState
        // 我们在body中访问AppState，所以需要先对ViewModel进行初始化
        self._viewModel = StateObject(wrappedValue: StatsViewModel(appState: AppState.shared))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 页面标题栏 - 运动记录/美食统计切换
            VStack {
                // 这里保留为将来可能添加的标题栏内容
            }
            .frame(height: 0) // 暂时不显示额外的标题栏
            
            // 标签页视图
            TabView {
                // 运动记录标签页
                ExerciseRecordView(viewModel: viewModel)
                    .tabItem {
                        Image(systemName: "figure.walk")
                        Text("运动记录")
                    }
                    .tag(0)
                
                // 美食记录标签页
                FoodCheckInView(viewModel: viewModel)
                    .tabItem {
                        Image(systemName: "fork.knife")
                        Text("美食记录")
                    }
                    .tag(1)
            }
            .accentColor(Color(hex: "FE2D55"))
        }
        .background(Color(UIColor.systemGray6))
        .onAppear {
            // 初始化操作（如有必要）
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
            .environmentObject(AppState.shared)
    }
} 
