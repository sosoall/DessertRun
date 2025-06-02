import Foundation

// MARK: - 地区数据模型
struct RegionData: Codable {
    let code: String
    let text: String
    let children: [RegionData]
}

// MARK: - 地区数据管理器
class RegionDataManager: ObservableObject {
    static let shared = RegionDataManager()
    
    private var regions: [RegionData] = []
    @Published var isLoaded = false
    
    private init() {
        loadRegionData()
    }
    
    // 加载地区数据
    private func loadRegionData() {
        guard let path = Bundle.main.path(forResource: "region_tree_date", ofType: "json"),
              let data = NSData(contentsOfFile: path) as Data? else {
            print("无法加载地区数据文件")
            return
        }
        
        do {
            regions = try JSONDecoder().decode([RegionData].self, from: data)
            print("成功加载地区数据，共\(regions.count)个省份")
            isLoaded = true
        } catch {
            print("解析地区数据失败: \(error)")
        }
    }
    
    // 获取所有省份
    func getProvinces() -> [RegionData] {
        return regions
    }
    
    // 根据省份代码获取城市
    func getCities(for provinceCode: String) -> [RegionData] {
        guard let province = regions.first(where: { $0.code == provinceCode }) else {
            return []
        }
        return province.children
    }
    
    // 根据城市代码获取区县
    func getDistricts(for provinceCode: String, cityCode: String) -> [RegionData] {
        guard let province = regions.first(where: { $0.code == provinceCode }),
              let city = province.children.first(where: { $0.code == cityCode }) else {
            return []
        }
        return city.children
    }
    
    // 根据代码获取名称
    func getRegionName(for code: String) -> String {
        if let province = regions.first(where: { $0.code == code }) {
            return province.text
        }
        
        for province in regions {
            if let city = province.children.first(where: { $0.code == code }) {
                return city.text
            }
            
            for city in province.children {
                if let district = city.children.first(where: { $0.code == code }) {
                    return district.text
                }
            }
        }
        
        return ""
    }
} 