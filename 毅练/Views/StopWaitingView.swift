import SwiftUI

/// 7分调整等待：红背景 + 呼吸圆 + 倒计时 + 随时可点的回落按钮 + 双指长按
struct StopWaitingView: View {
    let countdown: Int
    let cycle: Int
    let totalCycles: Int
    let onFallBackConfirmed: () -> Void
    let onDoubleFingerHold: () -> Void

    var body: some View {
        ZStack {
            Color.ylRed.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                Text("停止一切刺激")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                Text("第 \(cycle) / \(totalCycles) 轮")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.8))
                BreathingCircle(inhale: 4, exhale: 6, color: .green, showCountdown: countdown)
                Text("硬度略降完全正常")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Button(action: onFallBackConfirmed) {
                    Text("回落完成，继续刺激")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(24)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        // 双指长按1秒触发挤捏法（加在容器上，不拦截按钮点击）
        .gesture(
            LongPressGesture(minimumDuration: 1.0)
                .simultaneously(with: LongPressGesture(minimumDuration: 1.0))
                .onEnded { _ in onDoubleFingerHold() }
        )
    }
}
