import SwiftUI

/// 首页视图
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var appState: AppState
    
    @State private var showCheckInAnimation = false
    @State private var checkInButtonScale: CGFloat = 1.0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 问候与概览
                    greetingSection
                    
                    // 打卡状态卡片
                    checkInCard
                    
                    // 能力评分概览
                    abilityOverviewCard
                    
                    // 今日训练任务
                    todayTasksCard
                    
                    // 训练统计
                    trainingStatsCard
                    
                    // 快捷开始训练
                    quickStartButton
                }
                .padding()
            }
            .navigationTitle("控制训练")
            .refreshable {
                viewModel.refresh()
            }
        }
    }
    
    // MARK: - 问候与概览
    
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.greetingText)
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text(viewModel.encouragementText)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
    
    // MARK: - 打卡状态卡片
    
    private var checkInCard: some View {
        VStack(spacing: 16) {
            // 连续打卡天数展示
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("连续打卡")
                    .font(.headline)
                Spacer()
                
                NavigationLink(destination: CheckInView()) {
                    HStack(spacing: 4) {
                        Text("打卡详情")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            // 连续天数大字展示
            HStack(alignment: .firstTextBaseline) {
                Text("\(viewModel.consecutiveCheckInDays)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.orange)
                Text("天")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Spacer()
                
                // 打卡按钮
                Button(action: {
                    performCheckIn()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.todayCheckedIn ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                        Text(viewModel.todayCheckedIn ? "已打卡" : "打卡")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(viewModel.todayCheckedIn ? Color.green : Color.orange)
                    .cornerRadius(20)
                }
                .disabled(viewModel.todayCheckedIn)
                .scaleEffect(checkInButtonScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: checkInButtonScale)
            }
            
            // 今日状态提示
            if viewModel.todayCheckedIn {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("今日已打卡，继续保持！")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            } else {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("完成训练后记得打卡记录")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        .overlay {
            // 打卡成功动画
            if showCheckInAnimation {
                checkInSuccessOverlay
            }
        }
    }
    
    // MARK: - 打卡成功动画
    
    private var checkInSuccessOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .cornerRadius(16)
            
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
                    .scaleEffect(showCheckInAnimation ? 1.0 : 0.3)
                
                Text("打卡成功！")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("已连续\(viewModel.consecutiveCheckInDays)天")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding()
            .background(Color(.systemBackground).opacity(0.95))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        }
        .onAppear {
            // 自动隐藏动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showCheckInAnimation = false
                }
            }
        }
    }
    
    // MARK: - 执行打卡
    
    private func performCheckIn() {
        // 按钮缩放动画
        checkInButtonScale = 0.9
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            checkInButtonScale = 1.0
        }
        
        // 执行打卡
        viewModel.performCheckIn()
        
        // 显示成功动画
        if viewModel.todayCheckedIn {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showCheckInAnimation = true
            }
        }
    }
    
    // MARK: - 能力评分概览
    
    private var abilityOverviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.radar")
                    .foregroundColor(.blue)
                Text("能力评分")
                    .font(.headline)
                Spacer()
                
                NavigationLink(destination: AnalysisView()) {
                    HStack(spacing: 4) {
                        Text("详细分析")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text("\(viewModel.abilityScore)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(viewModel.scoreColor)
                Text("/ 100")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Spacer()
                Text(viewModel.abilityLevel.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(viewModel.scoreColor.opacity(0.15))
                    .foregroundColor(viewModel.scoreColor)
                    .cornerRadius(10)
            }
            
            // 维度进度条
            if viewModel.abilityScore > 0 {
                VStack(spacing: 8) {
                    dimensionProgressRow(label: "持久力", value: viewModel.dimensionScores.endurance, color: .red)
                    dimensionProgressRow(label: "控制力", value: viewModel.dimensionScores.control, color: .orange)
                    dimensionProgressRow(label: "恢复力", value: viewModel.dimensionScores.recovery, color: .green)
                    dimensionProgressRow(label: "呼吸配合", value: viewModel.dimensionScores.breathCoordination, color: .cyan)
                    dimensionProgressRow(label: "肌肉力量", value: viewModel.dimensionScores.muscleStrength, color: .purple)
                }
                .padding(.top, 4)
            }
            
            // 薄弱环节提示
            if !viewModel.weakDimensions.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("需加强：\(viewModel.weakDimensions.map { $0.rawValue }.joined(separator: "、"))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    // MARK: - 维度进度行
    
    private func dimensionProgressRow(label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 50, alignment: .leading)
            
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(.systemGray5))
                    .frame(height: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color)
                            .frame(width: geometry.size.width * min(value, 1.0), height: 6)
                    )
            }
            .frame(height: 6)
            
            Text("\(Int(value * 100))")
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 28, alignment: .trailing)
        }
    }
    
    // MARK: - 今日训练任务
    
    private var todayTasksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.checkmark")
                    .foregroundColor(.green)
                Text("今日训练")
                    .font(.headline)
                Spacer()
                
                if !viewModel.todayPlanItems.isEmpty {
                    Text("\(viewModel.todayPlanItems.filter { $0.isCompleted }.count)/\(viewModel.todayPlanItems.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if viewModel.todayPlanItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("暂无训练计划")
                        .foregroundColor(.secondary)
                    Text("去计划页面制定训练计划")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // 今日完成进度
                if viewModel.todayPlanItems.count > 0 {
                    let completedCount = viewModel.todayPlanItems.filter { $0.isCompleted }.count
                    let progress = Double(completedCount) / Double(viewModel.todayPlanItems.count)
                    
                    ProgressView(value: progress)
                        .tint(progress >= 1.0 ? .green : .accentColor)
                        .padding(.bottom, 4)
                }
                
                ForEach(viewModel.todayPlanItems) { item in
                    TodayTaskRow(item: item)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    // MARK: - 训练统计
    
    private var trainingStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar")
                    .foregroundColor(.purple)
                Text("训练统计")
                    .font(.headline)
                Spacer()
                
                NavigationLink(destination: ReviewView()) {
                    HStack(spacing: 4) {
                        Text("查看详情")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatMiniCard(title: "今日训练", value: "\(viewModel.todayTrainingCount)次", icon: "figure.strengthtraining.traditional", color: .green)
                StatMiniCard(title: "今日时长", value: viewModel.todayDurationText, icon: "clock", color: .blue)
                StatMiniCard(title: "本周训练", value: "\(viewModel.weekTrainingCount)次", icon: "calendar", color: .orange)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatMiniCard(title: "累计训练", value: "\(viewModel.totalTrainingCount)次", icon: "trophy", color: .yellow)
                StatMiniCard(title: "连续打卡", value: "\(viewModel.consecutiveCheckInDays)天", icon: "flame", color: .red)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    // MARK: - 快捷开始训练
    
    private var quickStartButton: some View {
        NavigationLink(destination: CoachView()) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                Text("开始训练")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(27)
            .shadow(color: .accentColor.opacity(0.3), radius: 8, y: 4)
        }
    }
}

// MARK: - 今日任务行

struct TodayTaskRow: View {
    let item: PlanItem
    
    var body: some View {
        HStack {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(item.isCompleted ? .green : .secondary)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.methodName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                    .strikethrough(item.isCompleted)
                
                Text(formatDuration(item.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if item.isCompleted {
                Text("已完成")
                    .font(.caption2)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(item.isCompleted ? Color(.systemGray6) : Color.clear)
        .cornerRadius(10)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)分钟"
    }
}

// MARK: - 统计迷你卡片

struct StatMiniCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}