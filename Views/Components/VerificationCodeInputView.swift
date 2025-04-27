import SwiftUI
import Combine

/// 验证码输入控件
struct VerificationCodeInputView: View {
    @Binding var code: String
    let numberOfDigits: Int
    @FocusState var isTextFieldFocused: Bool
    
    // 添加一个状态变量来控制键盘的显示
    @State private var isKeyboardActive = false
    
    init(code: Binding<String>, numberOfDigits: Int = 6) {
        self._code = code
        self.numberOfDigits = numberOfDigits
    }
    
    var body: some View {
        ZStack {
            // 实际的隐藏输入框
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .frame(width: 0, height: 0, alignment: .center)
                .opacity(0)
                .focused($isTextFieldFocused)
                .onChange(of: code) { oldValue, newValue in
                    // 限制输入字符数量和类型
                    let filtered = newValue.filter { "0123456789".contains($0) }
                    if filtered.count > numberOfDigits {
                        code = String(filtered.prefix(numberOfDigits))
                    } else if filtered != newValue {
                        code = filtered
                    }
                }
                .onAppear {
                    // 推迟显示键盘，让视图完全加载
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isKeyboardActive = true
                    }
                }
            
            // 显示验证码的视图
            HStack(spacing: 12) {
                ForEach(0..<numberOfDigits, id: \.self) { index in
                    digitBox(for: index)
                }
            }
            .contentShape(Rectangle())  // 整个区域可点击
            .onTapGesture {
                if isKeyboardActive {
                    activateTextFieldWithDelay()
                }
            }
        }
    }
    
    // 使用延迟激活输入框的方法，避免iOS输入法问题
    private func activateTextFieldWithDelay() {
        isTextFieldFocused = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isTextFieldFocused = true
        }
    }
    
    // 单个数字显示框
    private func digitBox(for index: Int) -> some View {
        let digit: String = index < code.count ? String(code[code.index(code.startIndex, offsetBy: index)]) : ""
        
        return ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isTextFieldFocused ? Color.blue : Color.gray, lineWidth: 1)
                .background(Color.white.opacity(0.8))
                .frame(width: 45, height: 55)
                .overlay(
                    Text(digit)
                        .font(.title2.bold())
                )
        }
        .frame(width: 45, height: 55)
    }
}

#Preview {
    VStack {
        VerificationCodeInputView(code: .constant("123"))
        VerificationCodeInputView(code: .constant(""), numberOfDigits: 4)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
} 