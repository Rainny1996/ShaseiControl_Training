import SwiftUI

@main
struct ControlTrainingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var dataController = DataController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(appState)
                .onAppear {
                    initializeDataIfNeeded()
                }
        }
    }
    
    /// 首次启动时初始化预设数据
    private func initializeDataIfNeeded() {
        guard !appState.isTrainingDataInitialized else { return }
        
        // 导入预设训练方法数据
        let trainingRepo = TrainingRepository(dataController: dataController)
        let defaultMethods = TrainingContentData.allTrainingMethods()
        trainingRepo.importTrainingMethods(defaultMethods)
        
        // 标记已初始化
        appState.markTrainingDataInitialized()
        print("Training data initialized with \(defaultMethods.count) methods")
    }
}

/// 应用全局状态管理
class AppState: ObservableObject {
    @Published var isLocked: Bool = false
    @Published var hasCompletedAssessment: Bool = false
    @Published var isFirstLaunch: Bool = true
    @Published var isTrainingDataInitialized: Bool = false
    @Published var isOnboardingCompleted: Bool = false
    @Published var isInitialSetupCompleted: Bool = false
    
    /// 配置应用保护（仅在初始化时调用一次）
    private func setupSecurityProtection() {
        SecurityService.shared.configureProtection()
    }
    
    init() {
        loadState()
        setupSecurityProtection()
        setupNotificationObservers()
    }
    
    /// 设置通知观察者
    private func setupNotificationObservers() {
        // 监听应用锁定通知
        NotificationCenter.default.addObserver(
            forName: .appDidLock,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isLocked = true
        }
        
        // 监听应用解锁通知
        NotificationCenter.default.addObserver(
            forName: .appDidUnlock,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isLocked = false
        }
    }
    
    private func loadState() {
        let defaults = UserDefaults.standard
        hasCompletedAssessment = defaults.bool(forKey: "hasCompletedAssessment")
        isFirstLaunch = defaults.bool(forKey: "isFirstLaunch") == false
        isTrainingDataInitialized = defaults.bool(forKey: "hasInitializedTrainingData")
        isOnboardingCompleted = defaults.bool(forKey: "isOnboardingCompleted")
        isInitialSetupCompleted = defaults.bool(forKey: "isInitialSetupCompleted")
    }
    
    func markAssessmentCompleted() {
        hasCompletedAssessment = true
        UserDefaults.standard.set(true, forKey: "hasCompletedAssessment")
    }
    
    func markFirstLaunchComplete() {
        isFirstLaunch = false
        UserDefaults.standard.set(true, forKey: "isFirstLaunch")
    }
    
    func markTrainingDataInitialized() {
        isTrainingDataInitialized = true
        UserDefaults.standard.set(true, forKey: "hasInitializedTrainingData")
    }
    
    /// 完成引导流程
    func completeOnboarding() {
        isOnboardingCompleted = true
        isFirstLaunch = false
        UserDefaults.standard.set(true, forKey: "isOnboardingCompleted")
        UserDefaults.standard.set(true, forKey: "isFirstLaunch")
    }
    
    /// 完成初始设置
    func completeInitialSetup() {
        isInitialSetupCompleted = true
        UserDefaults.standard.set(true, forKey: "isInitialSetupCompleted")
    }
}