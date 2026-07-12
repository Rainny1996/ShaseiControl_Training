import SwiftUI

/// 训练主容器：根据状态机渲染对应子视图
struct TrainingContainerView: View {
    @ObservedObject var vm: TrainingViewModel

    var body: some View {
        Group {
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
                    onEjaculateReady: isFinal ? vm.onEjaculateReady : nil
                )
            case .stopWaiting:
                StopWaitingView(
                    countdown: vm.countdown,
                    cycle: vm.cycle,
                    totalCycles: vm.totalCycles,
                    onFallBackConfirmed: vm.onFallBackConfirmed,
                    onDoubleFingerHold: vm.onDoubleFingerHold
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
                EjaculateReadyView(onFinish: vm.end)
            case .finished:
                FinishedView(session: vm.lastSession, onHome: vm.dismissTraining)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: vm.state.rawStage)
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
}

/// 射精许可中间页
struct EjaculateReadyView: View {
    let onFinish: () -> Void
    var body: some View {
        ZStack {
            Color.ylPurple.ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                Text("释放时刻")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                Text("不要有压力，享受释放的感觉。")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Button(action: onFinish) {
                    Text("我已释放，完成训练")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .foregroundColor(.ylPurple)
                        .cornerRadius(24)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
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
            VStack(spacing: 20) {
                Text("回落似乎有些困难")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.ylText)
                Text("是否需要尝试“停止-挤压法”辅助？")
                    .font(.system(size: 16))
                    .foregroundColor(.ylTextSecondary)
                    .multilineTextAlignment(.center)
                VStack(spacing: 12) {
                    Button(action: onContinue) {
                        Text("继续等待")
                            .frame(maxWidth: .infinity).frame(height: 48)
                            .background(Color.ylBackground2).foregroundColor(.ylText).cornerRadius(24)
                    }
                    Button(action: onTry) {
                        Text("尝试挤捏法")
                            .frame(maxWidth: .infinity).frame(height: 48)
                            .background(Color.ylPurple).foregroundColor(.white).cornerRadius(24)
                    }
                }
            }
            .padding(28)
            .background(Color.ylBackground)
            .cornerRadius(24)
            .padding(.horizontal, 40)
        }
    }
}
