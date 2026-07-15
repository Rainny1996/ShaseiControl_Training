import SwiftUI

/// 训练准备流程：清单逐条淡入 + “我已准备好”
struct PrepareView: View {
    let onPrepared: () -> Void
    @State private var visibleRows: Int = 0

    private let items: [(icon: String, text: String, ok: Bool)] = [
        ("checkmark.circle.fill", "安静、私密、不受打扰的空间", true),
        ("checkmark.circle.fill", "已准备润滑剂（推荐）", true),
        ("checkmark.circle.fill", "手机电量充足，屏幕常亮", true),
        ("xmark.circle.fill", "禁止观看高刺激度视频 / 图片", false),
        ("xmark.circle.fill", "禁止播放 ASMR 或成人内容", false)
    ]

    var body: some View {
        ZStack {
            LinearGradient.ylDark.ignoresSafeArea()
            VStack(spacing: 22) {
                Spacer()
                Text("训练准备")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.ylText)
                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(0..<visibleRows, id: \.self) { i in
                            HStack(spacing: 12) {
                                Image(systemName: items[i].icon)
                                    .foregroundColor(items[i].ok ? .ylSuccess : .ylWarning)
                                Text(items[i].text)
                                    .font(.system(size: 20))
                                    .foregroundColor(.ylText)
                            }
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                        }
                    }
                }
                .padding(.horizontal, 24)
                Spacer()
                CoachButton(title: "我已准备好", style: .primary) { onPrepared() }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 28)
            }
        }
        .onAppear {
            for i in 0..<items.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                    withAnimation { visibleRows = i + 1 }
                }
            }
        }
    }
}
