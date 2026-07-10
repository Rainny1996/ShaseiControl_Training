import Foundation
import Combine
import SwiftUI

/// 评估问卷视图模型
class AssessmentViewModel: ObservableObject {
    
    // MARK: - 问卷步骤
    let totalSteps = 5
    
    // MARK: - 当前步骤
    @Published var currentStep: Int = 0
    
    // MARK: - 问卷数据
    @Published var age: Int = 40
    @Published var currentAbilityScore: Int = 5
    @Published var trainingExperience: TrainingExperience = .none
    @Published var physicalCondition: PhysicalCondition = .normal
    @Published var trainingGoal: TrainingGoal = .endurance
    
    // MARK: - UI 状态
    @Published var isSubmitting: Bool = false
    @Published var assessmentCompleted: Bool = false
    
    // MARK: - 计算属性
    
    /// 当前步骤进度
    var stepProgress: Double {
        Double(currentStep + 1) / Double(totalSteps)
    }
    
    /// 当前步骤标题
    var stepTitle: String {
        switch currentStep {
        case 0: return "基本信息"
        case 1: return "能力自评"
        case 2: return "训练经验"
        case 3: return "身体状况"
        case 4: return "训练目标"
        default: return ""
        }
    }
    
    /// 当前步骤描述
    var stepDescription: String {
        switch currentStep {
        case 0: return "请填写您的基本信息，帮助我们了解您"
        case 1: return "请客观评估您当前的控制能力"
        case 2: return "请选择您之前的训练经验"
        case 3: return "请选择您当前的身体状况"
        case 4: return "请选择您最希望改善的方面"
        default: return ""
        }
    }
    
    /// 是否可以进入下一步
    var canProceed: Bool {
        switch currentStep {
        case 0: return age >= 18 && age <= 100
        case 1: return currentAbilityScore >= 1 && currentAbilityScore <= 10
        case 2: return true
        case 3: return true
        case 4: return true
        default: return false
        }
    }
    
    /// 是否是最后一步
    var isLastStep: Bool {
        currentStep == totalSteps - 1
    }
    
    // MARK: - Dependencies
    private let planRepository: PlanRepository
    private let appState: AppState
    
    init(planRepository: PlanRepository = PlanRepository(),
         appState: AppState = AppState()) {
        self.planRepository = planRepository
        self.appState = appState
    }
    
    // MARK: - 导航方法
    
    /// 下一步
    func nextStep() {
        guard canProceed, currentStep < totalSteps - 1 else { return }
        withAnimation {
            currentStep += 1
        }
    }
    
    /// 上一步
    func previousStep() {
        guard currentStep > 0 else { return }
        withAnimation {
            currentStep -= 1
        }
    }
    
    /// 跳到指定步骤
    func goToStep(_ step: Int) {
        guard step >= 0, step < totalSteps else { return }
        withAnimation {
            currentStep = step
        }
    }
    
    // MARK: - 提交评估
    
    /// 提交评估并生成计划
    @MainActor
    func submitAssessment() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        
        // 创建评估数据
        let assessment = Assessment(
            age: age,
            currentAbilityScore: currentAbilityScore,
            trainingExperience: trainingExperience,
            physicalCondition: physicalCondition,
            trainingGoal: trainingGoal
        )
        
        // 保存评估数据到 UserDefaults
        saveAssessment(assessment)
        
        // 生成训练计划
        let plan = PlanService.shared.generatePlan(from: assessment)
        planRepository.saveTrainingPlan(plan)
        
        // 标记评估完成
        appState.markAssessmentCompleted()
        
        // 设置训练提醒（默认每天早上8点）
        NotificationService.shared.requestAuthorization()
        NotificationService.shared.scheduleDailyTrainingReminder(hour: 8, minute: 0)
        
        isSubmitting = false
        assessmentCompleted = true
    }
    
    // MARK: - Private Methods
    
    /// 保存评估数据
    private func saveAssessment(_ assessment: Assessment) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(assessment) {
            UserDefaults.standard.set(data, forKey: "userAssessment")
        }
    }
    
    /// 加载已保存的评估数据
    static func loadSavedAssessment() -> Assessment? {
        guard let data = UserDefaults.standard.data(forKey: "userAssessment") else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(Assessment.self, from: data)
    }
}