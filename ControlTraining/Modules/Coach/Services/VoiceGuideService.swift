import Foundation
import AVFoundation

/// 语音引导服务 - 提供训练专用的语音引导编排
/// 封装AudioService，提供更高层次的训练语音引导功能
class VoiceGuideService {
    
    // MARK: - Singleton
    
    static let shared = VoiceGuideService()
    
    private let audioService: AudioService
    private var isSpeaking: Bool = false
    
    // MARK: - Configuration
    
    /// 语音引导是否启用
    var isEnabled: Bool = true
    
    /// 语速（0.0 - 1.0，默认正常语速）
    var speechRate: Float = AVSpeechUtteranceDefaultSpeechRate
    
    /// 音量（0.0 - 1.0）
    var volume: Float = 1.0
    
    private init(audioService: AudioService = .shared) {
        self.audioService = audioService
    }
    
    // MARK: - Session Lifecycle
    
    /// 配置训练会话音频环境
    func configureSession() {
        audioService.configureBackgroundPlayback()
    }
    
    /// 清理训练会话音频资源
    func cleanupSession() {
        audioService.stopAll()
        isSpeaking = false
    }
    
    // MARK: - Preparation Phase
    
    /// 播报训练准备开始
    func announcePreparationStart(methodName: String) {
        guard isEnabled else { return }
        speak("\(methodName)，训练即将开始，请做好准备")
    }
    
    /// 播报倒计时
    func announceCountdown(_ seconds: Int) {
        guard isEnabled else { return }
        audioService.announceCountdown(seconds)
    }
    
    /// 播报训练开始
    func announceTrainingStart() {
        guard isEnabled else { return }
        audioService.announceTrainingStart()
    }
    
    // MARK: - Training Phase Announcements
    
    /// 播报动作阶段切换
    func announceActionPhase(_ phase: TrainingActionPhase) {
        guard isEnabled else { return }
        switch phase {
        case .contract:
            audioService.announceContract()
        case .relax:
            audioService.announceRelax()
        case .rest:
            audioService.announceRest()
        }
    }
    
    /// 播报动作阶段详细指令
    func announceActionInstruction(_ phase: TrainingActionPhase) {
        guard isEnabled else { return }
        speak(phase.instruction)
    }
    
    /// 播报呼吸引导
    func announceBreathPhase(_ phase: BreathPhase) {
        guard isEnabled else { return }
        audioService.announceBreathGuidance(phase)
    }
    
    // MARK: - Training Control
    
    /// 播报训练暂停
    func announcePaused() {
        guard isEnabled else { return }
        speak("训练暂停")
    }
    
    /// 播报训练继续
    func announceResumed() {
        guard isEnabled else { return }
        speak("继续训练")
    }
    
    /// 播报训练提前结束
    func announceEarlyStop() {
        guard isEnabled else { return }
        speak("训练已停止")
    }
    
    // MARK: - Completion Phase
    
    /// 播报训练完成
    func announceTrainingComplete() {
        guard isEnabled else { return }
        audioService.announceTrainingEnd()
    }
    
    /// 播报训练完成详情
    func announceCompletionSummary(duration: Int, completionRate: Double) {
        guard isEnabled else { return }
        let minutes = duration / 60
        let seconds = duration % 60
        let percent = Int(completionRate * 100)
        
        if minutes > 0 {
            speak("训练完成，本次训练\(minutes)分\(seconds)秒，完成度\(percent)%")
        } else {
            speak("训练完成，本次训练\(seconds)秒，完成度\(percent)%")
        }
    }
    
    // MARK: - Step Guidance
    
    /// 播报训练步骤开始
    func announceStepStart(stepOrder: Int, stepTitle: String) {
        guard isEnabled else { return }
        speak("第\(stepOrder)步，\(stepTitle)")
    }
    
    /// 播报步骤完成提醒
    func announceStepComplete(nextStepTitle: String?) {
        guard isEnabled else { return }
        if let next = nextStepTitle {
            speak("本步骤完成，接下来\(next)")
        } else {
            speak("本步骤完成")
        }
    }
    
    // MARK: - Encouragement
    
    /// 播报鼓励语句
    func announceEncouragement() {
        guard isEnabled else { return }
        let encouragements = [
            "做得很好，继续保持",
            "保持节奏，你很棒",
            "坚持住，快要完成了",
            "注意呼吸，保持专注"
        ]
        if let encouragement = encouragements.randomElement() {
            speak(encouragement)
        }
    }
    
    /// 播报进度提醒
    func announceProgress(_ percent: Int) {
        guard isEnabled else { return }
        switch percent {
        case 25:
            speak("已完成四分之一")
        case 50:
            speak("已完成一半，继续加油")
        case 75:
            speak("已完成四分之三，快要结束了")
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    
    /// 朗读文本（带配置）
    private func speak(_ text: String) {
        guard isEnabled else { return }
        audioService.speak(text)
    }
}