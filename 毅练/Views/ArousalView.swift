import SwiftUI

/// 唤醒阶段（可选）：暖色呼吸光晕 + 勃起按钮
struct ArousalView: View {
    let onAroused: () -> Void
    let onExit: () -> Void

    var body: some View {
        ZStack {
            LinearGradient.ylDark.ignoresSafeArea()
            WarmGlow()
            VStack(spacing: 22) {
                Spacer()
                Text("请轻柔刺激，帮助自然勃起")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.ylText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Text("无需着急，保持放松")
                    .font(.system(size: 18))
                    .foregroundColor(.ylTextSecondary)
                Spacer()
                VStack(spacing: 16) {
                    CoachButton(title: "我已勃起，开始训练", style: .primary) { onAroused() }
                    Button(action: onExit) {
                        Text("退出训练")
                            .font(.system(size: 15))
                            .foregroundColor(.ylTextSecondary)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 28)
            }
        }
    }
}
