import SwiftUI
import Charts

/// 复盘报告视图 - 周/月复盘报告展示
struct ReviewReportView: View {
    
    @StateObject private var viewModel = ReviewViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 周/月切换
                    periodPicker
                        .padding(.horizontal)
                    
                    if let report = viewModel.currentReport {
                        // 报告内容
                        reportSummaryCard(report: report)
                            .padding(.horizontal)
                        
                        reportScoresCard(report: report)
                            .padding(.horizontal)
                        
                        highlightsCard(highlights: report.highlights)
                            .padding(.horizontal)
                        
                        improvementsCard(improvements: report.improvements)
                            .padding(.horizontal)
                        
                        suggestionsCard(suggestions: report.suggestions)
                            .padding(.horizontal)
                        
                        if !report.commonBodyReactions.isEmpty {
                            bodyReactionsCard(reactions: report.commonBodyReactions)
                                .padding(.horizontal)
                        }
                    } else {
                        // 无报告
                        noReportPlaceholder
                            .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding(.top, 16)
            }
            .navigationTitle("复盘报告")
            .onAppear {
                viewModel.loadData()
            }
        }
    }
    
    // MARK: - 周/月切换
    
    private var periodPicker: some View {
        Picker("报告周期", selection: $viewModel.selectedReportPeriod) {
            Text("周报").tag(ReportPeriod.weekly)
            Text("月报").tag(ReportPeriod.monthly)
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.selectedReportPeriod) { newPeriod in
            viewModel.switchReportPeriod(newPeriod)
        }
    }
    
    // MARK: - 报告摘要卡片
    
    private func reportSummaryCard(report: ReviewReport) -> some View {
        VStack(spacing: 16) {
            // 日期范围
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.accentColor)
                Text(report.dateRangeDisplay)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Divider()
            
            // 核心数据
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                SummaryItem(
                    icon: "figure.core.training",
                    title: "训练次数",
                    value: "\(report.totalSessions)次",
                    color: .accentColor
                )
                
                SummaryItem(
                    icon: "clock.fill",
                    title: "总时长",
                    value: report.totalDurationDisplay,
                    color: .blue
                )
                
                SummaryItem(
                    icon: "chart.pie.fill",
                    title: "平均完成度",
                    value: report.completionDisplay,
                    color: .green
                )
                
                SummaryItem(
                    icon: "star.fill",
                    title: "平均评分",
                    value: report.ratingDisplay,
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 复盘评分卡片
    
    private func reportScoresCard(report: ReviewReport) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundColor(.pink)
                Text("训练感受")
                    .font(.headline)
            }
            
            HStack(spacing: 16) {
                // 感受评分
                VStack(spacing: 8) {
                    Text("自我感受")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScoreRing(
                        value: report.averageFeelingScore,
                        maxValue: 5,
                        color: .accentColor
                    )
                    
                    Text(String(format: "%.1f", report.averageFeelingScore))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 80)
                
                // 难度评分
                VStack(spacing: 8) {
                    Text("训练难度")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScoreRing(
                        value: report.averageDifficultyScore,
                        maxValue: 5,
                        color: .orange
                    )
                    
                    Text(String(format: "%.1f", report.averageDifficultyScore))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 进步亮点卡片
    
    private func highlightsCard(highlights: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.green)
                Text("进步亮点")
                    .font(.headline)
            }
            
            if highlights.isEmpty {
                Text("暂无亮点数据，继续训练积累更多记录")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(highlights.enumerated()), id: \.offset) { index, highlight in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.subheadline)
                        
                        Text(highlight)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 待改进项卡片
    
    private func improvementsCard(improvements: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("待改进")
                    .font(.headline)
            }
            
            if improvements.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("目前没有需要改进的方面，保持良好状态！")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(Array(improvements.enumerated()), id: \.offset) { index, improvement in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.orange)
                            .font(.subheadline)
                        
                        Text(improvement)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 下期建议卡片
    
    private func suggestionsCard(suggestions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.blue)
                Text("下期建议")
                    .font(.headline)
            }
            
            if suggestions.isEmpty {
                Text("暂无建议，继续保持当前训练节奏")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                        
                        Text(suggestion)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 身体反应统计卡片
    
    private func bodyReactionsCard(reactions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "figure.core.training")
                    .foregroundColor(.purple)
                Text("常见身体反应")
                    .font(.headline)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(reactions, id: \.self) { reaction in
                    Text(reaction)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(16)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 无报告占位
    
    private var noReportPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.4))
            
            Text("暂无报告数据")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("完成更多训练后，系统将自动生成复盘报告")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - 摘要数据项

private struct SummaryItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 评分环

private struct ScoreRing: View {
    let value: Double
    let maxValue: Double
    let color: Color
    
    private var progress: Double {
        guard maxValue > 0 else { return 0 }
        return value / maxValue
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 6)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotation(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)
        }
        .frame(width: 60, height: 60)
    }
}

// MARK: - 流式布局（复用）

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            rowHeight = max(rowHeight, size.height)
            currentX += size.width + spacing
        }
        
        let totalHeight = currentY + rowHeight
        return (positions, CGSize(width: maxWidth, height: totalHeight))
    }
}

// MARK: - Preview

#Preview {
    ReviewReportView()
}