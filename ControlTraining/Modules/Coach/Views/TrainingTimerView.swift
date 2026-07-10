import SwiftUI

/// 环形进度计时器视图 - 显示训练进度和剩余时间
struct TrainingTimerView: View {
    
    /// 总进度（0.0 - 1.0）
    let progress: Double
    
    /// 剩余时间显示文本（MM:SS）
    let timeDisplay: String
    
    /// 当前阶段名称
    let phaseName: String
    
    /// 当前阶段颜色
    let phaseColor: Color
    
    /// 已完成循环数
    let completedCycles: Int
    
    /// 总循环数
    let totalCycles: Int
    
    /// 是否显示阶段进度
    var showPhaseProgress: Bool = true
    
    /// 阶段进度（0.0 - 1.0）
    var phaseProgress: Double = 0
    
    // MARK: - Animation
    
    @State private var pulseAnimation: Bool = false
    @State private var progressAnimation: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // 环形计时器
            ZStack {
                // 背景圆环
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 240, height: 240)
                
                // 进度圆环
                Circle()
                    .trim(from: 0, to: progressAnimation)
                    .stroke(
                        phaseColor.gradient,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 240, height: 240)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: phaseColor.opacity(0.3), radius: 8, x: 0, y: 0)
                
                // 阶段进度内环（如果启用）
                if showPhaseProgress {
                    Circle()
                        .trim(from: 0, to: phaseProgress)
                        .stroke(
                            phaseColor.opacity(0.3),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                }
                
                // 中心内容
                VStack(spacing: 6) {
                    // 时间显示
                    Text(timeDisplay)
                        .font(.system(size: 52, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                    
                    // 阶段名称
                    Text(phaseName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(phaseColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(phaseColor.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .scaleEffect(pulseAnimation ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
            .onAppear {
                pulseAnimation = true
                withAnimation(.easeInOut(duration: 0.5)) {
                    progressAnimation = progress
                }
            }
            .onChange(of: progress) { _, newValue in
                withAnimation(.easeInOut(duration: 0.5)) {
                    progressAnimation = newValue
                }
            }
            
            // 循环进度指示
            if totalCycles > 0 {
                cycleProgressView
            }
        }
    }
    
    // MARK: - Cycle Progress
    
    private var cycleProgressView: some View {
        VStack(spacing: 8) {
            // 循环进度条
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    ForEach(0..<totalCycles, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index < completedCycles ? phaseColor : Color(.systemGray5))
                            .frame(height: 4)
                    }
                }
            }
            .frame(height: 4)
            .padding(.horizontal)
            
            // 循环计数文本
            HStack {
                Text("循环进度")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(completedCycles)/\(totalCycles)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Countdown Timer View

/// 倒计时准备视图
struct CountdownTimerView: View {
    
    /// 剩余秒数
    let seconds: Int
    
    @State private var scaleAnimation: Bool = false
    @State private var opacityAnimation: Bool = false
    
    var body: some View {
        ZStack {
            // 背景脉冲圆
            Circle()
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: 280, height: 280)
                .scaleEffect(scaleAnimation ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: scaleAnimation)
            
            // 内圆
            Circle()
                .fill(Color.accentColor.opacity(0.05))
                .frame(width: 200, height: 200)
            
            // 数字
            Text("\(seconds)")
                .font(.system(size: 96, weight: .bold, design: .rounded))
                .foregroundColor(.accentColor)
                .scaleEffect(scaleAnimation ? 1.0 : 0.8)
                .opacity(opacityAnimation ? 1.0 : 0.5)
        }
        .onAppear {
            scaleAnimation = true
            opacityAnimation = true
        }
        .onChange(of: seconds) { _, _ in
            // 每次倒计时数字变化时触发动画
            scaleAnimation = false
            opacityAnimation = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                scaleAnimation = true
                opacityAnimation = true
            }
        }
    }
}

// MARK: - Phase Color Extension

extension TrainingActionPhase {
    /// 阶段对应颜色
    var color: Color {
        switch self {
        case .contract: return .blue
        case .relax: return .green
        case .rest: return .orange
        }
    }
}

// MARK: - Preview

#Preview("Training Timer") {
    TrainingTimerView(
        progress: 0.35,
        timeDisplay: "03:15",
        phaseName: "收缩",
        phaseColor: .blue,
        completedCycles: 5,
        totalCycles: 15,
        phaseProgress: 0.6
    )
}

#Preview("Countdown") {
    CountdownTimerView(seconds: 3)
}