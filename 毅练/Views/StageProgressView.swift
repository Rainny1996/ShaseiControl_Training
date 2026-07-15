import SwiftUI

/// 顶部训练阶段进度条：平静 → 控制 → 停止·恢复 → 完成，
/// 依据状态机自动高亮当前段，并显示当前轮次（第 N / 总轮）。
struct StageProgressView: View {
    let state: TrainingState
    let currentCycle: Int
    let totalCycles: Int
    /// 是否已进入过停止阶段：用于把「停止后回到低兴奋」高亮为独立「恢复」段
    let hasStopped: Bool

    private let segments = ["平静", "控制", "停止", "恢复", "完成"]

    /// 当前高亮段索引；prepare/arousal 返回 -1（暂不强调）。
    private var activeIndex: Int {
        switch state {
        case .lowArousal:            return hasStopped ? 3 : 0
        case .controlZone:           return 1
        case .stopWaiting, .squeeze: return 2
        case .ejaculateReady, .finished: return 4
        default:                     return -1
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<segments.count, id: \.self) { i in
                segmentDot(index: i)
                if i < segments.count - 1 {
                    connector(filled: i < activeIndex)
                }
            }
            Spacer(minLength: 12)
            Text("第 \(max(currentCycle, 1)) / \(totalCycles) 轮")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .glassEffect(in: Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private func segmentDot(index: Int) -> some View {
        let done = index < activeIndex
        let active = index == activeIndex
        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(dotColor(done: done, active: active))
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(active ? 0.9 : 0.35), lineWidth: active ? 2 : 1)
                    )
                if active {
                    Circle().fill(.white).frame(width: 6, height: 6)
                }
            }
            Text(segments[index])
                .font(.system(size: 11, weight: active ? .semibold : .regular))
                .foregroundColor(active ? .white : .white.opacity(0.6))
        }
    }

    private func connector(filled: Bool) -> some View {
        Rectangle()
            .fill(filled ? Color.white.opacity(0.85) : Color.white.opacity(0.25))
            .frame(width: 18, height: 2)
            .padding(.bottom, 14)
    }

    private func dotColor(done: Bool, active: Bool) -> Color {
        if active { return .white }
        if done { return .white.opacity(0.85) }
        return .clear
    }
}
