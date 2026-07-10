import Foundation
import Combine
import SwiftUI

// MARK: - 训练会话阶段

/// 训练会话阶段
enum TrainingSessionPhase {
    case preparing    // 倒计时准备
    case training     // 训练进行中
    case paused       // 暂停
    case completed    // 训练完成
}

// MARK: - 训练动作阶段

/// 训练中的动作阶段
enum TrainingActionPhase {
    case contract     // 收缩
    case relax        // 放松
    case rest         // 休息
    
    var displayText: String {
        switch self {
        case .contract: return "收缩"
        case .relax: return "放松"
        case .rest: return "休息"
        }
    }
    
    var instruction: String {
        switch self {
        case .contract: return "收缩骨盆底肌，保持力量"
        case .relax: return "缓慢放松肌肉"
        case .rest: return "充分休息，准备下一组"
        }
    }
}

// MARK: - CoachViewModel

/// 实时陪练ViewModel - 管理训练会话状态、计时器、模式逻辑
class CoachViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 当前训练方法
    let method: TrainingMethod
    
    /// 当前训练模式
    @Published var trainingMode: TrainingMode
    
    /// 会话阶段
    @Published var sessionPhase: TrainingSessionPhase = .preparing
    
    /// 倒计时准备秒数
    @Published var countdownSeconds: Int = 3
    
    /// 训练已用时间（秒）
    @Published var elapsedSeconds: Int = 0
    
    /// 训练总时长（秒）
    @Published var totalDuration: Int
    
    /// 当前动作阶段
    @Published var actionPhase: TrainingActionPhase = .contract
    
    /// 当前阶段剩余时间
    @Published var phaseRemainingSeconds: Int = 0
    
    /// 当前呼吸阶段
    @Published var breathPhase: BreathPhase = .inhale
    
    /// 呼吸阶段剩余时间
    @Published var breathRemainingSeconds: Int = 0
    
    /// 完成率（0.0 - 1.0）
    @Published var completionRate: Double = 0.0
    
    /// 已完成循环数
    @Published var completedCycles: Int = 0
    
    /// 总循环数
    @Published var totalCycles: Int = 0
    
    /// 是否显示完成界面
    @Published var showCompletion: Bool = false
    
    /// 语音引导开关
    @Published var voiceGuidanceEnabled: Bool = true
    
    /// 最近保存的训练记录ID（用于复盘问卷关联）
    @Published var lastTrainingRecordId: UUID?
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var audioService: AudioService
    private var trainingRepository: TrainingRepository
    private var cancellables = Set<AnyCancellable>()
    
    /// 当前模式的阶段配置
    private var phaseSequence: [PhaseConfig] = []
    private var currentPhaseIndex: Int = 0
    
    // MARK: - Phase Configuration
    
    struct PhaseConfig {
        let action: TrainingActionPhase
        let duration: Int        // 秒
        let breathPhase: BreathPhase
        let breathDuration: Int  // 秒
    }
    
    // MARK: - Initialization
    
    init(method: TrainingMethod,
         mode: TrainingMode = .basic,
         audioService: AudioService = .shared,
         trainingRepository: TrainingRepository? = nil) {
        self.method = method
        self.trainingMode = mode
        self.totalDuration = Int(method.defaultDuration)
        self.audioService = audioService
        self.trainingRepository = trainingRepository ?? TrainingRepository()
        
        // 配置音频会话
        self.audioService.configureBackgroundPlayback()
        
        // 生成阶段序列
        generatePhaseSequence()
        
        // AC-2.9: 音频中断监听
        setupAudioInterruptionObserver()
        
        // AC-2.10: 后台/强制退出 — 保存部分记录
        setupBackgroundObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopTimer()
        audioService.stopAll()
    }
    
    /// AC-2.9: 来电/抢占音频中断 → 计时暂停 + 提示手动恢复
    private func setupAudioInterruptionObserver() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
            
            switch type {
            case .began:
                // 音频被抢占 → 暂停训练
                if self.sessionPhase == .training {
                    self.pauseTraining()
                }
            case .ended:
                // 音频恢复 → 提示用户手动恢复
                if let optionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        // 音频已恢复，但训练保持暂停，由用户手动恢复
                        break
                    }
                }
            @unknown default: break
            }
        }
    }
    
    /// AC-2.10: 强制退出 → 生成部分训练记录
    private func setupBackgroundObserver() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self,
                  self.sessionPhase == .training || self.sessionPhase == .paused
            else { return }
            
            // 保存部分训练记录（isPartial=true, completed=false）
            self.savePartialRecordOnBackground()
        }
    }
    
    /// 保存部分训练记录
    private func savePartialRecordOnBackground() {
        let record = TrainingRecord(
            methodId: method.id,
            duration: TimeInterval(elapsedSeconds),
            completionRate: completionRate,
            selfRating: 3,
            notes: "训练未完成（强制退出或切后台中断）",
            mode: trainingMode,
            isPartial: true
        )
        trainingRepository.saveTrainingRecord(record)
    }
    
    // MARK: - Phase Sequence Generation
    
    /// 根据训练模式生成阶段序列
    private func generatePhaseSequence() {
        phaseSequence.removeAll()
        
        switch trainingMode {
        case .basic:
            generateBasicPhases()
        case .progressive:
            generateProgressivePhases()
        case .interval:
            generateIntervalPhases()
        }
        
        totalCycles = phaseSequence.count
    }
    
    /// 基础模式：等长收缩-放松循环
    private func generateBasicPhases() {
        let contractDuration = 3
        let relaxDuration = 3
        let cycleCount = totalDuration / (contractDuration + relaxDuration)
        
        for _ in 0..<cycleCount {
            phaseSequence.append(PhaseConfig(action: .contract, duration: contractDuration, breathPhase: .inhale, breathDuration: contractDuration))
            phaseSequence.append(PhaseConfig(action: .relax, duration: relaxDuration, breathPhase: .exhale, breathDuration: relaxDuration))
        }
    }
    
    /// 渐进模式：递增收缩时长
    private func generateProgressivePhases() {
        let relaxDuration = 3
        var contractDuration = 3
        var elapsed = 0
        
        while elapsed < totalDuration {
            // 收缩阶段（递增）
            let actualContract = min(contractDuration, totalDuration - elapsed)
            if actualContract <= 0 { break }
            phaseSequence.append(PhaseConfig(action: .contract, duration: actualContract, breathPhase: .inhale, breathDuration: actualContract))
            elapsed += actualContract
            
            // 放松阶段
            if elapsed < totalDuration {
                let actualRelax = min(relaxDuration, totalDuration - elapsed)
                phaseSequence.append(PhaseConfig(action: .relax, duration: actualRelax, breathPhase: .exhale, breathDuration: actualRelax))
                elapsed += actualRelax
            }
            
            // 每3个循环增加1秒收缩时长，最大10秒
            if phaseSequence.count % 6 == 0 && contractDuration < 10 {
                contractDuration += 1
            }
        }
    }
    
    /// 间歇模式：收缩-放松交替 + 组间休息
    private func generateIntervalPhases() {
        let contractDuration = 5
        let relaxDuration = 2
        let cyclesPerSet = 5
        let restDuration = 10
        var cycleCount = 0
        var elapsed = 0
        
        while elapsed < totalDuration {
            // 收缩-放松循环
            for _ in 0..<cyclesPerSet {
                if elapsed >= totalDuration { break }
                
                // 收缩
                let actualContract = min(contractDuration, totalDuration - elapsed)
                phaseSequence.append(PhaseConfig(action: .contract, duration: actualContract, breathPhase: .inhale, breathDuration: actualContract))
                elapsed += actualContract
                
                // 放松
                if elapsed < totalDuration {
                    let actualRelax = min(relaxDuration, totalDuration - elapsed)
                    phaseSequence.append(PhaseConfig(action: .relax, duration: actualRelax, breathPhase: .exhale, breathDuration: actualRelax))
                    elapsed += actualRelax
                }
                
                cycleCount += 1
            }
            
            // 组间休息
            if elapsed < totalDuration && cycleCount > 0 {
                let actualRest = min(restDuration, totalDuration - elapsed)
                phaseSequence.append(PhaseConfig(action: .rest, duration: actualRest, breathPhase: .hold, breathDuration: actualRest))
                elapsed += actualRest
            }
        }
    }
    
    // MARK: - Timer Control
    
    /// 开始倒计时准备
    func startPreparation() {
        sessionPhase = .preparing
        countdownSeconds = 3
        
        if voiceGuidanceEnabled {
            audioService.announceTrainingStart()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tickPreparation()
        }
    }
    
    /// 开始训练
    func startTraining() {
        sessionPhase = .training
        elapsedSeconds = 0
        currentPhaseIndex = 0
        completedCycles = 0
        
        if !phaseSequence.isEmpty {
            let firstPhase = phaseSequence[0]
            actionPhase = firstPhase.action
            phaseRemainingSeconds = firstPhase.duration
            breathPhase = firstPhase.breathPhase
            breathRemainingSeconds = firstPhase.breathDuration
        }
        
        if voiceGuidanceEnabled {
            audioService.speak("训练开始")
        }
        
        startTimer()
    }
    
    /// 暂停训练
    func pauseTraining() {
        sessionPhase = .paused
        stopTimer()
        
        if voiceGuidanceEnabled {
            audioService.speak("训练暂停")
        }
    }
    
    /// 继续训练
    func resumeTraining() {
        sessionPhase = .training
        startTimer()
        
        if voiceGuidanceEnabled {
            audioService.speak("继续训练")
        }
    }
    
    /// 停止训练（提前结束）
    func stopTraining() {
        stopTimer()
        audioService.stopAll()
        completeTraining()
    }
    
    // MARK: - Private Timer Methods
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tickTraining()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func tickPreparation() {
        countdownSeconds -= 1
        
        if voiceGuidanceEnabled && countdownSeconds > 0 {
            audioService.announceCountdown(countdownSeconds)
        }
        
        if countdownSeconds <= 0 {
            stopTimer()
            startTraining()
        }
    }
    
    private func tickTraining() {
        elapsedSeconds += 1
        completionRate = Double(elapsedSeconds) / Double(totalDuration)
        
        // 更新动作阶段剩余时间
        phaseRemainingSeconds -= 1
        breathRemainingSeconds -= 1
        
        // 语音提示当前阶段
        if voiceGuidanceEnabled && phaseRemainingSeconds == 0 {
            announcePhaseTransition()
        }
        
        // 动作阶段切换
        if phaseRemainingSeconds <= 0 {
            completedCycles += 1
            currentPhaseIndex += 1
            
            if currentPhaseIndex >= phaseSequence.count {
                // 训练完成
                stopTimer()
                completeTraining()
                return
            }
            
            let nextPhase = phaseSequence[currentPhaseIndex]
            actionPhase = nextPhase.action
            phaseRemainingSeconds = nextPhase.duration
            breathPhase = nextPhase.breathPhase
            breathRemainingSeconds = nextPhase.breathDuration
        }
        
        // 呼吸阶段切换（在动作阶段内）
        if breathRemainingSeconds <= 0 && phaseRemainingSeconds > 0 {
            // 在同一动作阶段内切换呼吸
            breathPhase = nextBreathPhase(for: actionPhase)
            breathRemainingSeconds = min(phaseRemainingSeconds, breathDuration(for: breathPhase))
        }
        
        // 检查是否达到总时长
        if elapsedSeconds >= totalDuration {
            stopTimer()
            completeTraining()
        }
    }
    
    /// 获取下一个呼吸阶段
    private func nextBreathPhase(for action: TrainingActionPhase) -> BreathPhase {
        switch action {
        case .contract: return .hold
        case .relax: return .exhale
        case .rest: return .hold
        }
    }
    
    /// 获取呼吸阶段时长
    private func breathDuration(for phase: BreathPhase) -> Int {
        switch phase {
        case .inhale: return 3
        case .hold: return 2
        case .exhale: return 4
        }
    }
    
    /// 语音播报阶段切换
    private func announcePhaseTransition() {
        guard voiceGuidanceEnabled else { return }
        
        switch actionPhase {
        case .contract:
            audioService.announceContract()
        case .relax:
            audioService.announceRelax()
        case .rest:
            audioService.announceRest()
        }
    }
    
    // MARK: - Training Completion
    
    /// 完成训练
    private func completeTraining() {
        sessionPhase = .completed
        completionRate = min(1.0, Double(elapsedSeconds) / Double(totalDuration))
        showCompletion = true
        
        if voiceGuidanceEnabled {
            audioService.announceTrainingEnd()
        }
        
        // 自动保存训练记录
        saveTrainingRecord()
    }
    
    /// 保存训练记录
    private func saveTrainingRecord() {
        let record = TrainingRecord(
            methodId: method.id,
            duration: TimeInterval(elapsedSeconds),
            completionRate: completionRate,
            selfRating: 3,  // 默认评分，用户可在复盘时修改
            notes: "",
            mode: trainingMode
        )
        lastTrainingRecordId = record.id
        trainingRepository.saveTrainingRecord(record)
    }
    
    // MARK: - Computed Properties
    
    /// 格式化剩余时间
    var remainingTimeDisplay: String {
        let remaining = max(0, totalDuration - elapsedSeconds)
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// 格式化已用时间
    var elapsedTimeDisplay: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    /// 进度百分比
    var progressPercent: Int {
        Int(completionRate * 100)
    }
    
    /// 当前阶段进度（0.0-1.0）
    var phaseProgress: Double {
        guard currentPhaseIndex < phaseSequence.count else { return 1.0 }
        let totalPhaseDuration = phaseSequence[currentPhaseIndex].duration
        guard totalPhaseDuration > 0 else { return 1.0 }
        return 1.0 - Double(phaseRemainingSeconds) / Double(totalPhaseDuration)
    }
    
    /// 呼吸引导文本
    var breathGuidanceText: String {
        switch breathPhase {
        case .inhale: return "吸气"
        case .hold: return "屏住"
        case .exhale: return "呼气"
        }
    }
    
    /// 是否可以暂停
    var canPause: Bool {
        sessionPhase == .training
    }
    
    /// 是否可以继续
    var canResume: Bool {
        sessionPhase == .paused
    }
}