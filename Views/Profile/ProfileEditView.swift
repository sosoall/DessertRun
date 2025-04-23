import SwiftUI

/// 用户资料编辑页面
struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    // 用户信息
    @State private var userName: String
    @State private var selectedGender: Gender
    @State private var height: Double
    @State private var weight: Double
    @State private var exerciseLevel: ExerciseLevel
    
    // 是否显示保存确认
    @State private var showingSaveConfirmation = false
    
    // 初始化，获取当前用户信息
    init() {
        _userName = State(initialValue: AppState.shared.userProfile.name)
        _selectedGender = State(initialValue: AppState.shared.userProfile.gender)
        _height = State(initialValue: AppState.shared.userProfile.height ?? 170)
        _weight = State(initialValue: AppState.shared.userProfile.weight ?? 60)
        _exerciseLevel = State(initialValue: AppState.shared.userProfile.exerciseLevel)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 头像部分
                avatarSection
                
                // 基本信息卡片
                basicInfoCard
                
                // 身体数据卡片
                bodyDataCard
                
                // 运动习惯卡片
                exerciseHabitCard
                
                // 保存按钮
                Button(action: {
                    saveUserInfo()
                }) {
                    Text("保存")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "FE2D55"))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGray6))
        .navigationTitle("编辑个人资料")
        .navigationBarTitleDisplayMode(.inline)
        .alert("保存成功", isPresented: $showingSaveConfirmation) {
            Button("确定", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("个人资料已更新")
        }
    }
    
    // 头像部分
    private var avatarSection: some View {
        VStack {
            Image(systemName: appState.userProfile.avatarName)
                .font(.system(size: 80))
                .foregroundColor(Color(hex: "FE2D55"))
                .frame(width: 120, height: 120)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                )
                .overlay(
                    Circle()
                        .fill(Color(hex: "FE2D55"))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1),
                    alignment: .bottomTrailing
                )
            
            Text("点击更换头像")
                .font(.caption)
                .foregroundColor(Color.gray)
                .padding(.top, 4)
        }
        .padding(.bottom, 16)
    }
    
    // 基本信息卡片
    private var basicInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("基本信息")
                .font(.headline)
                .foregroundColor(Color(hex: "333333"))
            
            // 昵称输入
            VStack(alignment: .leading, spacing: 8) {
                Text("昵称")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "666666"))
                
                TextField("请输入昵称", text: $userName)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "DDDDDD"), lineWidth: 1)
                    )
            }
            
            // 性别选择
            VStack(alignment: .leading, spacing: 8) {
                Text("性别")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "666666"))
                
                HStack(spacing: 12) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        Button(action: {
                            selectedGender = gender
                        }) {
                            HStack {
                                Text(gender.rawValue)
                                    .font(.system(size: 16))
                                    .foregroundColor(selectedGender == gender ? Color(hex: "FE2D55") : Color(hex: "333333"))
                                
                                Spacer()
                                
                                if selectedGender == gender {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color(hex: "FE2D55"))
                                } else {
                                    Circle()
                                        .stroke(Color(hex: "CCCCCC"), lineWidth: 1)
                                        .frame(width: 20, height: 20)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedGender == gender ? Color(hex: "FE2D55") : Color(hex: "EEEEEE"), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // 身体数据卡片
    private var bodyDataCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("身体数据")
                .font(.headline)
                .foregroundColor(Color(hex: "333333"))
            
            // 身高选择
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("身高")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "666666"))
                    
                    Spacer()
                    
                    Text("\(Int(height)) cm")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "333333"))
                }
                
                Slider(value: $height, in: 140...220, step: 1)
                    .accentColor(Color(hex: "FE2D55"))
            }
            
            Divider()
            
            // 体重选择
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("体重")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "666666"))
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", weight)) kg")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "333333"))
                }
                
                Slider(value: $weight, in: 30...150, step: 0.5)
                    .accentColor(Color(hex: "FE2D55"))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // 运动习惯卡片
    private var exerciseHabitCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("运动习惯")
                .font(.headline)
                .foregroundColor(Color(hex: "333333"))
            
            ForEach(ExerciseLevel.allCases, id: \.self) { level in
                Button(action: {
                    exerciseLevel = level
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(level.rawValue)
                                .font(.system(size: 16))
                                .foregroundColor(exerciseLevel == level ? Color(hex: "FE2D55") : Color(hex: "333333"))
                            
                            Text(getExerciseLevelDescription(level))
                                .font(.caption)
                                .foregroundColor(Color(hex: "999999"))
                        }
                        
                        Spacer()
                        
                        if exerciseLevel == level {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color(hex: "FE2D55"))
                        } else {
                            Circle()
                                .stroke(Color(hex: "CCCCCC"), lineWidth: 1)
                                .frame(width: 20, height: 20)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(exerciseLevel == level ? Color(hex: "FE2D55") : Color(hex: "EEEEEE"), lineWidth: 1)
                    )
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // 获取运动级别描述
    private func getExerciseLevelDescription(_ level: ExerciseLevel) -> String {
        switch level {
        case .beginner:
            return "很少运动，希望培养运动习惯"
        case .intermediate:
            return "偶尔运动，对运动有一定了解"
        case .advanced:
            return "经常运动，寻求更高强度的训练"
        }
    }
    
    // 保存用户信息
    private func saveUserInfo() {
        // 确保昵称不为空
        guard !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        // 更新用户信息
        appState.updateUserProfile(
            name: userName,
            gender: selectedGender,
            height: height,
            weight: weight,
            exerciseLevel: exerciseLevel
        )
        
        // 显示保存成功提示
        showingSaveConfirmation = true
    }
}

#Preview {
    NavigationView {
        ProfileEditView()
            .environmentObject(AppState.shared)
    }
} 