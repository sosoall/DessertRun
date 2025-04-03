//
//  HealthKitExtension.swift
//  DessertRun
//
//  Created by Claude on 2025/4/3.
//

import Foundation
import HealthKit

// MARK: - HealthKit扩展

extension HKHealthStore {
    /// 请求HealthKit权限
    /// - Parameter types: 需要读取的类型数组
    /// - Returns: 是否成功授权
    static func requestAuthorization(for types: [HKQuantityType]) async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit在此设备上不可用")
            return false
        }
        
        let healthStore = HKHealthStore()
        let typesToRead = Set(types as [HKSampleType])
        
        do {
            try await healthStore.requestAuthorization(toShare: Set<HKSampleType>(), read: typesToRead)
            return true
        } catch {
            print("HealthKit授权请求失败: \(error.localizedDescription)")
            return false
        }
    }
    
    /// 查询最近的步数数据
    /// - Parameters:
    ///   - limit: 返回的数据点数量
    ///   - completion: 完成回调，返回步数数组和错误信息
    func fetchLatestStepCount(limit: Int = 7, completion: @escaping ([Double], Error?) -> Void) {
        guard let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion([], NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "步数类型不可用"]))
            return
        }
        
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -(limit - 1), to: endDate) else {
            completion([], NSError(domain: "HealthKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "日期计算错误"]))
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepCountType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: calendar.startOfDay(for: startDate),
            intervalComponents: DateComponents(day: 1)
        )
        
        query.initialResultsHandler = { _, results, error in
            if let error = error {
                completion([], error)
                return
            }
            
            guard let results = results else {
                completion([], NSError(domain: "HealthKit", code: 3, userInfo: [NSLocalizedDescriptionKey: "没有返回结果"]))
                return
            }
            
            var stepCounts: [Double] = []
            results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                if let quantity = statistics.sumQuantity() {
                    let value = quantity.doubleValue(for: HKUnit.count())
                    stepCounts.append(value)
                } else {
                    stepCounts.append(0)
                }
            }
            
            completion(stepCounts, nil)
        }
        
        self.execute(query)
    }
    
    /// 查询累计消耗的卡路里
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    ///   - completion: 完成回调，返回消耗的卡路里和错误信息
    func fetchActiveEnergyBurned(from startDate: Date, to endDate: Date, completion: @escaping (Double, Error?) -> Void) {
        guard let energyBurnedType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0, NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "能量消耗类型不可用"]))
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let query = HKStatisticsQuery(
            quantityType: energyBurnedType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            if let error = error {
                completion(0, error)
                return
            }
            
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0, nil)
                return
            }
            
            let calories = sum.doubleValue(for: HKUnit.kilocalorie())
            completion(calories, nil)
        }
        
        self.execute(query)
    }
} 