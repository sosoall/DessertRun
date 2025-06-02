import SwiftUI

/// 地址编辑页面
struct AddressEditView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var recipientName: String
    @Binding var phoneNumber: String
    @Binding var province: String
    @Binding var city: String
    @Binding var district: String
    @Binding var detailAddress: String
    
    let onSave: () -> Void
    
    @StateObject private var regionManager = RegionDataManager.shared
    @State private var showRegionPicker = false
    @State private var provinceCode = ""
    @State private var cityCode = ""
    @State private var districtCode = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 导航栏
                headerView
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 联系人信息
                        inputSection(title: "联系人信息") {
                            VStack(spacing: 16) {
                                inputField(title: "收货人", placeholder: "请输入收货人姓名", text: $recipientName)
                                inputField(title: "手机号", placeholder: "请输入手机号码", text: $phoneNumber)
                                    .keyboardType(.phonePad)
                            }
                        }
                        
                        // 地址信息
                        inputSection(title: "地址信息") {
                            VStack(spacing: 16) {
                                // 地区选择按钮
                                regionSelectionButton
                                
                                inputField(title: "详细地址", placeholder: "请输入详细地址", text: $detailAddress)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
                .background(Color(hex: "F8F9FA"))
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showRegionPicker) {
            RegionPickerView(
                selectedProvince: $province,
                selectedCity: $city,
                selectedDistrict: $district,
                selectedProvinceCode: $provinceCode,
                selectedCityCode: $cityCode,
                selectedDistrictCode: $districtCode
            )
        }
        .onAppear {
            loadRegionData()
        }
    }
    
    // MARK: - 视图组件
    
    /// 头部导航栏
    private var headerView: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("编辑地址")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
            
            Spacer()
            
            Button("保存") {
                onSave()
                presentationMode.wrappedValue.dismiss()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color(hex: "FE2D55"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(hex: "E5E5E5")),
            alignment: .bottom
        )
    }
    
    /// 输入区域
    private func inputSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
            
            VStack(spacing: 1) {
                content()
            }
            .background(Color.white)
            .cornerRadius(12)
        }
    }
    
    /// 输入框
    private func inputField(title: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.black)
                .frame(width: 70, alignment: .leading)
            
            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .foregroundColor(.black)
                .placeholder(when: text.wrappedValue.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(Color(hex: "B3B3B3"))
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
    }
    
    /// 地区选择按钮
    private var regionSelectionButton: some View {
        Button(action: {
            showRegionPicker = true
        }) {
            HStack(spacing: 12) {
                Text("所在地区")
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                    .frame(width: 70, alignment: .leading)
                
                if province.isEmpty && city.isEmpty && district.isEmpty {
                    Text("请选择省市区")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "B3B3B3"))
                } else {
                    Text("\(province) \(city) \(district)")
                        .font(.system(size: 15))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "B3B3B3"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
        }
    }
    
    // MARK: - 方法
    
    /// 加载地区数据
    private func loadRegionData() {
        // 如果已经有地区信息，尝试加载对应的代码
        if !province.isEmpty && !city.isEmpty && !district.isEmpty {
            // 这里可以根据地区名称反向查找代码
            // 暂时保持为空，等待用户重新选择
        }
    }
}

// MARK: - 扩展

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    AddressEditView(
        recipientName: .constant(""),
        phoneNumber: .constant(""),
        province: .constant(""),
        city: .constant(""),
        district: .constant(""),
        detailAddress: .constant(""),
        onSave: {}
    )
} 