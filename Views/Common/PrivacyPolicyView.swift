import SwiftUI

/// 隐私政策页面，展示 Markdown 内容，可返回
struct PrivacyPolicyView: View {
    private let markdown: String = """
“该吃吃”隐私政策
更新日期：2025年6月1日
生效日期：2025年6月1日

你好，我是“该吃吃”运动健康App的运营者，我们非常注重保护用户（简称“您”）的个人信息及隐私。以下是我们的隐私声明。

1、如何收集和使用您的个人信息
我们可能会收集、保存和使用下列与您有关的信息才能实现相应的功能：
（1）账户注册及登录：手机号码、账户名称、密码
（2）创建健康档案：包含性别、身高、体重、是否有运动习惯。

2、需要开启哪些设备功能
（1）存储权限：包括图片、icon等数据，会存储在您的手机上
（2）网络权限：访问或获取WLAN和本地蜂窝网络

3、我们如何共享您的信息
我们不会共享您的任何信息

4、您的权利
您可以通过注销账号的方式删除您的个人信息，我们会从数据库中清除您的个人信息。

5、如何联系我们
如果您对本隐私协议或与个人信息相关的事宜有任何疑问、意见、建议或需要我们协助处理的事项，可在app内的“联系我们”模块给我们留言，我们会在24小时内为您处理。
"""

    var body: some View {
        ScrollView {
            Text(markdown)
                .padding()
                .multilineTextAlignment(.leading)
        }
        .navigationTitle("隐私政策")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView { PrivacyPolicyView() }
} 