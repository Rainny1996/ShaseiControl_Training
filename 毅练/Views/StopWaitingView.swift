import SwiftUI

/// 7分调整等待：红背景 + 呼吸圆 + 倒计时 + 灰显激活按钮 + 双指长按
struct StopWaitingView: View {
    let countdown: Int
    let onFallBackConfirmed: () -> Void
    let onDoubleFingerHold: () -> Void

    @State private var isActivated: Bool = false
    @State private var doubleFingerStart: Date?

    var body: some View {
        ZStack {
            Color.ylRed.ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                Text("停止一切刺激")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                BreathingCircle(inhale: 4, exhale: 6, color: .green, showCountdown: countdown)
                    .onChange(of: countdown) { new in
                        if new == 0 { withAnimation { isActivated = true } }
                    }
                Text("硬度略降完全正常")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Button(action: isActivated ? onFallBackConfirmed : {}) {
                    Text(isActivated ? "回落完成，继续刺激" : "回落完成后按这里")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isActivated ? Color.white : Color.white.opacity(0.2))
                        .foregroundColor(isActivated ? .black : .white.opacity(0.5))
                        .cornerRadius(24)
                }
                .disabled(!isActivated)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        // 双指长按1秒触发挤捏法
        .overlay(
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    LongPressGesture(minimumDuration: 1.0)
                        .simultaneously(with: LongPressGesture(minimumDuration: 1.0))
                        .onEnded { _ in onDoubleFingerHold() }
                )
        )
    }
}
