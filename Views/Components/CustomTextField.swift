import SwiftUI
import UIKit

/// 基于UITextField的自定义输入框，解决SwiftUI TextField输入法加载慢的问题
struct CustomTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var keyboardType: UIKeyboardType
    var isSecureTextEntry: Bool = false
    var returnKeyType: UIReturnKeyType = .default
    var textContentType: UITextContentType?
    var onSubmit: (() -> Void)?
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.returnKeyType = returnKeyType
        textField.isSecureTextEntry = isSecureTextEntry
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        
        if let textContentType = textContentType {
            textField.textContentType = textContentType
        }
        
        // 设置样式
        textField.borderStyle = .roundedRect
        textField.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        textField.textColor = .black
        
        // 添加左侧内边距
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        // 只有在值不同时才更新，避免光标位置重置
        if uiView.text != text {
            uiView.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomTextField
        
        init(_ parent: CustomTextField) {
            self.parent = parent
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            // 使用异步方式更新绑定的文本，避免在视图更新周期内修改状态
            DispatchQueue.main.async {
                self.parent.text = textField.text ?? ""
            }
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            // 处理回车键事件
            textField.resignFirstResponder()
            parent.onSubmit?()
            return true
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomTextField(
            text: .constant(""),
            placeholder: "手机号",
            keyboardType: .phonePad,
            returnKeyType: .next
        )
        .frame(height: 50)
        .padding()
        
        CustomTextField(
            text: .constant(""),
            placeholder: "密码",
            keyboardType: .default,
            isSecureTextEntry: true,
            returnKeyType: .done
        )
        .frame(height: 50)
        .padding()
    }
    .padding()
    .background(Color.gray.opacity(0.2))
} 