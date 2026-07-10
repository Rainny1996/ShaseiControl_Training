import Foundation
import SwiftUI

/// 计划视图模型 - 管理训练计划的状态和业务逻辑
class PlanViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentPlan: TrainingPlan?
    @Published var todayItems: [PlanItem] = []
    @Published var weekItems: [PlanItem] = []
    @Published var selectedPeriod: PlanPeriod = .week
    @Published var isLoading: Bool = false
    @Published var showAssessment: Bool = false
    @Published var showTemplateSelection: Bool = false
    @Published var reminderHour: Int = 8
    @Published var reminderMinute: Int = 0
    @Published var reminderEnabled: Bool = false
    
    // MARK: - 计算属性
    
    /// 计划进度百分比
    var progressPercent: Int {
        guard let plan = currentPlan else { return 0 }
        return Int(plan.progress * 100)
    }
    
    /// 今日完成项数
    var todayCompletedCount: Int {
        todayItems.filter { $0.isCompleted }.count
    }
    
    /// 今日总项数
    var todayTotalCount: Int {
        todayItems.count
    }
    
    /// 本周完成项数
    var weekCompletedCount: Int {
        weekItems.filter { $0.isCompleted }.count
    }
    
    /// 本周总项数
    var weekTotalCount: Int {
        weekItems.count
    }
    
    /// 计划目标
    var planGoal: String {
        currentPlan?.goal ?? "暂无计划"
    }
    
    /// 计划剩余天数
    var remainingDays: Int {
        guard let plan = currentPlan else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: plan.endDate).day ?? 0
        return max(0, days)
    }
    
    /// 是否有活跃计划
    var hasActivePlan: Bool {
        currentPlan != nil
    }
    
    // MARK: - Dependencies
    
    private let planRepository: PlanRepository
    private let trainingRepository: TrainingRepository
    
    init(planRepository: PlanRepository = PlanRepository(),
         trainingRepository: TrainingRepository = TrainingRepository()) {
        self.planRepository = planRepository
        self.trainingRepository = trainingRepository
        loadReminderSettings()
    }
    
    // MARK: - 数据加载
    
    /// 加载计划数据
    func loadPlan() {
        isLoading = true
        
        // 加载当前活跃计划
        currentPlan = planRepository.fetchActivePlan()
        
        // 加载今日计划项
        todayItems = planRepository.fetchTodayPlanItems()
        
        // 加载本周计划项
        loadWeekItems()
        
        // 检查是否需要评估
        if currentPlan == nil {
            let defaults = UserDefaults.standard
            showAssessment = !defaults.bool(forKey: "hasCompletedAssessment")
        }
        
        isLoading = false
    }
    
    /// 加载本周计划项
    private func loadWeekItems() {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        weekItems = planRepository.fetchPlanItems(from: startOfWeek, to: endOfWeek)
    }
    
    /// 刷新数据
    func refresh() {
        loadPlan()
    }
    
    // MARK: - 计划操作
    
    /// 使用模板创建计划
    func createPlanFromTemplate(_ template: PlanTemplate) {
        let plan = PlanService.shared.generatePlanFromTemplate(template)
        planRepository.saveTrainingPlan(plan)
        loadPlan()
    }
    
    /// 重新生成计划（基于最新训练数据）
    func regeneratePlan() {
        guard let assessment = AssessmentViewModel.loadSavedAssessment() else { return }
        
        // 删除旧计划
        if let oldPlan = currentPlan {
            planRepository.deletePlan(oldPlan.id)
        }
        
        // 生成新计划
        let plan = PlanService.shared.generatePlan(from: assessment)
        planRepository.saveTrainingPlan(plan)
        loadPlan()
    }
    
    /// 标记计划项完成
    func markItemCompleted(_ itemId: UUID) {
        planRepository.markPlanItemCompleted(itemId: itemId)
        loadPlan()
    }
    
    /// 动态调整计划
    func adjustPlanIfNeeded() {
        guard let plan = currentPlan else { return }
        
        // 获取近期训练记录
        let records = trainingRepository.fetchRecentRecords(limit: 10)
        guard !records.isEmpty else { return }
        
        // 调整计划
        let adjustedPlan = PlanService.shared.adjustPlan(plan, basedOn: records)
        
        // 保存调整后的计划
        if adjustedPlan.items != plan.items {
            planRepository.updatePlanItems(planId: adjustedPlan.id, items: adjustedPlan.items)
            loadPlan()
        }
    }
    
    // MARK: - 提醒设置
    
    /// 切换提醒开关
    func toggleReminder() {
        reminderEnabled.toggle()
        if reminderEnabled {
            NotificationService.shared.requestAuthorization()
            NotificationService.shared.scheduleDailyTrainingReminder(hour: reminderHour, minute: reminderMinute)
        } else {
            NotificationService.shared.cancelDailyTrainingReminder()
        }
        saveReminderSettings()
    }
    
    /// 更新提醒时间
    func updateReminderTime(hour: Int, minute: Int) {
        reminderHour = hour
        reminderMinute = minute
        if reminderEnabled {
            NotificationService.shared.scheduleDailyTrainingReminder(hour: hour, minute: minute)
        }
        saveReminderSettings()
    }
    
    /// 加载提醒设置
    private func loadReminderSettings() {
        let defaults = UserDefaults.standard
        reminderEnabled = defaults.bool(forKey: "reminderEnabled")
        reminderHour = defaults.integer(forKey: "reminderHour")
        reminderMinute = defaults.integer(forKey: "reminderMinute")
        if reminderHour == 0 && reminderMinute == 0 {
            reminderHour = 8
        }
    }
    
    /// 保存提醒设置
    private func saveReminderSettings() {
        let defaults = UserDefaults.standard
        defaults.set(reminderEnabled, forKey: "reminderEnabled")
        defaults.set(reminderHour, forKey: "reminderHour")
        defaults.set(reminderMinute, forKey: "reminderMinute")
    }
    
    // MARK: - 日历数据
    
    /// 获取指定日期的计划项
    func itemsForDate(_ date: Date) -> [PlanItem] {
        let calendar = Calendar.current
        return weekItems.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    /// 判断指定日期是否有计划
    func hasItemsOnDate(_ date: Date) -> Bool {
        !itemsForDate(date).isEmpty
    }
    
    /// 判断指定日期是否全部完成
    func isDateCompleted(_ date: Date) -> Bool {
        let items = itemsForDate(date)
        return !items.isEmpty && items.allSatisfy { $0.isCompleted }
    }
    
    /// 判断指定日期是否部分完成
    func isDatePartiallyCompleted(_ date: Date) -> Bool {
        let items = itemsForDate(date)
        let completedCount = items.filter { $0.isCompleted }.count
        return completedCount > 0 && completedCount < items.count
    }
}

// MARK: - TrainingRepository Extension

extension TrainingRepository {
    
    /// 获取近期训练记录
    func fetchRecentRecords(limit: Int = 10) -> [TrainingRecord] {
        // 从Core Data获取最近记录
        // 这里使用简化的实现
        return []
    }
}