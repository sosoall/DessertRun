import SwiftUI
import WebKit

/// 反馈与建议页面
struct FeedbackView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var webView: WKWebView?
    
    private let feedbackURL = "https://p9uwj00wv2.feishu.cn/share/base/form/shrcnaPWQDlCY6O9ybc6w1cxsFc"
    
    var body: some View {
        NavigationView {
            ZStack {
                // WebView
                WebView(
                    urlString: feedbackURL,
                    isLoading: $isLoading,
                    webView: $webView,
                    onError: { error in
                        errorMessage = error
                        showError = true
                    }
                )
                
                // 加载指示器
                if isLoading {
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        
                        Text("正在加载反馈表单...")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 8)
                }
            }
            .navigationTitle("反馈与建议")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color(hex: "FE2D55"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("刷新") {
                        reloadPage()
                    }
                    .foregroundColor(Color(hex: "FE2D55"))
                }
            }
        }
        .alert("加载失败", isPresented: $showError) {
            Button("重试") {
                reloadPage()
            }
            Button("在浏览器中打开") {
                openInSafari()
            }
            Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("无法加载反馈表单，请尝试重新加载或在浏览器中打开。\n\n错误信息：\(errorMessage)")
        }
    }
    
    private func reloadPage() {
        isLoading = true
        showError = false
        webView?.reload()
    }
    
    private func openInSafari() {
        if let url = URL(string: feedbackURL) {
            UIApplication.shared.open(url)
        }
        presentationMode.wrappedValue.dismiss()
    }
}

/// WebView组件
struct WebView: UIViewRepresentable {
    let urlString: String
    @Binding var isLoading: Bool
    @Binding var webView: WKWebView?
    let onError: (String) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        // 创建WebView配置
        let configuration = WKWebViewConfiguration()
        
        // 配置偏好设置
        configuration.preferences.javaScriptEnabled = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        // 允许任意负载
        configuration.limitsNavigationsToAppBoundDomains = false
        
        // 创建WebView
        let webView = WKWebView(frame: .zero, configuration: configuration)
        
        // 设置导航代理
        webView.navigationDelegate = context.coordinator
        
        // 设置自定义User-Agent
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
        
        // 允许放大缩小
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true
        
        // 设置背景色
        webView.backgroundColor = UIColor.systemBackground
        webView.isOpaque = false
        
        self.webView = webView
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else {
            onError("无效的URL")
            return
        }
        
        // 只在URL变化时才重新加载
        if webView.url?.absoluteString != urlString {
            // 创建请求
            var request = URLRequest(url: url)
            request.timeoutInterval = 30
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            
            // 添加请求头
            request.addValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
            request.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
            request.addValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
            request.addValue("zh-CN,zh;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
            
            // 加载请求
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
            print("🔄 开始加载页面")
        }
        
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            print("📝 页面开始渲染")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
            print("✅ 页面加载完成")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.onError("加载失败: \(error.localizedDescription)")
            }
            print("❌ 页面加载失败: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                
                let nsError = error as NSError
                if nsError.code == NSURLErrorCancelled {
                    // 忽略取消错误，通常是用户操作导致的
                    print("⚠️ 请求被取消，忽略此错误")
                    return
                }
                
                var errorMsg = "网络连接失败"
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet:
                    errorMsg = "无网络连接，请检查网络设置"
                case NSURLErrorTimedOut:
                    errorMsg = "连接超时，请稍后重试"
                case NSURLErrorCannotFindHost:
                    errorMsg = "无法找到服务器"
                case NSURLErrorCannotConnectToHost:
                    errorMsg = "无法连接到服务器"
                case NSURLErrorNetworkConnectionLost:
                    errorMsg = "网络连接中断"
                case NSURLErrorDNSLookupFailed:
                    errorMsg = "DNS解析失败"
                case NSURLErrorHTTPTooManyRedirects:
                    errorMsg = "重定向次数过多"
                case NSURLErrorResourceUnavailable:
                    errorMsg = "资源不可用"
                case NSURLErrorBadURL:
                    errorMsg = "链接格式错误"
                default:
                    errorMsg = "加载失败: \(error.localizedDescription)"
                }
                
                self.parent.onError(errorMsg)
            }
            print("❌ 临时加载失败: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // 允许所有导航
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            // 允许所有响应
            decisionHandler(.allow)
        }
    }
}

#Preview {
    FeedbackView()
}