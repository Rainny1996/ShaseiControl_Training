import SwiftUI

/// 7分调整等待：橙红渐变 + 呼吸圆焦点 + 倒计时下移 + 随时可点的回落按钮 + 双指长按
struct StopWaitingView: View {
    let countdown: Int
    let cycle: Int
    let totalCycles: Int
    let onFallBackConfirmed: () -> Void
    let onDoubleFingerHold: () -> Void
    let onEjaculated: () -> Void         // 右上角：中途射精，结束并记录

    @State private var appeared = false

    var body: some View {
        ZStack {
            // 双指长按手势只挂在背景层，绝不覆盖内容/按钮，避免拦截点击
            LinearGradient.ylStop
                .ignoresSafeArea()
                .gesture(
                    LongPressGesture(minimumDuration: 1.0)
                        .simultaneously(with: LongPressGesture(minimumDuration: 1.0))
                        .onEnded { _ in onDoubleFingerHold() }
                )
            // 右上角：中途射精按钮（独立层，不受背景手势影响）
            VStack {
                HStack {
                    Spacer()
                    CoachButton(title: "我已射精", style: .danger, height: 44) { onEjaculated() }
                        .frame(width: 110)
                        .padding(.top, 56)
                        .padding(.trailing, 16)
                }
                Spacer()
            }

            VStack(spacing: 18) {
                Spacer().frame(height: 28)
                VStack(spacing: 6) {
                    Text("🛑 停止刺激")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                    Text("第 \(cycle) / \(totalCycles) 轮")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                // 呼吸圆为视觉焦点：圆心显示吸气/呼气文字，彻底隐藏倒计时
                BreathingCircle(inhale: 4, exhale: 6, color: .white,
                                focusMode: true, showPhaseText: true)
                    .scaleEffect(appeared ? 1 : 0.92)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: appeared)

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        guidanceRow("深呼吸：呼—— 吸——")
                        guidanceRow("盆底完全放松")
                        guidanceRow("硬度下降属于正常现象")
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
                CoachButton(title: "恢复完成，继续刺激", style: .primary) { onFallBackConfirmed() }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 28)
            }
        }
        .onAppear { appeared = true }
    }

    private func guidanceRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.white.opacity(0.85))
            Text(text)
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.95))
        }
    }
}
