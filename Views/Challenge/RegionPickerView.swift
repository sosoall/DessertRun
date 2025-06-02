import SwiftUI

/// 地区选择器视图
struct RegionPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var selectedProvince: String
    @Binding var selectedCity: String
    @Binding var selectedDistrict: String
    @Binding var selectedProvinceCode: String
    @Binding var selectedCityCode: String
    @Binding var selectedDistrictCode: String
    
    @StateObject private var regionManager = RegionDataManager.shared
    @State private var provinces: [RegionData] = []
    @State private var cities: [RegionData] = []
    @State private var districts: [RegionData] = []
    
    @State private var selectedProvinceIndex = 0
    @State private var selectedCityIndex = 0
    @State private var selectedDistrictIndex = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 导航栏
            headerView
            
            // 地区选择器
            regionPickerView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(hex: "F8F9FA"))
        .onAppear {
            loadRegionData()
        }
    }
    
    // MARK: - 视图组件
    
    /// 头部导航栏
    private var headerView: some View {
        HStack {
            Button("取消") {
                presentationMode.wrappedValue.dismiss()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.gray)
            
            Spacer()
            
            Text("选择地区")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
            
            Spacer()
            
            Button("确定") {
                confirmSelection()
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
    
    /// 地区选择器主体
    private var regionPickerView: some View {
        VStack(spacing: 0) {
            // 选择器标题
            HStack {
                Text("省份")
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                Text("城市")
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                
                Text("区县")
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white)
            
            // 选择器滚轮
            HStack(spacing: 0) {
                // 省份选择器
                Picker("省份", selection: $selectedProvinceIndex) {
                    ForEach(0..<provinces.count, id: \.self) { index in
                        Text(provinces[index].text)
                            .font(.system(size: 16))
                            .tag(index)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(maxWidth: .infinity)
                .onChange(of: selectedProvinceIndex) { newValue in
                    updateCitiesForProvince(at: newValue)
                }
                
                // 城市选择器
                Picker("城市", selection: $selectedCityIndex) {
                    ForEach(0..<cities.count, id: \.self) { index in
                        Text(cities[index].text)
                            .font(.system(size: 16))
                            .tag(index)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(maxWidth: .infinity)
                .onChange(of: selectedCityIndex) { newValue in
                    updateDistrictsForCity(at: newValue)
                }
                
                // 区县选择器
                Picker("区县", selection: $selectedDistrictIndex) {
                    ForEach(0..<districts.count, id: \.self) { index in
                        Text(districts[index].text)
                            .font(.system(size: 16))
                            .tag(index)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .frame(maxWidth: .infinity)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
            .frame(maxHeight: .infinity)
        }
    }
    
    // MARK: - 方法
    
    /// 加载地区数据
    private func loadRegionData() {
        if regionManager.isLoaded {
            setupInitialData()
        } else {
            // 等待数据加载完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if regionManager.isLoaded {
                    setupInitialData()
                }
            }
        }
    }
    
    /// 设置初始数据
    private func setupInitialData() {
        provinces = regionManager.getProvinces()
        
        if !provinces.isEmpty {
            // 如果有预选的省份，尝试匹配
            if !selectedProvince.isEmpty {
                if let index = provinces.firstIndex(where: { $0.text == selectedProvince }) {
                    selectedProvinceIndex = index
                }
            }
            
            updateCitiesForProvince(at: selectedProvinceIndex)
        }
    }
    
    /// 更新城市列表
    private func updateCitiesForProvince(at index: Int) {
        guard index < provinces.count else { return }
        
        let province = provinces[index]
        cities = province.children
        selectedCityIndex = 0
        
        // 如果有预选的城市，尝试匹配
        if !selectedCity.isEmpty && province.text == selectedProvince {
            if let cityIndex = cities.firstIndex(where: { $0.text == selectedCity }) {
                selectedCityIndex = cityIndex
            }
        }
        
        if !cities.isEmpty {
            updateDistrictsForCity(at: selectedCityIndex)
        } else {
            districts = []
            selectedDistrictIndex = 0
        }
    }
    
    /// 更新区县列表
    private func updateDistrictsForCity(at index: Int) {
        guard index < cities.count else { return }
        
        let city = cities[index]
        districts = city.children
        selectedDistrictIndex = 0
        
        // 如果有预选的区县，尝试匹配
        if !selectedDistrict.isEmpty && city.text == selectedCity {
            if let districtIndex = districts.firstIndex(where: { $0.text == selectedDistrict }) {
                selectedDistrictIndex = districtIndex
            }
        }
    }
    
    /// 确认选择
    private func confirmSelection() {
        guard selectedProvinceIndex < provinces.count,
              selectedCityIndex < cities.count,
              selectedDistrictIndex < districts.count else {
            return
        }
        
        let province = provinces[selectedProvinceIndex]
        let city = cities[selectedCityIndex]
        let district = districts[selectedDistrictIndex]
        
        selectedProvince = province.text
        selectedCity = city.text
        selectedDistrict = district.text
        
        selectedProvinceCode = province.code
        selectedCityCode = city.code
        selectedDistrictCode = district.code
        
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    RegionPickerView(
        selectedProvince: .constant(""),
        selectedCity: .constant(""),
        selectedDistrict: .constant(""),
        selectedProvinceCode: .constant(""),
        selectedCityCode: .constant(""),
        selectedDistrictCode: .constant("")
    )
} 