import Foundation
import Combine

/// 状态分析视图模型
class AnalysisViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var overallScore: Int = 0
    @Published var abilityLevel: AbilityLevel = .entry
    @Published var dimensionScores: [(dimension: AbilityDimension, name: String, score: Double, level: String)] = []
    @Published var weaknesses: [AbilityDimension] = []
    @Published var suggestions: [ImprovementSuggestion] = []
    @Published var recommendations: [(category: TrainingCategory, reason: String)] = []
    @Published var scoreTrend: [DailyScore] = []
    @Published var selectedDimension: AbilityDimension? = nil
    @Published var dimensionTrend: [DailyScore] = []
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Dependencies
    
    private let analysisService: AnalysisService
    
    // MARK: - Init
    
    init(analysisService: AnalysisService = AnalysisService.shared) {
        self.analysisService = analysisService
    }
    
    // MARK: - Data Loading
    
    /// 加载所有分析数据
    func loadAnalysis() {
        isLoading = true
        errorMessage = nil
        
        // 计算综合评分
        overallScore = analysisService.calculateOverallScore()
        abilityLevel = analysisService.getCurrentAbilityLevel()
        
        // 计算维度得分
        dimensionScores = analysisService.getDimensionScores()
        
        // 识别薄弱环节
        weaknesses = analysisService.identifyWeaknesses()
        
        // 生成改善建议
        suggestions = analysisService.generateImprovementSuggestions()
        
        // 获取推荐训练
        recommendations = analysisService.recommendTrainingCategories()
        
        // 获取历史趋势
        scoreTrend = analysisService.fetchScoreTrend(days: 30)
        
        // 如果有选中的维度，加载维度趋势
        if let dimension = selectedDimension {
            dimensionTrend = analysisService.fetchDimensionTrend(dimension: dimension, days: 30)
        }
        
        isLoading = false
    }
    
    /// 刷新数据
    func refresh() {
        loadAnalysis()
    }
    
    /// 选择维度查看趋势
    func selectDimension(_ dimension: AbilityDimension) {
        selectedDimension = dimension
        dimensionTrend = analysisService.fetchDimensionTrend(dimension: dimension, days: 30)
    }
    
    /// 取消维度选择
    func deselectDimension() {
        selectedDimension = nil
        dimensionTrend = []
    }
    
    /// 保存当前能力档案
    func saveAbilityProfile() {
        analysisService.saveCurrentAbilityProfile()
    }
    
    // MARK: - Computed Properties
    
    /// 综合评分颜色
    var scoreColor: String {
        switch overallScore {
        case 0..<20: return "red"
        case 20..<40: return "orange"
        case 40..<60: return "yellow"
        case 60..<80: return "green"
        default: return "blue"
        }
    }
    
    /// 综合评分描述
    var scoreDescription: String {
        switch overallScore {
        case 0..<20: return "需要加强训练"
        case 20..<40: return "基础正在建立"
        case 40..<60: return "稳步进步中"
        case 60..<80: return "表现良好"
        default: return "非常出色"
        }
    }
    
    /// 能力等级图标
    var levelIcon: String {
        switch abilityLevel {
        case .entry: return "leaf.fill"
        case .beginner: return "sprout"
        case .intermediate: return "tree.fill"
        case .advanced: return "mountain.2.fill"
        case .expert: return "crown.fill"
        }
    }
    
    /// 能力等级颜色
    var levelColor: String {
        switch abilityLevel {
        case .entry: return "gray"
        case .beginner: return "green"
        case .intermediate: return "blue"
        case .advanced: return "purple"
        case .expert: return "orange"
        }
    }
    
    /// 是否有薄弱环节
    var hasWeaknesses: Bool {
        !weaknesses.isEmpty
    }
    
    /// 薄弱环节名称列表
    var weaknessNames: [String] {
        weaknesses.map { $0.rawValue }
    }
    
    /// 维度得分字典（用于雷达图）
    var dimensionValues: [String: Double] {
        var dict: [String: Double] = [:]
        for item in dimensionScores {
            dict[item.name] = item.score
        }
        return dict
    }
    
    /// 获取指定维度的得分
    func scoreForDimension(_ dimension: AbilityDimension) -> Double {
        dimensionScores.first { $0.dimension == dimension }?.score ?? 0
    }
    
    /// 获取指定维度的等级
    func levelForDimension(_ dimension: AbilityDimension) -> String {
        dimensionScores.first { $0.dimension == dimension }?.level ?? ""
    }
    
    /// 维度是否为薄弱环节
    func isWeakness(_ dimension: AbilityDimension) -> Bool {
        weaknesses.contains(dimension)
    }
}