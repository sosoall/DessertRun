import SwiftUI

struct WorkoutCheckInView: View {
    // 环境属性
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    
    // 状态属性
    @StateObject private var exerciseImagePicker = ImagePickerManager()
    @StateObject private var dessertImagePicker = ImagePickerManager()
    @State private var durationInMinutes: Double = 30
    @State private var notes: String = ""
    @State private var showingSuccessAlert = false
    
    // 计算属性
    var caloriesBurned: Double {
        guard let exerciseType = appState.selectedExerciseType,
              let dessert = appState.selectedDessert else {
            return 0
        }
        
        // 简单计算: 时间(分钟) * 每分钟消耗的卡路里
        return durationInMinutes * exerciseType.caloriesPerMinute
    }
    
    var canSubmit: Bool {
        return exerciseImagePicker.selectedImage != nil && durationInMinutes > 0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 标题
                Text("运动打卡")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // 甜品和运动信息摘要
                summarySection
                
                // 运动时长选择
                durationSection
                
                // 运动截图上传
                exerciseImageSection
                
                // 美食照片上传（可选）
                dessertImageSection
                
                // 备注（可选）
                notesSection
                
                // 完成按钮
                Button(action: submitWorkout) {
                    Text("完成打卡")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSubmit ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!canSubmit)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .padding(.horizontal)
        }
        .navigationBarTitle("运动打卡", displayMode: .inline)
        .navigationBarItems(leading: Button("取消") {
            presentationMode.wrappedValue.dismiss()
        })
        .sheet(isPresented: $exerciseImagePicker.isImagePickerPresented) {
            ImagePickerView(
                selectedImage: $exerciseImagePicker.selectedImage,
                isPresented: $exerciseImagePicker.isImagePickerPresented,
                sourceType: exerciseImagePicker.sourceType
            )
        }
        .sheet(isPresented: $dessertImagePicker.isImagePickerPresented) {
            ImagePickerView(
                selectedImage: $dessertImagePicker.selectedImage,
                isPresented: $dessertImagePicker.isImagePickerPresented,
                sourceType: dessertImagePicker.sourceType
            )
        }
        .alert(isPresented: $showingSuccessAlert) {
            Alert(
                title: Text("打卡成功"),
                message: Text("你的运动记录已保存"),
                dismissButton: .default(Text("确定")) {
                    // 关闭当前页面，返回主页
                    presentationMode.wrappedValue.dismiss()
                    
                    // 重置运动状态
                    appState.resetWorkoutState()
                    
                    // 切换到统计标签页
                    appState.selectedTabIndex = 1
                }
            )
        }
    }
    
    // MARK: - 子视图
    
    // 甜品和运动信息摘要
    var summarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("运动信息摘要")
                .font(.headline)
            
            HStack(spacing: 15) {
                // 甜品图片
                if let dessert = appState.selectedDessert {
                    Image(dessert.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .cornerRadius(10)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    // 甜品名称
                    if let dessert = appState.selectedDessert {
                        Text(dessert.name)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("\(Int(dessert.calories))卡路里")
                            .foregroundColor(.secondary)
                    }
                    
                    // 运动类型
                    if let exerciseType = appState.selectedExerciseType {
                        Text("运动方式: \(exerciseType.name)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
    
    // 运动时长选择
    var durationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("运动时长（分钟）")
                .font(.headline)
            
            HStack {
                Text("\(Int(durationInMinutes))")
                    .font(.title)
                    .fontWeight(.bold)
                    .frame(width: 60, alignment: .center)
                
                Slider(value: $durationInMinutes, in: 5...240, step: 5)
                    .accentColor(.blue)
            }
            
            HStack {
                Button("15分钟") { durationInMinutes = 15 }
                    .buttonStyle(SmallButtonStyle())
                
                Button("30分钟") { durationInMinutes = 30 }
                    .buttonStyle(SmallButtonStyle())
                
                Button("45分钟") { durationInMinutes = 45 }
                    .buttonStyle(SmallButtonStyle())
                
                Button("60分钟") { durationInMinutes = 60 }
                    .buttonStyle(SmallButtonStyle())
            }
            
            Text("预计消耗: \(Int(caloriesBurned)) 卡路里")
                .foregroundColor(.secondary)
                .padding(.top, 5)
        }
        .padding(.horizontal)
    }
    
    // 运动截图上传
    var exerciseImageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("运动截图（必填）")
                .font(.headline)
            
            if let image = exerciseImagePicker.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(10)
                
                Button("重新选择") {
                    presentImageSourceActionSheet(for: .exercise)
                }
                .foregroundColor(.blue)
            } else {
                Button(action: {
                    presentImageSourceActionSheet(for: .exercise)
                }) {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.largeTitle)
                            .padding()
                        
                        Text("上传运动截图")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // 美食照片上传（可选）
    var dessertImageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("美食照片（可选）")
                .font(.headline)
            
            if let image = dessertImagePicker.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(10)
                
                Button("重新选择") {
                    presentImageSourceActionSheet(for: .dessert)
                }
                .foregroundColor(.blue)
            } else {
                Button(action: {
                    presentImageSourceActionSheet(for: .dessert)
                }) {
                    VStack {
                        Image(systemName: "photo.fill")
                            .font(.largeTitle)
                            .padding()
                        
                        Text("上传美食照片")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // 备注（可选）
    var notesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("备注（可选）")
                .font(.headline)
            
            TextEditor(text: $notes)
                .frame(height: 100)
                .padding(4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }
    
    // MARK: - 方法
    
    // 图片源类型
    enum ImageSourceType {
        case exercise
        case dessert
    }
    
    // 显示图片源选择菜单
    func presentImageSourceActionSheet(for source: ImageSourceType) {
        let manager = source == .exercise ? exerciseImagePicker : dessertImagePicker
        
        #if targetEnvironment(simulator)
        // 模拟器中只能使用相册
        manager.selectImageFromLibrary()
        #else
        // 真机中可以使用相册或相机
        let actionSheet = UIAlertController(title: "选择图片来源", message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "相册", style: .default) { _ in
            manager.selectImageFromLibrary()
        })
        
        actionSheet.addAction(UIAlertAction(title: "相机", style: .default) { _ in
            manager.takePhoto()
        })
        
        actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        
        UIApplication.shared.windows.first?.rootViewController?.present(actionSheet, animated: true, completion: nil)
        #endif
    }
    
    // 提交运动记录
    func submitWorkout() {
        guard let dessert = appState.selectedDessert,
              let exerciseType = appState.selectedExerciseType else {
            return
        }
        
        // 创建运动记录
        var record = WorkoutRecord(
            dessert: dessert,
            exerciseType: exerciseType,
            duration: durationInMinutes,
            caloriesBurned: caloriesBurned
        )
        
        // 上传运动截图
        exerciseImagePicker.saveOrUploadImage { url in
            if let url = url {
                record.exerciseImageURL = url
                
                // 上传美食照片（如果有）
                if let _ = dessertImagePicker.selectedImage {
                    dessertImagePicker.saveOrUploadImage { dessertURL in
                        record.dessertImageURL = dessertURL
                        
                        // 添加备注（如果有）
                        record.notes = notes.isEmpty ? nil : notes
                        
                        // 添加记录到应用状态
                        appState.addWorkoutRecord(record)
                        
                        // 显示成功提示
                        showingSuccessAlert = true
                    }
                } else {
                    // 只有运动截图，没有美食照片
                    record.notes = notes.isEmpty ? nil : notes
                    appState.addWorkoutRecord(record)
                    showingSuccessAlert = true
                }
            }
        }
    }
}

// MARK: - 辅助视图

// 小型按钮样式
struct SmallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(configuration.isPressed ? Color.blue.opacity(0.7) : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(5)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - 预览

struct WorkoutCheckInView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState.shared
        appState.selectedDessert = DessertData.getSampleDesserts().first
        appState.selectedExerciseType = ExerciseType.walking
        
        return NavigationView {
            WorkoutCheckInView()
                .environmentObject(appState)
        }
    }
} 