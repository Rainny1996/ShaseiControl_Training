import SwiftUI

/// 停止-挤压法指导：紫色渐变 + 先提示动作，点击“开始挤压”后再倒计时
struct SqueezeView: View {
    let cycle: Int
    let totalCycles: Int
    let onSqueezeDone: () -> Void
    let onRetry: () -> Void
    let onEnd: () -> Void

    private let timer = TimerScheduler.shared
    @State private var isCounting: Bool = false
    @State private var remaining: Int = 8

    var body: some View {
        ZStack {
            LinearGradient.ylRelease.ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer().frame(height: 28)
                VStack(spacing: 6) {
                    Text("停止-挤压法")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    Text("第 \(cycle) / \(totalCycles) 轮")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                GlassCard {
                    Text("拇指按在龟头腹侧系带处，食指+中指放在背侧冠状沟，形成 V 字钳。用适中压力挤压 5-10 秒。")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.95))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                if isCounting {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 8)
                            .frame(width: 140, height: 140)
                        Circle()
                            .trim(from: 0, to: CGFloat(remaining) / 8.0)
                            .stroke(Color.white, lineWidth: 8)
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))
                        Text("\(remaining)")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.white)
                    }
                } else {
                    Text("准备好后，点击下方按钮开始挤压计时")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
                VStack(spacing: 12) {
                    if isCounting {
                        CoachButton(title: "挤压完成，继续训练", style: .primary) { onSqueezeDone() }
                    } else {
                        CoachButton(title: "开始挤压", style: .primary) { startCounting() }
                    }
                    HStack(spacing: 12) {
                        CoachButton(title: "再挤压一次", style: .secondary) { onRetry() }
                        CoachButton(title: "结束训练", style: .danger) { onEnd() }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
            Text("若疼痛不适，立即停止")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 12)
        }
    }

    private func startCounting() {
        isCounting = true
        remaining = 8
        timer.scheduleCountdown(from: 8) { r in remaining = r }
    }
}
