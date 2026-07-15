import SwiftUI

/// 训练完成界面：柔和成功动画 + 统计玻璃卡
struct FinishedView: View {
    let session: TrainingSession?
    let onHome: () -> Void

    @State private var appeared = false

    private var durationText: String {
        guard let s = session else { return "--" }
        let m = s.totalDuration / 60
        let sec = s.totalDuration % 60
        return "\(m) 分 \(sec) 秒"
    }

    var body: some View {
        ZStack {
            LinearGradient.ylDark.ignoresSafeArea()
            VStack(spacing: 26) {
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.ylSuccess)
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)
                Text("训练完成")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.ylText)
                GlassCard {
                    VStack(spacing: 14) {
                        StatRow(label: "本次用时", value: durationText)
                        StatRow(label: "停止次数", value: "\(session?.cycleCount ?? 0)")
                        StatRow(label: "是否使用挤压法", value: (session?.usedSqueeze ?? false) ? "是" : "否")
                    }
                }
                .padding(.horizontal, 32)
                Text("你做得很好。保持规律训练，感受身体掌控力的提升。")
                    .font(.system(size: 22))
                    .foregroundColor(.ylTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
                CoachButton(title: "返回主页", style: .primary) { onHome() }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { appeared = true }
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundColor(.ylTextSecondary).font(.system(size: 16))
            Spacer()
            Text(value).foregroundColor(.ylText).font(.system(size: 16, weight: .semibold))
        }
    }
}
