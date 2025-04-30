import Foundation

/// API端点
enum ApiEndpoints {
    // 认证相关
    struct Auth {
        static let base = "/api/v1/auth"
        static let login = base + "/login"
        static let loginPassword = base + "/login-password"
        static let register = base + "/register"
        static let verificationCode = base + "/verification-code"
        static let refreshToken = base + "/refresh-token"
    }
    
    // 用户相关
    struct User {
        static let base = "/api/v1/users"
        static let profile = base + "/profile"
        static let updateProfile = base + "/profile"
    }
    
    // 甜品相关
    struct Dessert {
        static let base = "/api/v1/desserts"
        static let list = base
        static let detail = base + "/"  // 需要附加ID: detail + "{id}"
    }
    
    // 运动相关
    struct Exercise {
        static let base = "/api/v1/exercises"
        static let types = base + "/types"  // 获取所有运动类型
        static let calculateTime = base + "/calculate/time"
        static let calculateDistance = base + "/calculate/distance"
        static let calculateCalories = base + "/calculate/calories"
        static let records = base + "/records"
    }
    
    // 运动记录相关
    struct Workout {
        static let base = "/api/v1/workouts"
        static let records = base + "/records"
        static let createRecord = records
        static let updateRecord = records + "/"  // 需要附加ID: updateRecord + "{id}"
        static let deleteRecord = records + "/"  // 需要附加ID: deleteRecord + "{id}"
    }
    
    // 积分和兑换相关
    struct Points {
        static let base = "/api/v1/points"
        static let balance = base + "/balance"
        static let history = base + "/history"
        static let redeem = base + "/redeem"
    }
} 