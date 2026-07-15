import SwiftUI

/// 低兴奋区（1-3分）：绿渐变 + 教练式指导卡 + 卡片按钮
struct LowArousalView: View {
    let cycle: Int
    let totalCycles: Int
    let isFinal: Bool
    let onEnteredControl: () -> Void
    let onReachedSeven: () -> Void
    let onEjaculateReady: (() -> Void)?   // 仅最后一轮显示
    var hasStopped: Bool = false           // 是否已进入过停止阶段（用于显示「恢复中」）

    var body: some View {
        ZStack {
            LinearGradient.ylCalm.ignoresSafeArea()
            VStack(spacing: 18) {
                Spacer().frame(height: 28)
                VStack(spacing: 8) {
                    Text("平静期")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.black)
                    Text("1-3 分")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.black.opacity(0.7))
                    Text("第 \(cycle) / \(totalCycles) 轮")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black.opacity(0.55))
                    if hasStopped {
                        Text("恢复中")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.black.opacity(0.6))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.08))
                            .cornerRadius(8)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("教练指导")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black.opacity(0.6))
                        guidanceRow("保持自然呼吸")
                        guidanceRow("无需刻意刺激")
                    }
                }
                .padding(.horizontal, 24)

                HStack(spacing: 8) {
                    Image(systemName: "target").foregroundColor(.black.opacity(0.7))
                    Text("当前目标：进入 4-6 分")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.black)
                }

                Spacer()
                VStack(spacing: 12) {
                    CoachButton(title: "我进入 4-6 分了", style: .primary) { onEnteredControl() }
                    if let finalAction = onEjaculateReady {
                        CoachButton(title: "我已准备好射精", style: .primary) { finalAction() }
                    }
                    CoachButton(title: "我到了 7 分（停止）", style: .primary, height: 48) { onReachedSeven() }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 28)
            }
        }
    }

    private func guidanceRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.black.opacity(0.5))
            Text(text)
                .font(.system(size: 20))
                .foregroundColor(.black.opacity(0.85))
        }
    }
}
