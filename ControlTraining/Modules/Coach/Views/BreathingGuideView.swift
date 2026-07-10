import SwiftUI

/// 呼吸引导动画视图 - 配合训练节奏展示呼吸动画
struct BreathingGuideView: View {
    
    /// 当前呼吸阶段
    let breathPhase: BreathPhase
    
    /// 呼吸阶段剩余时间（秒）
    let remainingSeconds: Int
    
    // MARK: - Animation States
    
    @State private var circleScale: CGFloat = 0.5
    @State private var glowOpacity: Double = 0.3
    @State private var textOpacity: Double = 1.0
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            // 呼吸引导圆
            ZStack {
                // 外层光晕
                Circle()
                    .fill(breathColor.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .scaleEffect(circleScale * 1.3)
                    .opacity(glowOpacity)
                
                // 主圆
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [breathColor.opacity(0.6), breathColor.opacity(0.2)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(circleScale)
                    .shadow(color: breathColor.opacity(0.3), radius: 10, x: 0, y: 0)
                
                // 内圆
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 80, height: 80)
                    .scaleEffect(circleScale)
                
                // 呼吸文字
                VStack(spacing: 4) {
                    Text(breathPhaseText)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(breathColor)
                        .opacity(textOpacity)
                    
                    if remainingSeconds > 0 {
                        Text("\(remainingSeconds)s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 160)
            
            // 呼吸引导说明
            Text(breathInstruction)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .onChange(of: breathPhase) { _, newPhase in
            updateAnimation(for: newPhase)
        }
        .onAppear {
            updateAnimation(for: breathPhase)
        }
    }
    
    // MARK: - Computed Properties
    
    /// 呼吸阶段颜色
    private var breathColor: Color {
        switch breathPhase {
        case .inhale: return .blue
        case .hold: return .orange
        case .exhale: return .green
        }
    }
    
    /// 呼吸阶段文字
    private var breathPhaseText: String {
        switch breathPhase {
        case .inhale: return "吸气"
        case .hold: return "屏住"
        case .exhale: return "呼气"
        }
    }
    
    /// 呼吸引导说明
    private var breathInstruction: String {
        switch breathPhase {
        case .inhale: return "缓缓吸气，感受腹部扩张"
        case .hold: return "屏住呼吸，保持专注"
        case .exhale: return "缓缓呼气，放松身体"
        }
    }
    
    // MARK: - Animation
    
    /// 根据呼吸阶段更新动画
    private func updateAnimation(for phase: BreathPhase) {
        withAnimation(.easeInOut(duration: breathAnimationDuration)) {
            switch phase {
            case .inhale:
                circleScale = 1.0
                glowOpacity = 0.6
                textOpacity = 1.0
            case .hold:
                circleScale = 1.0
                glowOpacity = 0.4
                textOpacity = 1.0
            case .exhale:
                circleScale = 0.5
                glowOpacity = 0.2
                textOpacity = 1.0
            }
        }
    }
    
    /// 呼吸动画持续时间
    private var breathAnimationDuration: Double {
        switch breathPhase {
        case .inhale: return 3.0
        case .hold: return 0.5
        case .exhale: return 4.0
        }
    }
}

// MARK: - Compact Breathing Guide

/// 紧凑版呼吸引导视图 - 用于训练界面底部
struct CompactBreathingGuideView: View {
    
    let breathPhase: BreathPhase
    let remainingSeconds: Int
    
    @State private var dotScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 12) {
            // 呼吸指示圆点
            Circle()
                .fill(breathColor)
                .frame(width: 12, height: 12)
                .scaleEffect(dotScale)
                .shadow(color: breathColor.opacity(0.5), radius: 4)
            
            // 呼吸阶段文字
            Text(breathPhaseText)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(breathColor)
            
            // 剩余时间
            if remainingSeconds > 0 {
                Text("· \(remainingSeconds)s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 呼吸波形
            breathWaveView
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(breathColor.opacity(0.08))
        .cornerRadius(20)
        .onChange(of: breathPhase) { _, newPhase in
            updateDotAnimation(for: newPhase)
        }
        .onAppear {
            updateDotAnimation(for: breathPhase)
        }
    }
    
    private var breathColor: Color {
        switch breathPhase {
        case .inhale: return .blue
        case .hold: return .orange
        case .exhale: return .green
        }
    }
    
    private var breathPhaseText: String {
        switch breathPhase {
        case .inhale: return "吸气"
        case .hold: return "屏住"
        case .exhale: return "呼气"
        }
    }
    
    /// 呼吸波形动画
    private var breathWaveView: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(breathColor.opacity(0.4))
                    .frame(width: 3, height: waveHeight(for: index))
            }
        }
    }
    
    private func waveHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 8
        let variation: CGFloat = breathPhase == .inhale ? CGFloat(index) * 4 : CGFloat(4 - index) * 4
        return baseHeight + variation
    }
    
    private func updateDotAnimation(for phase: BreathPhase) {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            switch phase {
            case .inhale:
                dotScale = 1.4
            case .hold:
                dotScale = 1.2
            case .exhale:
                dotScale = 0.8
            }
        }
    }
}

// MARK: - Preview

#Preview("Breathing Guide") {
    VStack(spacing: 40) {
        BreathingGuideView(breathPhase: .inhale, remainingSeconds: 3)
        BreathingGuideView(breathPhase: .hold, remainingSeconds: 2)
        BreathingGuideView(breathPhase: .exhale, remainingSeconds: 4)
    }
}

#Preview("Compact Breathing") {
    VStack(spacing: 20) {
        CompactBreathingGuideView(breathPhase: .inhale, remainingSeconds: 3)
        CompactBreathingGuideView(breathPhase: .hold, remainingSeconds: 2)
        CompactBreathingGuideView(breathPhase: .exhale, remainingSeconds: 4)
    }
}