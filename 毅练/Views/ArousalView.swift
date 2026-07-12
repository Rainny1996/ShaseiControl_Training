import SwiftUI

/// 唤醒阶段（可选）：暖色呼吸光晕 + 勃起按钮
struct ArousalView: View {
    let onAroused: () -> Void
    let onExit: () -> Void
    var body: some View {
        ZStack {
            Color.ylBackground.ignoresSafeArea()
            WarmGlow()
            VStack(spacing: 28) {
                Spacer()
                Text("请轻柔刺激，帮助自然勃起")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.ylText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Text("无需着急，保持放松")
                    .font(.system(size: 17))
                    .foregroundColor(.ylTextSecondary)
                Spacer()
                VStack(spacing: 16) {
                    Button(action: onAroused) {
                        Text("我已勃起，开始训练")
                            .font(.system(size: 20, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(24)
                    }
                    Button(action: onExit) {
                        Text("退出训练")
                            .font(.system(size: 15))
                            .foregroundColor(.ylTextSecondary)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}
