import SwiftUI

/// 呼吸圆/光晕动画组件：呼/吸 4:6 秒节奏，颜色按阶段语义切换。
/// iOS 26 兼容版：用 Timer 驱动动画进度；新增 focusMode 供停止阶段以呼吸圆为视觉焦点。
struct BreathingCircle: View {
    /// 吸气时长（秒）
    let inhale: Double
    /// 呼气时长（秒）
    let exhale: Double
    /// 颜色
    let color: Color
    /// 是否显示倒计时数字
    var showCountdown: Int? = nil
    /// 焦点模式：呼吸圆作为视觉中心，倒计时数字移到圆下方并缩小（停止阶段使用）
    var focusMode: Bool = false
    /// 相位文字模式：在圆心显示「吸气 N / 呼气 N」，彻底隐藏倒计时（停止阶段使用）
    var showPhaseText: Bool = false

    @State private var elapsed: Double = 0

    private var total: Double { inhale + exhale }

    var body: some View {
        let t = elapsed.truncatingRemainder(dividingBy: total)
        let scale: CGFloat = t < inhale
            ? 0.7 + 0.3 * (t / inhale)
            : 1.0 - 0.3 * ((t - inhale) / exhale)
        let opacity: Double = t < inhale ? 0.5 + 0.5 * (t / inhale) : 1.0 - 0.5 * ((t - inhale) / exhale)

        let ring = ZStack {
            Circle()
                .fill(color.opacity(0.25 * opacity))
                .frame(width: 260, height: 260)
                .scaleEffect(scale * 1.2)
            Circle()
                .stroke(color, lineWidth: 4)
                .frame(width: 200, height: 200)
                .scaleEffect(scale)
        }

        Group {
            if focusMode {
                ZStack {
                    ring
                    if showPhaseText {
                        phaseLabel
                    } else if let count = showCountdown {
                        Text("\(count)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }
                }
            } else {
                ZStack {
                    ring
                    if let count = showCountdown {
                        Text("\(count)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }
                }
            }
        }
        .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
            elapsed += 0.05
        }
    }

    private var phaseLabel: some View {
        let t = elapsed.truncatingRemainder(dividingBy: total)
        let isInhale = t < inhale
        let remaining = Int(ceil(isInhale ? inhale - t : total - t))
        return VStack(spacing: 2) {
            Text(isInhale ? "吸气" : "呼气")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.white)
            Text("\(remaining)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
        }
    }
}

/// 暖色呼吸光晕（唤醒阶段）
struct WarmGlow: View {
    @State private var pulse = false
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color.orange.opacity(0.6), Color.clear],
                center: .center,
                startRadius: 40,
                endRadius: 200
            )
            .scaleEffect(pulse ? 1.15 : 0.9)
            .opacity(pulse ? 0.9 : 0.5)
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: pulse)
        }
        .onAppear { pulse = true }
    }
}
