import SwiftUI

/// 环境设置视图，用于在开发和测试过程中切换环境
struct EnvironmentSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedEnvironment: Config.API.ServerEnvironment = Config.API.environment
    @State private var showSuccess = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("服务器环境选择")) {
                    ForEach(Config.API.ServerEnvironment.allCases, id: \.self) { env in
                        Button(action: {
                            selectedEnvironment = env
                        }) {
                            HStack {
                                Text(env.rawValue)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedEnvironment == env {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("当前环境信息")) {
                    HStack {
                        Text("服务器地址")
                        Spacer()
                        Text(selectedEnvironment.baseURL)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                
                Section {
                    Button(action: {
                        Config.API.environment = selectedEnvironment
                        showSuccess = true
                        
                        // 延迟关闭成功提示
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showSuccess = false
                        }
                    }) {
                        Text("保存设置")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("环境设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if showSuccess {
                    VStack {
                        Text("设置已保存")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(.easeInOut, value: showSuccess)
                }
            }
        }
    }
}

#Preview {
    EnvironmentSettingsView()
} 