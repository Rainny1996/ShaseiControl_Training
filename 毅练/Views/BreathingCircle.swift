import SwiftUI

/// 呼吸圆/光晕动画组件：呼/吸 4:6 秒节奏，颜色按阶段语义切换
/// iOS 15 兼容版本：用 Timer 驱动动画进度
struct BreathingCircle: View {
    /// 吸气时长（秒）
    let inhale: Double
    /// 呼气时长（秒）
    let exhale: Double
    /// 颜色
    let color: Color
    /// 是否显示倒计时数字（7分等待用）
    var showCountdown: Int? = nil

    @State private var elapsed: Double = 0

    private var total: Double { inhale + exhale }

    var body: some View {
        let t = elapsed.truncatingRemainder(dividingBy: total)
        let scale: CGFloat = t < inhale
            ? 0.7 + 0.3 * (t / inhale)
            : 1.0 - 0.3 * ((t - inhale) / exhale)
        let opacity: Double = t < inhale ? 0.5 + 0.5 * (t / inhale) : 1.0 - 0.5 * ((t - inhale) / exhale)

        ZStack {
            Circle()
                .fill(color.opacity(0.25 * opacity))
                .frame(width: 260, height: 260)
                .scaleEffect(scale * 1.2)
            Circle()
                .stroke(color, lineWidth: 4)
                .frame(width: 200, height: 200)
                .scaleEffect(scale)
            if let count = showCountdown {
                Text("\(count)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
            elapsed += 0.05
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
