import SwiftUI

/// 首次使用引导视图
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    /// 引导页面数据
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "figure.strengthtraining.traditional",
            title: "欢迎来到控制训练",
            subtitle: "科学训练，逐步提升",
            description: "基于专业训练方法，帮助您系统性地提升控制能力，建立自信与持久的掌控力。",
            gradientColors: [Color.blue, Color.cyan]
        ),
        OnboardingPage(
            icon: "calendar.badge.clock",
            title: "个性化训练计划",
            subtitle: "量身定制，循序渐进",
            description: "根据您的当前水平和目标，智能生成专属训练计划。每日任务清晰明确，跟踪进度持续进步。",
            gradientColors: [Color.green, Color.teal]
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            title: "数据驱动分析",
            subtitle: "量化进步，精准提升",
            description: "多维度能力评分系统，实时追踪持久力、控制力、恢复力等关键指标，让进步看得见。",
            gradientColors: [Color.orange, Color.yellow]
        ),
        OnboardingPage(
            icon: "lock.shield",
            title: "隐私安全保障",
            subtitle: "数据加密，安心使用",
            description: "支持Face ID/密码锁、后台模糊保护、AES-256数据加密，您的训练数据只属于您自己。",
            gradientColors: [Color.purple, Color.pink]
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 页面内容
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            // 页面指示器
            pageIndicator
            
            // 底部按钮
            bottomButtons
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - 页面指示器
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(currentPage == index ? pages[index].gradientColors[0] : Color(.systemGray4))
                    .frame(width: currentPage == index ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - 底部按钮
    
    private var bottomButtons: some View {
        HStack {
            // 跳过按钮
            if currentPage < pages.count - 1 {
                Button(action: skipOnboarding) {
                    Text("跳过")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 下一步/开始按钮
            Button(action: nextAction) {
                HStack(spacing: 8) {
                    Text(currentPage == pages.count - 1 ? "开始使用" : "下一步")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if currentPage < pages.count - 1 {
                        Image(systemName: "arrow.right")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: pages[currentPage].gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: pages[currentPage].gradientColors[0].opacity(0.3), radius: 8, y: 4)
            }
        }
    }
    
    // MARK: - 操作方法
    
    private func nextAction() {
        if currentPage < pages.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }
    
    private func skipOnboarding() {
        completeOnboarding()
    }
    
    private func completeOnboarding() {
        withAnimation(.easeOut(duration: 0.3)) {
            appState.completeOnboarding()
        }
    }
}

// MARK: - 引导页面数据模型

struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let gradientColors: [Color]
}

// MARK: - 单个引导页面视图

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var iconScale: CGFloat = 0.5
    @State private var contentOffset: CGFloat = 30
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // 图标
            ZStack {
                // 背景圆
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.gradientColors.map { $0.opacity(0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 180, height: 180)
                
                // 装饰圆环
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: page.gradientColors.map { $0.opacity(0.3) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 200, height: 200)
                
                // 图标
                Image(systemName: page.icon)
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: page.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(iconScale)
            }
            
            // 标题
            VStack(spacing: 8) {
                Text(page.title)
                    .font(.title.bold())
                    .foregroundColor(.primary)
                
                Text(page.subtitle)
                    .font(.title3)
                    .foregroundStyle(
                        LinearGradient(
                            colors: page.gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .offset(y: contentOffset)
            .opacity(contentOffset == 0 ? 1 : 0)
            
            // 描述
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
                .offset(y: contentOffset)
                .opacity(contentOffset == 0 ? 1 : 0)
            
            Spacer()
                .frame(height: 60)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                iconScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                contentOffset = 0
            }
        }
    }
}

// MARK: - 引导完成后的初始设置视图

struct InitialSetupView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedGoal: TrainingGoal = .endurance
    @State private var selectedLevel: ExperienceLevel = .beginner
    @State private var isSettingUp = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // 标题
                VStack(spacing: 8) {
                    Text("初始设置")
                        .font(.title.bold())
                    
                    Text("帮助我们了解您的情况，定制专属训练计划")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // 训练目标选择
                VStack(alignment: .leading, spacing: 12) {
                    Text("训练目标")
                        .font(.headline)
                    
                    VStack(spacing: 10) {
                        ForEach(TrainingGoal.allCases, id: \.self) { goal in
                            GoalOptionRow(
                                goal: goal,
                                isSelected: selectedGoal == goal,
                                action: { selectedGoal = goal }
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                // 经验水平选择
                VStack(alignment: .leading, spacing: 12) {
                    Text("经验水平")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        ForEach(ExperienceLevel.allCases, id: \.self) { level in
                            LevelOptionCard(
                                level: level,
                                isSelected: selectedLevel == level,
                                action: { selectedLevel = level }
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // 开始按钮
                Button(action: startInitialSetup) {
                    HStack {
                        if isSettingUp {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("开始我的训练之旅")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.accentColor)
                    .cornerRadius(25)
                }
                .disabled(isSettingUp)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .navigationTitle("初始设置")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func startInitialSetup() {
        isSettingUp = true
        // 保存用户初始设置
        UserDefaults.standard.set(selectedGoal.rawValue, forKey: "trainingGoal")
        UserDefaults.standard.set(selectedLevel.rawValue, forKey: "experienceLevel")
        // 完成初始设置
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            appState.completeInitialSetup()
        }
    }
}

// MARK: - 训练目标枚举

enum TrainingGoal: String, CaseIterable {
    case endurance = "持久提升"
    case control = "精准控制"
    case recovery = "快速恢复"
    case comprehensive = "全面提升"
    
    var icon: String {
        switch self {
        case .endurance: return "timer"
        case .control: return "hand.tap"
        case .recovery: return "arrow.uturn.backward"
        case .comprehensive: return "star"
        }
    }
    
    var description: String {
        switch self {
        case .endurance: return "延长持续时间，增强耐力"
        case .control: return "提升控制精度，随心所欲"
        case .recovery: return "缩短恢复时间，快速重启"
        case .comprehensive: return "均衡发展，全面提升"
        }
    }
}

// MARK: - 经验水平枚举

enum ExperienceLevel: String, CaseIterable {
    case beginner = "初学者"
    case intermediate = "有经验"
    case advanced = "进阶"
    
    var icon: String {
        switch self {
        case .beginner: return "1.circle"
        case .intermediate: return "2.circle"
        case .advanced: return "3.circle"
        }
    }
    
    var description: String {
        switch self {
        case .beginner: return "刚开始接触训练"
        case .intermediate: return "有一定训练基础"
        case .advanced: return "有丰富训练经验"
        }
    }
}

// MARK: - 目标选项行

struct GoalOptionRow: View {
    let goal: TrainingGoal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: goal.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(goal.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - 经验水平选项卡片

struct LevelOptionCard: View {
    let level: ExperienceLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: level.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .accentColor)
                
                Text(level.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(level.description)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.accentColor : Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}