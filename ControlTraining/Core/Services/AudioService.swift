import Foundation
import AVFoundation

/// 音频服务，负责语音引导和音频播放
class AudioService {
    static let shared = AudioService()
    
    private var speechSynthesizer: AVSpeechSynthesizer?
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    private init() {
        speechSynthesizer = AVSpeechSynthesizer()
    }
    
    // MARK: - Text-to-Speech
    
    /// 朗读文本
    /// - Parameter text: 要朗读的文本
    /// - Parameter language: 语言代码，默认中文
    func speak(_ text: String, language: String = "zh-CN") {
        guard let synthesizer = speechSynthesizer else { return }
        
        // 停止当前朗读
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    /// 停止朗读
    func stopSpeaking() {
        speechSynthesizer?.stopSpeaking(at: .immediate)
    }
    
    // MARK: - Training Voice Guidance
    
    /// 训练开始提示
    func announceTrainingStart() {
        speak("训练即将开始，请做好准备")
    }
    
    /// 训练结束提示
    func announceTrainingEnd() {
        speak("训练结束，做得很好！")
    }
    
    /// 收缩提示
    func announceContract() {
        speak("收缩")
    }
    
    /// 放松提示
    func announceRelax() {
        speak("放松")
    }
    
    /// 休息提示
    func announceRest() {
        speak("休息")
    }
    
    /// 倒计时提示
    /// - Parameter seconds: 剩余秒数
    func announceCountdown(_ seconds: Int) {
        speak("\(seconds)")
    }
    
    /// 呼吸引导
    /// - Parameter phase: 呼吸阶段
    func announceBreathGuidance(_ phase: BreathPhase) {
        switch phase {
        case .inhale:
            speak("吸气")
        case .hold:
            speak("屏住")
        case .exhale:
            speak("呼气")
        }
    }
    
    // MARK: - Sound Effects
    
    /// 播放音效
    /// - Parameter name: 音效名称
    func playSoundEffect(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("Sound effect not found: \(name)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            audioPlayers[name] = player
        } catch {
            print("Failed to play sound effect: \(error)")
        }
    }
    
    /// 播放完成音效
    func playCompletionSound() {
        playSoundEffect("completion")
    }
    
    /// 播放打卡音效
    func playCheckInSound() {
        playSoundEffect("checkin")
    }
    
    // MARK: - Session Management
    
    /// 配置音频会话为后台播放模式
    /// 注意：音频会话已在AppDelegate中统一配置，此方法仅用于需要重新激活的场景
    func configureBackgroundPlayback() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate audio session: \(error)")
        }
    }
    
    /// 停止所有音频
    func stopAll() {
        speechSynthesizer?.stopSpeaking(at: .immediate)
        audioPlayers.values.forEach { $0.stop() }
        audioPlayers.removeAll()
    }
}

// MARK: - Breath Phase

/// 呼吸阶段
enum BreathPhase {
    case inhale   // 吸气
    case hold     // 屏住
    case exhale   // 呼气
}