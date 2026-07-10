import SwiftUI
import Combine

/// 训练方法视图模型 - 管理训练列表、筛选、收藏等状态
class TrainingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 所有训练方法
    @Published var allMethods: [TrainingMethod] = []
    
    /// 筛选后的训练方法
    @Published var filteredMethods: [TrainingMethod] = []
    
    /// 收藏的训练方法
    @Published var favoriteMethods: [TrainingMethod] = []
    
    /// 当前选中的分类
    @Published var selectedCategory: TrainingCategory? = nil
    
    /// 当前选中的难度
    @Published var selectedDifficulty: DifficultyLevel? = nil
    
    /// 搜索关键词
    @Published var searchText: String = ""
    
    /// 是否显示仅收藏
    @Published var showFavoritesOnly: Bool = false
    
    /// 是否正在加载
    @Published var isLoading: Bool = false
    
    /// 数据是否已初始化
    @Published var isDataInitialized: Bool = false
    
    // MARK: - Private Properties
    
    private let trainingRepository: TrainingRepository
    private let dataController: DataController
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// 分类列表（含数量）
    var categoriesWithCount: [(category: TrainingCategory, count: Int)] {
        TrainingCategory.allCases.map { category in
            (category, allMethods.filter { $0.category == category }.count)
        }
    }
    
    /// 难度列表（含数量）
    var difficultiesWithCount: [(difficulty: DifficultyLevel, count: Int)] {
        DifficultyLevel.allCases.map { difficulty in
            (difficulty, allMethods.filter { $0.difficulty == difficulty }.count)
        }
    }
    
    /// 是否有筛选条件
    var hasActiveFilters: Bool {
        selectedCategory != nil || selectedDifficulty != nil || !searchText.isEmpty || showFavoritesOnly
    }
    
    // MARK: - Initialization
    
    init(dataController: DataController = .shared) {
        self.dataController = dataController
        self.trainingRepository = TrainingRepository(dataController: dataController)
        setupBindings()
    }
    
    /// 设置响应式绑定
    private func setupBindings() {
        // 监听筛选条件变化
        Publishers.CombineLatest4($selectedCategory, $selectedDifficulty, $searchText, $showFavoritesOnly)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _, _, _, _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    /// 加载训练方法数据
    func loadTrainingMethods() {
        isLoading = true
        
        // 先尝试从Core Data加载
        let savedMethods = trainingRepository.fetchAllTrainingMethods()
        
        if savedMethods.isEmpty && !isDataInitialized {
            // 首次启动，导入预设数据
            let defaultMethods = TrainingContentData.allTrainingMethods()
            trainingRepository.importTrainingMethods(defaultMethods)
            
            // 等待保存完成后重新加载
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.loadFromCoreData()
                self?.isLoading = false
            }
            isDataInitialized = true
        } else {
            loadFromCoreData()
            isLoading = false
        }
    }
    
    /// 从Core Data加载数据
    private func loadFromCoreData() {
        allMethods = trainingRepository.fetchAllTrainingMethods()
        favoriteMethods = trainingRepository.fetchFavoriteMethods()
        applyFilters()
    }
    
    /// 刷新数据
    func refresh() {
        loadFromCoreData()
    }
    
    // MARK: - Filtering
    
    /// 应用筛选条件
    private func applyFilters() {
        var result = allMethods
        
        // 分类筛选
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        // 难度筛选
        if let difficulty = selectedDifficulty {
            result = result.filter { $0.difficulty == difficulty }
        }
        
        // 搜索筛选
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { method in
                method.name.lowercased().contains(query) ||
                method.description.lowercased().contains(query) ||
                method.principle.lowercased().contains(query) ||
                method.targetAudience.lowercased().contains(query)
            }
        }
        
        // 仅显示收藏
        if showFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }
        
        filteredMethods = result
    }
    
    /// 清除所有筛选条件
    func clearAllFilters() {
        selectedCategory = nil
        selectedDifficulty = nil
        searchText = ""
        showFavoritesOnly = false
    }
    
    // MARK: - Favorites
    
    /// 切换收藏状态
    func toggleFavorite(methodId: UUID) {
        trainingRepository.toggleFavorite(methodId: methodId)
        
        // 更新本地数据
        if let index = allMethods.firstIndex(where: { $0.id == methodId }) {
            allMethods[index].isFavorite.toggle()
        }
        
        // 更新收藏列表
        favoriteMethods = allMethods.filter { $0.isFavorite }
        
        // 重新应用筛选
        applyFilters()
    }
    
    /// 检查方法是否已收藏
    func isFavorite(_ methodId: UUID) -> Bool {
        allMethods.first(where: { $0.id == methodId })?.isFavorite ?? false
    }
    
    // MARK: - Training Method Access
    
    /// 根据ID获取训练方法
    func methodById(_ id: UUID) -> TrainingMethod? {
        allMethods.first(where: { $0.id == id })
    }
    
    /// 获取推荐给初学者的方法
    func beginnerRecommendations() -> [TrainingMethod] {
        allMethods.filter { $0.difficulty == .beginner }
    }
    
    /// 获取与指定方法相关的方法（同分类或同难度）
    func relatedMethods(to method: TrainingMethod) -> [TrainingMethod] {
        allMethods.filter { 
            ($0.category == method.category || $0.difficulty == method.difficulty) && $0.id != method.id 
        }
    }
}