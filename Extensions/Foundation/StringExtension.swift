//
//  StringExtension.swift
//  DessertRun
//
//  Created by Claude on 2025/4/3.
//

import Foundation

// MARK: - 字符串扩展

extension String {
    /// 从字符串中提取数字
    var extractedNumbers: Double? {
        let pattern = "[0-9]+(\\.[0-9]+)?"
        let regex = try? NSRegularExpression(pattern: pattern)
        if let match = regex?.firstMatch(in: self, range: NSRange(location: 0, length: self.count)) {
            if let range = Range(match.range, in: self) {
                return Double(self[range])
            }
        }
        return nil
    }
    
    /// 是否包含给定的子字符串，不区分大小写
    /// - Parameter string: 要查找的子字符串
    /// - Returns: 是否包含
    func containsIgnoringCase(_ string: String) -> Bool {
        return self.lowercased().contains(string.lowercased())
    }
    
    /// 裁剪首尾空白字符
    var trimmed: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// 是否为有效的邮箱地址
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
} 