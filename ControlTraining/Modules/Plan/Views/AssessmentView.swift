import SwiftUI

/// 评估问卷视图 - 5步引导式问卷
struct AssessmentView: View {
    @StateObject private var viewModel = AssessmentViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 进度条
                progressBar
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                // 步骤标题和描述
                VStack(spacing: 8) {
                    Text(viewModel.stepTitle)
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    Text(viewModel.stepDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
                
                // 步骤内容
                Group {
                    switch viewModel.currentStep {
                    case 0: ageStepView
                    case 1: abilityStepView
                    case 2: experienceStepView
                    case 3: conditionStepView
                    case 4: goalStepView
                    default: EmptyView()
                    }
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // 底部按钮
                bottomButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
            .navigationTitle("初始评估")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.currentStep > 0 {
                        Button("上一步") {
                            viewModel.previousStep()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 进度条
    
    private var progressBar: some View {
        VStack(spacing: 8) {
            // 步骤指示器
            HStack(spacing: 4) {
                ForEach(0..<viewModel.totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= viewModel.currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                }
            }
            
            // 进度条
            ProgressView(value: viewModel.stepProgress)
                .tint(.accentColor)
                .animation(.easeInOut(duration: 0.3), value: viewModel.stepProgress)
        }
    }
    
    // MARK: - Step 1: 年龄
    
    private var ageStepView: some View {
        VStack(spacing: 32) {
            // 年龄图标
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .padding(.top, 20)
            
            // 年龄显示
            VStack(spacing: 8) {
                Text("\(viewModel.age)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.accentColor)
                
                Text("岁")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // 年龄滑块
            VStack(spacing: 12) {
                Slider(value: Binding(
                    get: { Double(viewModel.age) },
                    set: { viewModel.age = Int($0) }
                ), in: 18...80, step: 1)
                .tint(.accentColor)
                
                HStack {
                    Text("18岁")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("80岁")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            
            // 提示
            Text("年龄信息仅用于个性化训练计划生成，不会对外分享")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }
    
    // MARK: - Step 2: 能力自评
    
    private var abilityStepView: some View {
        VStack(spacing: 24) {
            // 评分图标
            Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .padding(.top, 20)
            
            Text("请客观评估您当前的控制能力")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // 评分显示
            VStack(spacing: 8) {
                Text("\(viewModel.currentAbilityScore)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(abilityScoreColor)
                
                Text(abilityScoreLabel)
                    .font(.headline)
                    .foregroundColor(abilityScoreColor)
            }
            
            // 评分滑块
            VStack(spacing: 12) {
                Slider(value: Binding(
                    get: { Double(viewModel.currentAbilityScore) },
                    set: { viewModel.currentAbilityScore = Int($0) }
                ), in: 1...10, step: 1)
                .tint(abilityScoreColor)
                
                HStack {
                    Text("1 - 很弱")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("10 - 很强")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            
            // 评分说明
            abilityScoreDescription
                .padding(.horizontal, 8)
        }
    }
    
    private var abilityScoreColor: Color {
        switch viewModel.currentAbilityScore {
        case 1...3: return .red
        case 4...5: return .orange
        case 6...7: return .yellow
        case 8...10: return .green
        default: return .accentColor
        }
    }
    
    private var abilityScoreLabel: String {
        switch viewModel.currentAbilityScore {
        case 1...2: return "需要大量训练"
        case 3...4: return "基础较弱"
        case 5...6: return "中等水平"
        case 7...8: return "较好水平"
        case 9...10: return "优秀水平"
        default: return ""
        }
    }
    
    private var abilityScoreDescription: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("1-3分：控制力较弱，需要从基础开始训练", systemImage: "info.circle")
                .font(.caption)
                .foregroundColor(.secondary)
            Label("4-6分：有一定基础，需要系统性提升", systemImage: "info.circle")
                .font(.caption)
                .foregroundColor(.secondary)
            Label("7-10分：基础较好，可以进行进阶训练", systemImage: "info.circle")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Step 3: 训练经验
    
    private var experienceStepView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .padding(.top, 20)
            
            Text("选择您之前的训练经验水平")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                ForEach(TrainingExperience.allCases, id: \.self) { experience in
                    ExperienceOptionCard(
                        experience: experience,
                        isSelected: viewModel.trainingExperience == experience,
                        action: { viewModel.trainingExperience = experience }
                    )
                }
            }
        }
    }
    
    // MARK: - Step 4: 身体状况
    
    private var conditionStepView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .padding(.top, 20)
            
            Text("选择您当前的身体状况")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                ForEach(PhysicalCondition.allCases, id: \.self) { condition in
                    ConditionOptionCard(
                        condition: condition,
                        isSelected: viewModel.physicalCondition == condition,
                        action: { viewModel.physicalCondition = condition }
                    )
                }
            }
        }
    }
    
    // MARK: - Step 5: 训练目标
    
    private var goalStepView: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .padding(.top, 20)
            
            Text("选择您最希望改善的方面")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                ForEach(TrainingGoal.allCases, id: \.self) { goal in
                    GoalOptionCard(
                        goal: goal,
                        isSelected: viewModel.trainingGoal == goal,
                        action: { viewModel.trainingGoal = goal }
                    )
                }
            }
        }
    }
    
    // MARK: - 底部按钮
    
    private var bottomButtons: some View {
        VStack(spacing: 12) {
            if viewModel.isLastStep {
                // 提交按钮
                Button(action: {
                    Task { await viewModel.submitAssessment() }
                }) {
                    HStack {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("生成训练计划")
                                .font(.headline)
                            Image(systemName: "sparkles")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.canProceed || viewModel.isSubmitting)
                .opacity(viewModel.canProceed ? 1.0 : 0.6)
            } else {
                // 下一步按钮
                Button(action: { viewModel.nextStep() }) {
                    HStack {
                        Text("下一步")
                            .font(.headline)
                        Image(systemName: "chevron.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.canProceed)
                .opacity(viewModel.canProceed ? 1.0 : 0.6)
            }
            
            // 步骤指示
            Text("\(viewModel.currentStep + 1) / \(viewModel.totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 经验选择卡片

struct ExperienceOptionCard: View {
    let experience: TrainingExperience
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(experience.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .gray.opacity(0.3))
                    .font(.title3)
            }
            .padding(16)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
    
    private var iconName: String {
        switch experience {
        case .none: return "xmark.circle"
        case .beginner: return "leaf"
        case .intermediate: return "flame"
        case .advanced: return "bolt.fill"
        }
    }
    
    private var description: String {
        switch experience {
        case .none: return "从未进行过相关训练"
        case .beginner: return "尝试过少量训练，不规律"
        case .intermediate: return "有规律训练经验，3个月以上"
        case .advanced: return "长期系统训练，1年以上"
        }
    }
}

// MARK: - 身体状况选择卡片

struct ConditionOptionCard: View {
    let condition: PhysicalCondition
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? conditionColor : .secondary)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(condition.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .gray.opacity(0.3))
                    .font(.title3)
            }
            .padding(16)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
    
    private var iconName: String {
        switch condition {
        case .excellent: return "heart.fill"
        case .good: return "heart.circle.fill"
        case .normal: return "heart.circle"
        case .poor: return "heart.slash.circle"
        }
    }
    
    private var conditionColor: Color {
        switch condition {
        case .excellent: return .green
        case .good: return .blue
        case .normal: return .orange
        case .poor: return .red
        }
    }
    
    private var description: String {
        switch condition {
        case .excellent: return "经常运动，身体素质很好"
        case .good: return "偶尔运动，身体素质不错"
        case .normal: return "较少运动，身体素质一般"
        case .poor: return "几乎不运动，身体素质较差"
        }
    }
}

// MARK: - 训练目标选择卡片

struct GoalOptionCard: View {
    let goal: TrainingGoal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? goalColor : .secondary)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .gray.opacity(0.3))
                    .font(.title3)
            }
            .padding(16)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
    
    private var iconName: String {
        switch goal {
        case .endurance: return "clock.fill"
        case .control: return "hand.raised.fill"
        case .recovery: return "arrow.clockwise.heart.fill"
        case .comprehensive: return "star.fill"
        }
    }
    
    private var goalColor: Color {
        switch goal {
        case .endurance: return .blue
        case .control: return .purple
        case .recovery: return .green
        case .comprehensive: return .orange
        }
    }
    
    private var description: String {
        switch goal {
        case .endurance: return "延长持续时间，增强耐力"
        case .control: return "提升主动控制能力"
        case .recovery: return "加快训练间恢复速度"
        case .comprehensive: return "全面均衡提升各方面能力"
        }
    }
}

#Preview {
    AssessmentView()
        .environmentObject(AppState())
}