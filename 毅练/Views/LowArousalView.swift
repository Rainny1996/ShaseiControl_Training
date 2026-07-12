import SwiftUI

/// 低兴奋区（1-3分）：绿背景 + 大按钮“我进入4-6分了” + 防误触小按钮“我到了7分”
struct LowArousalView: View {
    let cycle: Int
    let totalCycles: Int
    let isFinal: Bool
    let onEnteredControl: () -> Void
    let onReachedSeven: () -> Void
    let onEjaculateReady: (() -> Void)?   // 仅最后一轮显示

    var body: some View {
        ZStack {
            Color.ylGreen.ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                Text("平静期（1-3分）")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.black)
                Text("第 \(cycle) / \(totalCycles) 轮")
                    .font(.system(size: 15))
                    .foregroundColor(.black.opacity(0.6))
                Spacer()
                VStack(spacing: 16) {
                    Button(action: onEnteredControl) {
                        Text("我进入 4-6 分了")
                            .font(.system(size: 24, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 72)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(24)
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
                    }
                    Button(action: onReachedSeven) {
                        Text("我到了 7 分（停止）")
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.white.opacity(0.4))
                            .cornerRadius(24)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}
