import SwiftUI

/// 可控区间（4-6分）：黄背景 + 中央超大按钮“我到了7分（立刻停止）”
struct ControlZoneView: View {
    let cycle: Int
    let totalCycles: Int
    let isFinal: Bool
    let onReachedSeven: () -> Void
    let onEjaculateReady: (() -> Void)?  // 仅最后一轮

    var body: some View {
        ZStack {
            Color.ylYellow.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                Text("快感可控（4-6分）")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.black)
                Text("第 \(cycle) / \(totalCycles) 轮")
                    .font(.system(size: 15))
                    .foregroundColor(.black.opacity(0.6))
                Text("保持在 5-6 分，享受")
                    .font(.system(size: 17))
                    .foregroundColor(.black.opacity(0.7))
                Spacer()
                VStack(spacing: 16) {
                    Button(action: onReachedSeven) {
                        Text("我到了 7 分\n（立刻停止）")
                            .font(.system(size: 28, weight: .bold))
                            .multilineTextAlignment(.center)
                            .frame(width: 260, height: 260)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .clipShape(Circle())
                    }
                    if let finalAction = onEjaculateReady {
                        Button(action: finalAction) {
                            Text("我已准备好射精")
                                .font(.system(size: 18, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.ylPurple)
                                .foregroundColor(.white)
                                .cornerRadius(24)
                        }
                        .padding(.horizontal, 32)
                    }
                }
                Spacer()
            }
        }
    }
}
