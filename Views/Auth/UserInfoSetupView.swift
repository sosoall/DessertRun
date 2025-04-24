import SwiftUI

/// 用户信息设置页面 - 新用户注册后的信息收集
struct UserInfoSetupView: View {
    @StateObject private var authService = AuthService.shared
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var nickname = ""
    @State private var selectedGender: User.Gender?
    @State private var height: Double = 170.0
    @State private var weight: Double = 60.0
    @State private var hasExerciseHabit: Bool?
    @State private var showingSuccessAlert = false
    @State private var navigateToMainView = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景颜色
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 步骤进度显示
                    ProgressView(value: Double(currentStep), total: 3)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: "FE2D55")))
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // 当前步骤内容
                    ScrollView {
                        VStack(spacing: 20) {
                            stepTitle
                            
                            switch currentStep {
                            case 0:
                                basicInfoStep
                            case 1:
                                bodyInfoStep
                            case 2:
                                exerciseHabitStep
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 30)
                    }
                    
                    // 底部按钮区域
                    bottomButtons
                }
            }
            .navigationTitle("个人信息")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("跳过") {
                        // 跳过操作，将当前信息保存并返回
                        saveCurrentInfo()
                        navigateToMainView = true
                    }
                }
            }
            .alert("设置完成", isPresented: $showingSuccessAlert) {
                Button("开始使用", role: .cancel) {
                    navigateToMainView = true
                }
            } message: {
                Text("个人信息设置已完成，开始享受DessertRun的美好体验吧！")
            }
            .fullScreenCover(isPresented: $navigateToMainView) {
                MainTabView()
            }
        }
    }
    
    // MARK: - 步骤标题
    private var stepTitle: some View {
        Text(stepTitleText)
            .font(.system(size: 22, weight: .bold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 20)
    }
    
    private var stepTitleText: String {
        switch currentStep {
        case 0:
            return "基本信息"
        case 1:
            return "身体数据"
        case 2:
            return "运动习惯"
        default:
            return ""
        }
    }
    
    // MARK: - 第一步：基本信息
    private var basicInfoStep: some View {
        VStack(spacing: 30) {
            // 昵称输入
            VStack(alignment: .leading, spacing: 8) {
                Text("昵称")
                    .font(.headline)
                
                TextField("请输入您的昵称", text: $nickname)
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
            }
            
            // 性别选择
            VStack(alignment: .leading, spacing: 15) {
                Text("性别")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    genderButton(.male)
                    genderButton(.female)
                }
            }
            
            Text("基本信息将帮助我们为您提供更准确的运动推荐")
                .font(.footnote)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
        }
    }
    
    // 性别选择按钮
    private func genderButton(_ gender: User.Gender) -> some View {
        Button(action: {
            selectedGender = gender
        }) {
            VStack {
                Image(systemName: gender == .male ? "person" : "person.fill")
                    .font(.system(size: 30))
                    .foregroundColor(selectedGender == gender ? Color(hex: "FE2D55") : .gray)
                    .padding()
                    .background(
                        Circle()
                            .fill(selectedGender == gender ? Color(hex: "FE2D55").opacity(0.1) : Color(UIColor.systemGray6))
                            .frame(width: 70, height: 70)
                    )
                
                Text(gender.rawValue)
                    .font(.system(size: 16, weight: selectedGender == gender ? .medium : .regular))
                    .foregroundColor(selectedGender == gender ? Color(hex: "FE2D55") : .gray)
                    .padding(.top, 8)
            }
        }
    }
    
    // MARK: - 第二步：身体数据
    private var bodyInfoStep: some View {
        VStack(spacing: 30) {
            // 身高设置
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("身高")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(Int(height)) cm")
                        .font(.headline)
                        .foregroundColor(Color(hex: "FE2D55"))
                }
                
                Slider(value: $height, in: 100...220, step: 1)
                    .accentColor(Color(hex: "FE2D55"))
                
                HStack {
                    Text("100cm")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("220cm")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // 体重设置
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("体重")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(Int(weight)) kg")
                        .font(.headline)
                        .foregroundColor(Color(hex: "FE2D55"))
                }
                
                Slider(value: $weight, in: 30...150, step: 1)
                    .accentColor(Color(hex: "FE2D55"))
                
                HStack {
                    Text("30kg")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("150kg")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Text("您的身体数据仅用于运动消耗计算，不会泄露或用于其他用途")
                .font(.footnote)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
        }
    }
    
    // MARK: - 第三步：运动习惯
    private var exerciseHabitStep: some View {
        VStack(spacing: 30) {
            Text("您是否有常规的运动习惯？")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 运动习惯选择
            HStack(spacing: 20) {
                // 有运动习惯按钮
                Button(action: {
                    hasExerciseHabit = true
                }) {
                    VStack(spacing: 15) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 30))
                            .foregroundColor(hasExerciseHabit == true ? Color(hex: "FE2D55") : .gray)
                            .padding()
                            .background(
                                Circle()
                                    .fill(hasExerciseHabit == true ? Color(hex: "FE2D55").opacity(0.1) : Color(UIColor.systemGray6))
                                    .frame(width: 80, height: 80)
                            )
                        
                        Text("是的，我经常运动")
                            .font(.system(size: 14))
                            .foregroundColor(hasExerciseHabit == true ? Color(hex: "FE2D55") : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(hasExerciseHabit == true ? Color(hex: "FE2D55").opacity(0.05) : Color(UIColor.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(hasExerciseHabit == true ? Color(hex: "FE2D55") : Color.clear, lineWidth: 1)
                            )
                    )
                }
                
                // 无运动习惯按钮
                Button(action: {
                    hasExerciseHabit = false
                }) {
                    VStack(spacing: 15) {
                        Image(systemName: "bed.double")
                            .font(.system(size: 30))
                            .foregroundColor(hasExerciseHabit == false ? Color(hex: "FE2D55") : .gray)
                            .padding()
                            .background(
                                Circle()
                                    .fill(hasExerciseHabit == false ? Color(hex: "FE2D55").opacity(0.1) : Color(UIColor.systemGray6))
                                    .frame(width: 80, height: 80)
                            )
                        
                        Text("不，我很少运动")
                            .font(.system(size: 14))
                            .foregroundColor(hasExerciseHabit == false ? Color(hex: "FE2D55") : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(hasExerciseHabit == false ? Color(hex: "FE2D55").opacity(0.05) : Color(UIColor.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(hasExerciseHabit == false ? Color(hex: "FE2D55") : Color.clear, lineWidth: 1)
                            )
                    )
                }
            }
            
            Text("这将帮助我们为您定制合适的运动计划")
                .font(.footnote)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
        }
    }
    
    // MARK: - 底部按钮
    private var bottomButtons: some View {
        VStack(spacing: 10) {
            // 主要操作按钮（下一步或完成）
            Button(action: {
                handleMainButtonAction()
            }) {
                Text(currentStep < 2 ? "下一步" : "完成")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(isCurrentStepValid ? Color(hex: "FE2D55") : Color.gray)
                    )
                    .padding(.horizontal, 30)
            }
            .disabled(!isCurrentStepValid)
            
            // 上一步按钮（不是第一步时显示）
            if currentStep > 0 {
                Button(action: {
                    withAnimation {
                        currentStep -= 1
                    }
                }) {
                    Text("上一步")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "FE2D55"))
                        .padding(.vertical, 10)
                }
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - 辅助方法
    
    /// 当前步骤是否有效
    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 0:
            return !nickname.isEmpty && selectedGender != nil
        case 1:
            return true // 身高体重已经有默认值
        case 2:
            return hasExerciseHabit != nil
        default:
            return false
        }
    }
    
    /// 处理主按钮操作
    private func handleMainButtonAction() {
        if currentStep < 2 {
            // 保存当前步骤信息
            saveCurrentStepInfo()
            
            // 进入下一步
            withAnimation {
                currentStep += 1
            }
        } else {
            // 完成所有步骤，保存信息
            saveCurrentInfo()
            showSetupComplete()
        }
    }
    
    /// 保存当前步骤信息
    private func saveCurrentStepInfo() {
        switch currentStep {
        case 0:
            authService.updateUserProfile(nickname: nickname, gender: selectedGender)
        case 1:
            authService.updateUserProfile(height: height, weight: weight)
        case 2:
            authService.updateUserProfile(hasExerciseHabit: hasExerciseHabit)
        default:
            break
        }
    }
    
    /// 保存所有当前信息
    private func saveCurrentInfo() {
        authService.updateUserProfile(
            nickname: nickname.isEmpty ? "用户\(Int.random(in: 1000...9999))" : nickname,
            gender: selectedGender,
            height: height,
            weight: weight,
            hasExerciseHabit: hasExerciseHabit
        )
    }
    
    /// 显示设置完成提示
    private func showSetupComplete() {
        // 更新全局应用状态
        appState.updateLoginStatus()
        showingSuccessAlert = true
    }
}

#Preview {
    UserInfoSetupView()
} 