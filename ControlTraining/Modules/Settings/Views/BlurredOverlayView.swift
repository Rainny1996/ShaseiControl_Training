import SwiftUI

/// 后台模糊遮罩视图
/// 应用进入后台时显示，防止多任务切换时暴露敏感内容
struct BlurredOverlayView: View {
    
    var body: some View {
        ZStack {
            // 模糊背景
            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
                .ignoresSafeArea()
            
            // 隐私保护文字
            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("隐私保护中")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("应用内容已隐藏")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}

/// UIKit模糊效果包装
struct VisualEffectView: UIViewRepresentable {
    
    let effect: UIVisualEffect?
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        UIVisualEffectView()
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
        uiView.effect = effect
    }
}

// MARK: - Preview

struct BlurredOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        BlurredOverlayView()
    }
}