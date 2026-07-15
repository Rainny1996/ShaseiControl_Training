import SwiftUI

/// 可控区间（4-6分）：暖橙黄渐变 + 目标卡/自检清单 + 醒目圆形停止按钮
struct ControlZoneView: View {
    let cycle: Int
    let totalCycles: Int
    let isFinal: Bool
    let onReachedSeven: () -> Void
    let onEjaculateReady: (() -> Void)?  // 仅最后一轮
    let onEjaculated: () -> Void         // 右上角：中途射精，结束并记录

    var body: some View {
        ZStack {
            LinearGradient.ylControl.ignoresSafeArea()
            // 右上角：中途射精按钮
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
                VStack(spacing: 8) {
                    Text("快感可控")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.black)
                    Text("4-6 分")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.black.opacity(0.7))
                    Text("第 \(cycle) / \(totalCycles) 轮")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black.opacity(0.55))
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "target").foregroundColor(.black.opacity(0.7))
                            Text("当前目标：保持 5-6 分")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.black)
                        }
                        checkRow("呼吸放慢")
                        checkRow("盆底放松")
                        checkRow("手速放慢")
                        checkRow("不要追求高潮")
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
                // 醒目圆形「我到了 7 分」按钮
                Button(action: onReachedSeven) {
                    VStack(spacing: 4) {
                        Text("我到了 7 分")
                            .font(.system(size: 26, weight: .bold))
                        Text("立刻停止")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.black)
                    .frame(width: 220, height: 220)
                }
                .glassEffect(in: Circle())

                if let finalAction = onEjaculateReady {
                    CoachButton(title: "我已准备好射精", style: .primary) { finalAction() }
                        .padding(.horizontal, 32)
                }
                Spacer().frame(height: 28)
            }
        }
    }

    private func checkRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.black.opacity(0.55))
            Text(text)
                .font(.system(size: 20))
                .foregroundColor(.black.opacity(0.85))
        }
    }
}
