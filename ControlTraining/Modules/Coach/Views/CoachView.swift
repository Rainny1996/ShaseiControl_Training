import SwiftUI

/// 实时陪练视图 - 提供训练模式选择、倒计时准备、训练计时、呼吸引导、完成记录
struct CoachView: View {
    
    /// 传入的训练方法（可选，从训练详情页进入时提供）
    var initialMethod: TrainingMethod?
    
    @State private var selectedMode: TrainingMode = .basic
    @State private var selectedMethod: TrainingMethod?
    @State private var isTraining = false
    @State private var coachViewModel: CoachViewModel?
    @State private var showReviewQuestionnaire = false
    
    @StateObject private var trainingViewModel = TrainingViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if let method = selectedMethod, isTraining, let viewModel = coachViewModel {
                    trainingSessionView(method: method, viewModel: viewModel)
                } else {
                    trainingSelectionView
                }
            }
            .navigationTitle("陪练")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if let method = initialMethod {
                selectedMethod = method
            }
        }
        .sheet(isPresented: $showReviewQuestionnaire) {
            if let recordId = coachViewModel?.lastTrainingRecordId {
                ReviewQuestionnaireView(trainingRecordId: recordId)
            }
        }
    }
    
    // MARK: - 训练选择视图
    
    private var trainingSelectionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 训练方法选择（如果未指定）
                if initialMethod == nil {
                    methodSelectionSection
                }
                
                // 训练模式选择
                modeSelectionSection
                
                // 语音引导开关
                voiceGuidanceSection
                
                Spacer(minLength: 20)
                
                // 开始训练按钮
                startTrainingButton
            }
            .padding()
        }
    }
    
    // MARK: - 方法选择区
    
    private var methodSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.core.training")
                    .foregroundColor(.accentColor)
                Text("选择训练方法")
                    .font(.headline)
            }
            
            if trainingViewModel.filteredMethods.isEmpty {
                // 加载中
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                // 方法列表
                ForEach(trainingViewModel.filteredMethods.prefix(5)) { method in
                    MethodSelectionCard(
                        method: method,
                        isSelected: selectedMethod?.id == method.id
                    ) {
                        selectedMethod = method
                    }
                }
            }
        }
        .onAppear {
            trainingViewModel.loadTrainingMethods()
        }
    }
    
    // MARK: - 模式选择区
    
    private var modeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.accentColor)
                Text("选择训练模式")
                    .font(.headline)
            }
            
            ForEach(TrainingMode.allCases, id: \.self) { mode in
                ModeSelectionCard(mode: mode, isSelected: selectedMode == mode) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMode = mode
                    }
                }
            }
        }
    }
    
    // MARK: - 语音引导设置
    
    private var voiceGuidanceSection: some View {
        HStack {
            Image(systemName: "speaker.wave.2.fill")
                .foregroundColor(.accentColor)
            Text("语音引导")
                .font(.subheadline)
            Spacer()
            Toggle("", isOn: Binding(
                get: { coachViewModel?.voiceGuidanceEnabled ?? true },
                set: { coachViewModel?.voiceGuidanceEnabled = $0 }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .scaleEffect(0.8)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 开始训练按钮
    
    private var startTrainingButton: some View {
        Button(action: startTraining) {
            HStack {
                Image(systemName: "play.fill")
                Text("开始训练")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(canStartTraining ? Color.accentColor : Color(.systemGray3))
            .cornerRadius(27)
        }
        .disabled(!canStartTraining)
    }
    
    /// 是否可以开始训练
    private var canStartTraining: Bool {
        selectedMethod != nil
    }
    
    // MARK: - 训练会话视图
    
    private func trainingSessionView(method: TrainingMethod, viewModel: CoachViewModel) -> some View {
        VStack(spacing: 0) {
            switch viewModel.sessionPhase {
            case .preparing:
                preparingView(viewModel: viewModel)
            case .training:
                trainingInProgressView(method: method, viewModel: viewModel)
            case .paused:
                pausedView(viewModel: viewModel)
            case .completed:
                completedView(method: method, viewModel: viewModel)
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - 倒计时准备视图
    
    private func preparingView(viewModel: CoachViewModel) -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 训练方法名称
            VStack(spacing: 8) {
                Image(systemName: selectedMethod?.category.icon ?? "figure.core.training")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                
                Text(selectedMethod?.name ?? "")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(selectedMode.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 倒计时
            CountdownTimerView(seconds: viewModel.countdownSeconds)
            
            Text("准备开始")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // 取消按钮
            Button(action: cancelTraining) {
                Text("取消")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - 训练进行中视图
    
    private func trainingInProgressView(method: TrainingMethod, viewModel: CoachViewModel) -> some View {
        VStack(spacing: 0) {
            // 顶部信息栏
            trainingTopBar(method: method, viewModel: viewModel)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // 环形计时器
                    TrainingTimerView(
                        progress: viewModel.completionRate,
                        timeDisplay: viewModel.remainingTimeDisplay,
                        phaseName: viewModel.actionPhase.displayText,
                        phaseColor: viewModel.actionPhase.color,
                        completedCycles: viewModel.completedCycles,
                        totalCycles: viewModel.totalCycles,
                        phaseProgress: viewModel.phaseProgress
                    )
                    
                    // 动作指令
                    actionInstructionView(viewModel: viewModel)
                    
                    // 呼吸引导
                    BreathingGuideView(
                        breathPhase: viewModel.breathPhase,
                        remainingSeconds: viewModel.breathRemainingSeconds
                    )
                    
                    // 已用时间
                    HStack {
                        Text("已用时")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.elapsedTimeDisplay)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            // 底部控制区
            trainingControlBar(viewModel: viewModel)
        }
    }
    
    // MARK: - 顶部信息栏
    
    private func trainingTopBar(method: TrainingMethod, viewModel: CoachViewModel) -> some View {
        HStack {
            // 方法名称
            VStack(alignment: .leading, spacing: 2) {
                Text(method.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(selectedMode.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 进度百分比
            Text("\(viewModel.progressPercent)%")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.accentColor)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    // MARK: - 动作指令视图
    
    private func actionInstructionView(viewModel: CoachViewModel) -> some View {
        VStack(spacing: 8) {
            // 当前阶段指令
            Text(viewModel.actionPhase.instruction)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // 阶段剩余时间
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.actionPhase.color)
                    .frame(width: 8, height: 8)
                
                Text(viewModel.actionPhase.displayText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(viewModel.actionPhase.color)
                
                if viewModel.phaseRemainingSeconds > 0 {
                    Text("· \(viewModel.phaseRemainingSeconds)秒")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(viewModel.actionPhase.color.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(viewModel.actionPhase.color.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - 底部控制栏
    
    private func trainingControlBar(viewModel: CoachViewModel) -> some View {
        HStack(spacing: 32) {
            // 暂停按钮
            Button(action: { viewModel.pauseTraining() }) {
                VStack(spacing: 4) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.accentColor)
                    Text("暂停")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .disabled(!viewModel.canPause)
            
            // 停止按钮
            Button(action: { viewModel.stopTraining() }) {
                VStack(spacing: 4) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.red)
                    Text("结束")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 语音开关
            Button(action: {
                viewModel.voiceGuidanceEnabled.toggle()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: viewModel.voiceGuidanceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.system(size: 24))
                        .foregroundColor(viewModel.voiceGuidanceEnabled ? .accentColor : .secondary)
                    Text("语音")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: -4, y: -2)
    }
    
    // MARK: - 暂停视图
    
    private func pausedView(viewModel: CoachViewModel) -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            // 暂停图标
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 8) {
                Text("训练暂停")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("已训练 \(viewModel.elapsedTimeDisplay)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("完成度 \(viewModel.progressPercent)%")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }
            
            Spacer()
            
            // 控制按钮
            VStack(spacing: 16) {
                // 继续按钮
                Button(action: { viewModel.resumeTraining() }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("继续训练")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.accentColor)
                    .cornerRadius(27)
                }
                
                // 结束按钮
                Button(action: { viewModel.stopTraining() }) {
                    Text("结束训练")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - 完成视图
    
    private func completedView(method: TrainingMethod, viewModel: CoachViewModel) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)
                
                // 完成图标
                ZStack {
                    Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }
                
                VStack(spacing: 8) {
                    Text("训练完成")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(method.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 训练统计
                completionStatsCard(viewModel: viewModel)
                
                // 操作按钮
                VStack(spacing: 12) {
                    // 填写复盘
                    if let recordId = viewModel.lastTrainingRecordId {
                        Button(action: { showReviewQuestionnaire = true }) {
                            HStack {
                                Image(systemName: "doc.text.magnifyingglass")
                                Text("填写复盘")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.orange)
                            .cornerRadius(27)
                        }
                    }
                    
                    // 返回陪练主页
                    Button(action: resetTraining) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("再来一次")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.accentColor)
                        .cornerRadius(27)
                    }
                    
                    // 返回训练详情
                    Button(action: cancelTraining) {
                        Text("返回训练列表")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
    }
    
    // MARK: - 完成统计卡片
    
    private func completionStatsCard(viewModel: CoachViewModel) -> some View {
        VStack(spacing: 16) {
            // 完成率
            VStack(spacing: 4) {
                Text("\(viewModel.progressPercent)%")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.accentColor)
                Text("完成度")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 详细统计
            HStack(spacing: 0) {
                statItem(icon: "clock", title: "时长", value: viewModel.elapsedTimeDisplay)
                
                Divider()
                    .frame(height: 40)
                
                statItem(icon: "repeat", title: "循环", value: "\(viewModel.completedCycles)")
                
                Divider()
                    .frame(height: 40)
                
                statItem(icon: "slider.horizontal.3", title: "模式", value: selectedMode.rawValue)
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .padding(.horizontal)
    }
    
    private func statItem(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Actions
    
    private func startTraining() {
        guard let method = selectedMethod else { return }
        
        // 创建ViewModel
        let viewModel = CoachViewModel(method: method, mode: selectedMode)
        coachViewModel = viewModel
        isTraining = true
        
        // 开始倒计时准备
        viewModel.startPreparation()
    }
    
    private func cancelTraining() {
        coachViewModel?.stopTraining()
        coachViewModel = nil
        isTraining = false
        selectedMethod = initialMethod
    }
    
    private func resetTraining() {
        coachViewModel = nil
        isTraining = false
        // 保持选中的方法和模式，方便重新开始
    }
}

// MARK: - 方法选择卡片

struct MethodSelectionCard: View {
    let method: TrainingMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // 图标
                Image(systemName: method.category.icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
                    .cornerRadius(10)
                
                // 信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(method.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text(method.difficulty.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("·")
                            .foregroundColor(.secondary)
                        
                        Text(method.defaultDuration.formattedDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.08) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 模式选择卡片（保留原有设计）

struct ModeSelectionCard: View {
    let mode: TrainingMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: modeIcon)
                            .foregroundColor(isSelected ? .accentColor : .secondary)
                        Text(mode.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.08) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var modeIcon: String {
        switch mode {
        case .basic: return "1.circle"
        case .progressive: return "chart.line.uptrend.xyaxis"
        case .interval: return "waveform.path.ecg"
        }
    }
}

// MARK: - Preview

#Preview("Coach Selection") {
    CoachView()
}

#Preview("Coach with Method") {
    CoachView(initialMethod: TrainingContentData.allTrainingMethods()[0])
}