import SwiftUI
import Charts

/// 复盘主视图 - 统计概览、训练趋势图表、历史训练记录
struct ReviewView: View {
    
    @StateObject private var viewModel = ReviewViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 统计概览
                    statisticsOverview
                        .padding(.horizontal)
                    
                    // 训练频率趋势
                    frequencyTrendCard
                        .padding(.horizontal)
                    
                    // 能力变化趋势
                    abilityTrendCard
                        .padding(.horizontal)
                    
                    // 历史训练记录
                    trainingHistorySection
                        .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
                .padding(.top, 16)
            }
            .navigationTitle("训练复盘")
            .onAppear {
                viewModel.loadData()
            }
            .overlay {
                if viewModel.isLoading && viewModel.trainingRecords.isEmpty {
                    ProgressView("加载中...")
                }
            }
        }
    }
    
    // MARK: - 统计概览
    
    private var statisticsOverview: some View {
        VStack(spacing: 16) {
            Text("训练总览")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "训练次数",
                    value: "\(viewModel.totalTrainingCount)"
                )
                
                StatCard(
                    title: "总时长",
                    value: viewModel.formatDuration(viewModel.totalTrainingDuration)
                )
                
                StatCard(
                    title: "平均完成度",
                    value: viewModel.formatCompletionRate(viewModel.averageCompletion)
                )
                
                StatCard(
                    title: "平均自评",
                    value: String(format: "%.1f", viewModel.averageRating)
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 训练频率趋势
    
    private var frequencyTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.accentColor)
                Text("训练频率")
                    .font(.headline)
                Spacer()
                Text("近12周")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if viewModel.weeklyFrequency.isEmpty {
                emptyChartPlaceholder(message: "暂无训练数据")
            } else {
                Chart(viewModel.weeklyFrequency) { item in
                    BarMark(
                        x: .value("周", item.label),
                        y: .value("次数", item.count)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.gray.opacity(0.2))
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 能力变化趋势
    
    private var abilityTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                Text("能力变化")
                    .font(.headline)
                Spacer()
                
                // 图例
                HStack(spacing: 12) {
                    LegendItem(color: .accentColor, text: "评分")
                    LegendItem(color: .green, text: "完成度")
                }
            }
            
            if viewModel.abilityTrend.isEmpty {
                emptyChartPlaceholder(message: "暂无趋势数据")
            } else {
                Chart(viewModel.abilityTrend) { item in
                    LineMark(
                        x: .value("周", item.label),
                        y: .value("评分", item.averageRating)
                    )
                    .foregroundStyle(Color.accentColor)
                    .symbol { Circle().frame(width: 8, height: 8) }
                    
                    LineMark(
                        x: .value("周", item.label),
                        y: .value("完成度", item.averageCompletion * 5)
                    )
                    .foregroundStyle(Color.green)
                    .symbol { Circle().frame(width: 8, height: 8) }
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [4, 2]))
                }
                .frame(height: 180)
                .chartYScale(domain: 0...5)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 1, 2, 3, 4, 5]) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.gray.opacity(0.2))
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 历史训练记录
    
    private var trainingHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.clipboard.fill")
                    .foregroundColor(.accentColor)
                Text("训练记录")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.trainingRecords.count)条")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if viewModel.trainingRecords.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("还没有训练记录")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("完成训练后记录会出现在这里")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.trainingRecords.suffix(20).reversed()) { record in
                        TrainingRecordRow(
                            record: record,
                            methodName: viewModel.getMethodName(for: record.methodId),
                            reviewNote: viewModel.getReviewNote(for: record.id),
                            formatDuration: { viewModel.formatDuration($0) },
                            formatDate: { viewModel.formatDate($0) },
                            formatCompletion: { viewModel.formatCompletionRate($0) }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 空图表占位
    
    private func emptyChartPlaceholder(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.4))
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }
}

// MARK: - 图例项

private struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - 训练记录行

private struct TrainingRecordRow: View {
    let record: TrainingRecord
    let methodName: String
    let reviewNote: ReviewNote?
    let formatDuration: (TimeInterval) -> String
    let formatDate: (Date) -> String
    let formatCompletion: (Double) -> String
    
    var body: some View {
        HStack(spacing: 12) {
            // 左侧日期图标
            VStack(spacing: 4) {
                Image(systemName: "figure.core.training")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
            .frame(width: 36)
            
            // 中间信息
            VStack(alignment: .leading, spacing: 4) {
                Text(methodName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(formatDate(record.date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatDuration(record.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 右侧完成度和评分
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCompletion(record.completionRate))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(completionColor)
                
                // 自评星级
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= record.selfRating ? "star.fill" : "star")
                            .font(.system(size: 10))
                            .foregroundColor(star <= record.selfRating ? .yellow : .gray.opacity(0.2))
                    }
                }
            }
            
            // 复盘标记
            if reviewNote != nil {
                Image(systemName: "note.text.fill")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(10)
    }
    
    /// 完成度颜色
    private var completionColor: Color {
        if record.completionRate >= 0.8 { return .green }
        if record.completionRate >= 0.6 { return .orange }
        return .red
    }
}

// MARK: - Preview

#Preview {
    ReviewView()
}