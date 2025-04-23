import SwiftUI

/// 用户信息设置页面 - 首次登录时收集用户信息
struct UserInfoSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    // 步骤管理
    @State private var currentStep = 0
    
    // 用户信息
    @State private var userName = ""
    @State private var selectedGender: Gender = .other
    @State private var height: Double = 170
    @State private var weight: Double = 60
    @State private var exerciseLevel: ExerciseLevel = .beginner
    
    // 步骤标题
    private let stepTitles = ["基本信息", "身体数据", "运动习惯"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 进度指示器
                ProgressView(value: Double(currentStep), total: Double(stepTitles.count))
                    .accentColor(Color(hex: "FE2D55"))
                    .padding(.top)
                
                // 步骤标题
                Text(stepTitles[currentStep])
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "333333"))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 当前步骤内容
                ScrollView {
                    VStack(spacing: 30) {
                        switch currentStep {
                        case 0:
                            // 第一步：基本信息
                            basicInfoView
                        case 1:
                            // 第二步：身体数据
                            bodyDataView
                        case 2:
                            // 第三步：运动习惯
                            exerciseHabitView
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
                .background(Color(hex: "F8F8F8"))
                
                // 底部按钮
                bottomButtons
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(
                trailing: Button(action: {
                    // 跳过设置，使用默认值
                    saveUserInfo()
                    dismiss()
                }) {
                    Text("跳过")
                        .foregroundColor(Color(hex: "FE2D55"))
                }
            )
        }
    }
    
    // 基本信息视图
    private var basicInfoView: some View {
        VStack(spacing: 20) {
            // 昵称输入
            VStack(alignment: .leading, spacing: 8) {
                Text("昵称")
                    .font(.headline)
                    .foregroundColor(Color(hex: "333333"))
                
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
                    .font(.headline)
                    .foregroundColor(Color(hex: "333333"))
                
                HStack(spacing: 15) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        genderButton(gender)
                    }
                }
            }
        }
    }
    
    // 身体数据视图
    private var bodyDataView: some View {
        VStack(spacing: 30) {
            // 身高选择
            VStack(alignment: .leading, spacing: 8) {
                Text("身高 (cm)")
                    .font(.headline)
                    .foregroundColor(Color(hex: "333333"))
                
                HStack {
                    Slider(value: $height, in: 140...220, step: 1)
                        .accentColor(Color(hex: "FE2D55"))
                    
                    Text("\(Int(height))")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(hex: "333333"))
                        .frame(width: 50)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
            }
            
            // 体重选择
            VStack(alignment: .leading, spacing: 8) {
                Text("体重 (kg)")
                    .font(.headline)
                    .foregroundColor(Color(hex: "333333"))
                
                HStack {
                    Slider(value: $weight, in: 30...150, step: 0.5)
                        .accentColor(Color(hex: "FE2D55"))
                    
                    Text(String(format: "%.1f", weight))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(hex: "333333"))
                        .frame(width: 50)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(8)
            }
        }
    }
    
    // 运动习惯视图
    private var exerciseHabitView: some View {
        VStack(spacing: 20) {
            Text("你的运动经验如何？")
                .font(.headline)
                .foregroundColor(Color(hex: "333333"))
            
            VStack(spacing: 15) {
                ForEach(ExerciseLevel.allCases, id: \.self) { level in
                    Button(action: {
                        exerciseLevel = level
                    }) {
                        HStack {
                            Text(level.rawValue)
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "333333"))
                            
                            Spacer()
                            
                            if exerciseLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "FE2D55"))
                            } else {
                                Circle()
                                    .stroke(Color(hex: "DDDDDD"), lineWidth: 1)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                }
            }
            
            // 运动习惯解释
            VStack(alignment: .leading, spacing: 8) {
                Text("这些信息将帮助我们为你推荐合适的运动计划")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "999999"))
                
                Text("你可以随时在个人资料中更改这些信息")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "999999"))
            }
            .padding(.top, 20)
        }
    }
    
    // 底部按钮
    private var bottomButtons: some View {
        HStack(spacing: 20) {
            // 上一步按钮（仅当不是第一步时显示）
            if currentStep > 0 {
                Button(action: {
                    withAnimation {
                        currentStep -= 1
                    }
                }) {
                    Text("上一步")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "666666"))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "DDDDDD"), lineWidth: 1)
                        )
                }
            }
            
            // 下一步/完成按钮
            Button(action: {
                handleNextStep()
            }) {
                Text(currentStep == stepTitles.count - 1 ? "完成" : "下一步")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "FE2D55"))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
    }
    
    // 性别选择按钮
    private func genderButton(_ gender: Gender) -> some View {
        Button(action: {
            selectedGender = gender
        }) {
            VStack {
                Image(systemName: gender == .male ? "person.fill" : 
                              gender == .female ? "person.dress.fill" : "person")
                    .font(.system(size: 30))
                    .foregroundColor(selectedGender == gender ? Color(hex: "FE2D55") : Color(hex: "999999"))
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(selectedGender == gender ? Color(hex: "FE2D55").opacity(0.1) : Color.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(selectedGender == gender ? Color(hex: "FE2D55") : Color(hex: "DDDDDD"), lineWidth: 1)
                    )
                
                Text(gender.rawValue)
                    .font(.system(size: 14))
                    .foregroundColor(selectedGender == gender ? Color(hex: "FE2D55") : Color(hex: "333333"))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedGender == gender ? Color(hex: "FE2D55") : Color(hex: "DDDDDD"), lineWidth: 1)
            )
        }
    }
    
    // 处理下一步按钮点击
    private func handleNextStep() {
        if currentStep < stepTitles.count - 1 {
            // 还有下一步
            withAnimation {
                currentStep += 1
            }
        } else {
            // 已经是最后一步，保存信息并完成设置
            saveUserInfo()
            dismiss()
        }
    }
    
    // 保存用户信息
    private func saveUserInfo() {
        // 确保昵称不为空
        let finalName = userName.isEmpty ? "新用户\(Int.random(in: 1000...9999))" : userName
        
        // 更新用户信息
        appState.updateUserProfile(
            name: finalName,
            gender: selectedGender,
            height: height,
            weight: weight,
            exerciseLevel: exerciseLevel
        )
        
        // 记录用户已完成设置
        UserDefaults.standard.set(true, forKey: "hasCompletedUserSetup")
        
        // 记录最后一次更新时间
        UserDefaults.standard.set(Date(), forKey: "lastProfileUpdateTime")
        
        // 打印调试信息
        print("【调试】用户信息已保存：\(finalName), 性别: \(selectedGender.rawValue), 身高: \(Int(height))cm, 体重: \(String(format: "%.1f", weight))kg, 运动习惯: \(exerciseLevel.rawValue)")
    }
}

#Preview {
    UserInfoSetupView()
        .environmentObject(AppState.shared)
} 