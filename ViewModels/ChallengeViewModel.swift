import Foundation
import Combine
import SwiftUI

/// 挑战活动视图模型
class ChallengeViewModel: ObservableObject {
    // 全局应用状态
    private let appState: AppState
    
    // 挑战服务
    private let challengeService = ChallengeService.shared
    
    // 取消令牌
    private var cancellables = Set<AnyCancellable>()
    
    // 发布者
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var challengeActivities: [ChallengeActivity] = []
    @Published var filteredActivities: [ChallengeActivity] = []
    @Published var enrolledChallenges: [EnrollmentWithChallenge] = []
    @Published var selectedChallenge: ChallengeActivity? = nil
    @Published var selectedEnrollment: ChallengeEnrollment? = nil
    @Published var progressResponse: ChallengeProgressResponse? = nil
    
    // 筛选条件
    @Published var selectedActivityType: String = "all" // "all", "free", "paid"
    
    // 初始化
    init(appState: AppState) {
        self.appState = appState
        
        // 监听筛选条件变化
        $selectedActivityType
            .sink { [weak self] type in
                self?.filterActivities(by: type)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 数据加载
    
    /// 加载挑战活动列表
    func loadChallenges() {
        // 避免重复加载，减轻服务器压力
        if isLoading || 
           (!challengeActivities.isEmpty && 
            appState.lastChallengeLoadTime != nil && 
            Date().timeIntervalSince(appState.lastChallengeLoadTime!) < 30) {
            // 如果已有数据且30秒内刚加载过，直接使用缓存
            self.challengeActivities = appState.challengeActivities
            self.filterActivities(by: selectedActivityType)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        challengeService.getChallenges()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = "加载挑战失败: \(error.localizedDescription)"
                        DRError("加载挑战失败: \(error)")
                    }
                },
                receiveValue: { [weak self] challenges in
                    guard let self = self else { return }
                    
                    self.challengeActivities = challenges
                    // 更新全局状态缓存
                    self.appState.challengeActivities = challenges
                    self.appState.lastChallengeLoadTime = Date()
                    
                    // 应用筛选
                    self.filterActivities(by: self.selectedActivityType)
                    
                    DRInfo("成功加载 \(challenges.count) 个挑战活动")
                }
            )
            .store(in: &cancellables)
    }
    
    /// 加载用户已报名的挑战列表
    func loadEnrollments() {
        // 避免重复加载
        if isLoading || 
           (!enrolledChallenges.isEmpty && 
            appState.lastEnrollmentLoadTime != nil && 
            Date().timeIntervalSince(appState.lastEnrollmentLoadTime!) < 30) {
            // 如果已有数据且30秒内刚加载过，直接使用缓存
            self.enrolledChallenges = appState.enrolledChallenges
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        challengeService.getEnrollments()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = "加载已报名挑战失败: \(error.localizedDescription)"
                        DRError("加载已报名挑战失败: \(error)")
                    }
                },
                receiveValue: { [weak self] enrollments in
                    guard let self = self else { return }
                    
                    self.enrolledChallenges = enrollments
                    // 更新全局状态缓存
                    self.appState.enrolledChallenges = enrollments
                    self.appState.lastEnrollmentLoadTime = Date()
                    
                    DRInfo("成功加载 \(enrollments.count) 个已报名挑战")
                }
            )
            .store(in: &cancellables)
    }
    
    /// 加载挑战详情
    func loadChallengeDetail(id: String) {
        isLoading = true
        errorMessage = nil
        appState.selectedChallengeId = id
        
        challengeService.getChallengeDetail(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = "加载挑战详情失败: \(error.localizedDescription)"
                        DRError("加载挑战详情失败: \(error)")
                    }
                },
                receiveValue: { [weak self] challenge in
                    self?.selectedChallenge = challenge
                    DRInfo("成功加载挑战详情: \(challenge.name)")
                }
            )
            .store(in: &cancellables)
    }
    
    /// 加载挑战进度
    func loadProgress(id: String) {
        isLoading = true
        errorMessage = nil
        
        challengeService.getProgress(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = "加载挑战进度失败: \(error.localizedDescription)"
                        DRError("加载挑战进度失败: \(error)")
                    }
                },
                receiveValue: { [weak self] progress in
                    self?.progressResponse = progress
                    self?.selectedEnrollment = progress.enrollment
                    self?.appState.selectedEnrollmentId = progress.enrollment.id
                    DRInfo("成功加载挑战进度: 完成率 \(progress.completionPercent * 100)%")
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - 操作
    
    /// 报名参加挑战
    func enrollChallenge(id: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        challengeService.enrollChallenge(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionState in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completionState {
                        self?.errorMessage = "报名挑战失败: \(error.localizedDescription)"
                        DRError("报名挑战失败: \(error)")
                        completion(false)
                    }
                },
                receiveValue: { _ in
                    DRInfo("成功报名挑战")
                    // 报名成功后重新加载已报名列表
                    self.loadEnrollments()
                    completion(true)
                }
            )
            .store(in: &cancellables)
    }
    
    /// 领取挑战奖励
    func redeemReward(id: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        challengeService.redeemReward(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completionState in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completionState {
                        self?.errorMessage = "领取奖励失败: \(error.localizedDescription)"
                        DRError("领取奖励失败: \(error)")
                        completion(false)
                    }
                },
                receiveValue: { _ in
                    DRInfo("成功领取奖励")
                    // 领取成功后重新加载进度
                    if let id = self.appState.selectedChallengeId {
                        self.loadProgress(id: id)
                    }
                    completion(true)
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - 辅助方法
    
    /// 根据类型筛选活动
    private func filterActivities(by type: String) {
        switch type {
        case "free":
            filteredActivities = challengeActivities.filter { $0.activityType == .free }
        case "paid":
            filteredActivities = challengeActivities.filter { $0.activityType == .paid }
        default:
            filteredActivities = challengeActivities
        }
    }
    
    /// 检查用户是否已报名某个挑战
    func isEnrolled(in challengeId: String) -> Bool {
        return enrolledChallenges.contains { $0.challenge.id == challengeId }
    }
    
    /// 获取指定挑战的报名信息
    func getEnrollment(for challengeId: String) -> ChallengeEnrollment? {
        return enrolledChallenges.first { $0.challenge.id == challengeId }?.enrollment
    }
    
    /// 清理资源
    func cleanup() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
} 