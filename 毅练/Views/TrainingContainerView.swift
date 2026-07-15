import SwiftUI

/// 训练主容器：根据状态机渲染对应子视图，并在顶部显示训练阶段进度条
struct TrainingContainerView: View {
    @ObservedObject var vm: TrainingViewModel

    private var shouldShowProgress: Bool {
        // 完成页不显示阶段条
        if case .finished = vm.state { return false }
        return true
    }

    var body: some View {
        ZStack(alignment: .top) {
            contentForState
                .id(vm.state.rawStage)
                .transition(.opacity.combined(with: .scale(scale: 0.98)))

            if shouldShowProgress {
                StageProgressView(
                    state: vm.state,
                    currentCycle: vm.cycle,
                    totalCycles: vm.totalCycles,
                    hasStopped: vm.hasStopped
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.8), value: vm.state.rawStage)
        .overlay(
            vm.showSqueezePrompt ?
            SqueezePromptOverlay(onContinue: vm.continueWaiting, onTry: vm.trySqueeze) : nil
        )
        .onChange(of: vm.state) { new in
            if case .stopWaiting = new {
                // 倒计时结束（按钮激活）后，再等待 10 秒监控，若用户仍未确认则弹挤捏法提示
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(max(vm.countdown, 0)) + 10) {
                    if case .stopWaiting = vm.state { vm.showSqueezePromptIfNeeded() }
                }
            }
        }
    }

    @ViewBuilder
    private var contentForState: some View {
        switch vm.state {
        case .prepare:
            PrepareView(onPrepared: vm.onPrepared)
        case .arousal:
            ArousalView(onAroused: vm.onAroused, onExit: vm.dismissTraining)
        case .lowArousal(let cycle, let isFinal):
            LowArousalView(
                cycle: cycle,
                totalCycles: vm.totalCycles,
                isFinal: isFinal,
                onEnteredControl: vm.onEnteredControl,
                onReachedSeven: vm.onReachedSeven,
                onEjaculateReady: isFinal ? vm.onEjaculateReady : nil
            )
        case .controlZone(_, let isFinal):
            ControlZoneView(
                cycle: vm.cycle,
                totalCycles: vm.totalCycles,
                isFinal: isFinal,
                onReachedSeven: vm.onReachedSeven,
                onEjaculateReady: isFinal ? vm.onEjaculateReady : nil,
                onEjaculated: vm.onEjaculated
            )
        case .stopWaiting:
            StopWaitingView(
                countdown: vm.countdown,
                cycle: vm.cycle,
                totalCycles: vm.totalCycles,
                onFallBackConfirmed: vm.onFallBackConfirmed,
                onDoubleFingerHold: vm.onDoubleFingerHold,
                onEjaculated: vm.onEjaculated
            )
        case .squeeze:
            SqueezeView(
                cycle: vm.cycle,
                totalCycles: vm.totalCycles,
                onSqueezeDone: vm.onSqueezeDone,
                onRetry: vm.onSqueezeRetry,
                onEnd: vm.onSqueezeEnd
            )
        case .ejaculateReady:
            EjaculateReadyView(
                onFinish: vm.end,
                totalCycles: vm.totalCycles,
                usedSqueeze: vm.machine.usedSqueeze
            )
        case .finished:
            FinishedView(session: vm.lastSession, onHome: vm.dismissTraining)
        }
    }
}

/// 射精许可中间页（释放仪式感）
struct EjaculateReadyView: View {
    let onFinish: () -> Void
    let totalCycles: Int
    let usedSqueeze: Bool

    var body: some View {
        ZStack {
            LinearGradient.ylRelease.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                Text("🎉 训练完成")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("今天完成")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        checkRow("完成 \(totalCycles) 轮训练")
                        checkRow("控制训练完成")
                        checkRow(usedSqueeze ? "已用挤捏法放松" : "放松训练完成")
                    }
                }
                .padding(.horizontal, 24)
                Text("现在可以自然射精\n无需继续控制，享受释放即可")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                Spacer()
                CoachButton(title: "结束训练", systemImage: "checkmark.seal.fill", style: .primary) {
                    onFinish()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }

    private func checkRow(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white)
            Text(text)
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.95))
        }
    }
}

/// 挤捏法弹窗
struct SqueezePromptOverlay: View {
    let onContinue: () -> Void
    let onTry: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            GlassCard(padding: 24) {
                VStack(spacing: 18) {
                    Text("回落似乎有些困难")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.ylText)
                    Text("是否需要尝试“停止-挤压法”辅助？")
                        .font(.system(size: 16))
                        .foregroundColor(.ylTextSecondary)
                        .multilineTextAlignment(.center)
                    VStack(spacing: 12) {
                        CoachButton(title: "继续等待", style: .secondary) { onContinue() }
                        CoachButton(title: "尝试挤捏法", style: .primary) { onTry() }
                    }
                }
            }
            .padding(.horizontal, 40)
        }
    }
}
