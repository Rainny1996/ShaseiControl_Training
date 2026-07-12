import Foundation
import Combine

/// 训练状态机：单一事实来源，驱动阶段流转、超时、循环计数与射精许可逻辑
final class TrainingStateMachine: ObservableObject {
    @Published private(set) var state: TrainingState = .prepare
    @Published private(set) var countdownRemaining: Int = 0
    @Published private(set) var currentCycle: Int = 0

    let config: TrainingConfig
    private let voice: VoiceService
    private let timer: TimerScheduler
    private let haptic = HapticManager.shared

    // 统计
    private(set) var startTime: Date = Date()
    private(set) var stopCount: Int = 0
    private(set) var usedSqueeze: Bool = false
    private(set) var controlEnteredAt: Date?
    private(set) var controlDurations: [Int] = []
    private(set) var prematureEjaculation: Bool = false
    private(set) var brakePoint: Float = 7.0

    /// 阶段计时：进入每个状态的时间点，用于结算上一状态时长
    private var enteredStateAt: Date?
    /// 每轮各阶段时长聚合：phaseByCycle[cycle-1][stage] = 秒数
    private(set) var phaseByCycle: [[String: Double]] = []

    private var monitorBag = Set<AnyCancellable>()

    init(config: TrainingConfig, voice: VoiceService, timer: TimerScheduler) {
        self.config = config
        self.voice = voice
        self.timer = timer
        self.startTime = Date()
        self.enteredStateAt = self.startTime
    }

    // MARK: - 事件入口
    func send(_ event: TrainingEvent) {
        switch (state, event) {
        case (.prepare, .prepared):
            transitionTo(config.enableArousal ? .arousal : .lowArousal(cycle: 1, isFinal: isFinalCycle(1)))
        case (.arousal, .aroused):
            transitionTo(.lowArousal(cycle: 1, isFinal: isFinalCycle(1)))
        case (.lowArousal, .enteredControl):
            controlEnteredAt = Date()
            transitionTo(.controlZone(cycle: currentCycleOfState, isFinal: isFinalOfState))
        case (.controlZone, .reachedSeven):
            stopCount += 1
            brakePoint = 7.0
            if let entered = controlEnteredAt {
                controlDurations.append(Int(Date().timeIntervalSince(entered)))
            }
            startFallBack(count: currentCycleOfState)
        case (.stopWaiting, .fallBackConfirmed):
            completeCycle(count: currentCycleOfState)
        case (.stopWaiting, .doubleFingerHold):
            enterSqueeze(count: currentCycleOfState)
        case (.stopWaiting, .squeezeTriggered):
            enterSqueeze(count: currentCycleOfState)
        case (.stopWaiting, .continueWaiting):
            continueWaitingExtended(count: currentCycleOfState)
        case (.stopWaiting, .timeout):
            // 10秒监控超时：不自动跳转，由 UI 弹出挤捏法提醒
            break
        case (.squeeze, .squeezeDone):
            usedSqueeze = true
            transitionTo(.lowArousal(cycle: currentCycleOfState, isFinal: isFinalCycle(currentCycleOfState)))
        case (.squeeze, .squeezeRetry):
            enterSqueeze(count: currentCycleOfState)
        case (.squeeze, .squeezeEnd):
            finish()
        case (.lowArousal, .ejaculateReady), (.controlZone, .ejaculateReady):
            transitionTo(.ejaculateReady)
        case (.ejaculateReady, .finish):
            finish()
        case (.controlZone, .prematureEjaculation):
            prematureEjaculation = true
            finish()
        case (.controlZone, .ejaculated), (.stopWaiting, .ejaculated):
            prematureEjaculation = true
            finish()
        default:
            break
        }
    }

    // MARK: - 阶段切换
    private func transitionTo(_ newState: TrainingState) {
        settleCurrentPhase() // 结算上一个状态在该轮中的累计时长
        enteredStateAt = Date()
        state = newState
        timer.cancelAll()
        voice.stopAndClear()
        switch newState {
        case .prepare:
            voice.speak(VoiceScripts.prepare)
        case .arousal:
            currentCycle = 1
            voice.speak(VoiceScripts.arousalLoop, loop: true, interval: 15)
            // 3分钟超时提醒
            timer.scheduleOnce(seconds: 180) { [weak self] in
                self?.voice.speak(VoiceScripts.arousalTimeout)
            }
        case .lowArousal(let cycle, let isFinal):
            currentCycle = cycle
            if isFinal {
                voice.speak(VoiceScripts.lowArousalFinal)
            } else {
                voice.speak(VoiceScripts.lowArousal)
            }
            // 3分钟无操作询问
            timer.scheduleOnce(seconds: 180) { [weak self] in
                self?.voice.speak(VoiceScripts.lowArousalTimeout)
            }
        case .controlZone(_, let isFinal):
            if isFinal {
                voice.speak(VoiceScripts.controlZoneFinal)
            } else {
                voice.speak(VoiceScripts.controlZone)
            }
            if config.enableControlReminder {
                timer.scheduleRepeating(seconds: 20) { [weak self] in
                    self?.voice.speak(VoiceScripts.controlReminder)
                }
            }
        case .stopWaiting:
            voice.speak(VoiceScripts.sevenStopGuide) // 一次性30秒完整引导
            startFallBack(count: currentCycleOfState)
        case .squeeze:
            voice.speak(VoiceScripts.squeezeGuide)
        case .ejaculateReady:
            voice.speak(VoiceScripts.ejaculateReady)
        case .finished:
            voice.speak(VoiceScripts.finished)
        }
    }

    // MARK: - 回落倒计时
    private func startFallBack(count: Int) {
        state = .stopWaiting(cycle: count, isFinal: isFinalCycle(count))
        countdownRemaining = config.fallBackDuration
        timer.scheduleCountdown(from: config.fallBackDuration) { [weak self] remaining in
            guard let self else { return }
            self.countdownRemaining = remaining
            if remaining == 15 {
                self.voice.speak(VoiceScripts.fallBack15s)
            }
            if remaining == 0 {
                self.activateFallBackButton()
            }
        }
    }

    private func activateFallBackButton() {
        // 按钮激活 + 10秒无操作监控
        timer.scheduleOnce(seconds: 10) { [weak self] in
            self?.send(.timeout)
        }
    }

    /// 回落超时后"继续等待"：再延长30秒，重复一次10秒监控（仅限一次）
    private func continueWaitingExtended(count: Int) {
        timer.cancelAll()
        voice.stopAndClear()
        state = .stopWaiting(cycle: count, isFinal: isFinalCycle(count))
        countdownRemaining = 30
        timer.scheduleCountdown(from: 30) { [weak self] remaining in
            guard let self else { return }
            self.countdownRemaining = remaining
            if remaining == 0 {
                self.activateFallBackButton()
            }
        }
    }

    // MARK: - 循环完成
    private func completeCycle(count: Int) {
        if count >= config.cycleCount {
            // 最后一轮完成，进入射精许可前的低兴奋区保留按钮
            transitionTo(.lowArousal(cycle: count, isFinal: true))
        } else {
            transitionTo(.lowArousal(cycle: count + 1, isFinal: isFinalCycle(count + 1)))
        }
    }

    private func enterSqueeze(count: Int) {
        usedSqueeze = true
        transitionTo(.squeeze(cycle: count))
    }

    private func finish() {
        settleCurrentPhase() // 结算最后一个阶段时长
        timer.cancelAll()
        voice.stopAndClear()
        transitionTo(.finished)
    }

    // MARK: - 阶段时长结算
    /// 结算当前状态自 enteredStateAt 起经历的时长，累加到对应轮次与阶段。
    /// 仅循环阶段（低兴奋/控制区/停止回落/挤捏）计入 phaseByCycle，索引 = cycle - 1。
    /// 非循环阶段（准备/唤醒/射精许可/完成）不计入，避免污染轮次明细。
    private func settleCurrentPhase() {
        guard let entered = enteredStateAt else { return }
        let elapsed = Date().timeIntervalSince(entered)
        guard elapsed > 0 else { return }
        guard let cycle = cycleOfCurrentStateIfCyclic() else { return }
        let stage = state.rawStage
        let cycleIndex = cycle - 1
        if phaseByCycle.count <= cycleIndex {
            while phaseByCycle.count <= cycleIndex {
                phaseByCycle.append([String: Double]())
            }
        }
        phaseByCycle[cycleIndex][stage, default: 0] += elapsed
    }

    /// 若当前状态为循环阶段（低兴奋/控制区/停止回落/挤捏），返回其 cycle，否则 nil
    private func cycleOfCurrentStateIfCyclic() -> Int? {
        switch state {
        case .lowArousal(let c, _), .controlZone(let c, _), .stopWaiting(let c, _), .squeeze(let c):
            return c
        default:
            return nil
        }
    }

    // MARK: - 辅助
    private var currentCycleOfState: Int {
        switch state {
        case .lowArousal(let c, _), .controlZone(let c, _), .stopWaiting(let c, _), .squeeze(let c):
            return c
        default:
            return currentCycle
        }
    }

    private var isFinalOfState: Bool {
        switch state {
        case .lowArousal(_, let f), .controlZone(_, let f), .stopWaiting(_, let f):
            return f
        default:
            return false
        }
    }

    private func isFinalCycle(_ cycle: Int) -> Bool {
        return cycle >= config.cycleCount
    }
}
