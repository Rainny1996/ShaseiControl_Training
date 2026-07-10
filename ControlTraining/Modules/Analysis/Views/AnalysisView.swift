import SwiftUI
import Charts

/// 状态分析主页面
struct AnalysisView: View {
    
    @StateObject private var viewModel = AnalysisViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 综合评分卡片
                overallScoreCard
                
                // 能力维度雷达图
                radarChartCard
                
                // 维度详情列表
                dimensionDetailCard
                
                // 历史趋势图表
                trendChartCard
                
                // 薄弱环节提示
                if viewModel.hasWeaknesses {
                    weaknessesCard
                }
                
                // 改善建议
                suggestionsCard
                
                // 推荐训练
                recommendationsCard
            }
            .padding()
        }
        .navigationTitle("状态分析")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadAnalysis()
        }
        .refreshable {
            viewModel.refresh()
        }
    }
    
    // MARK: - 综合评分卡片
    
    private var overallScoreCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("综合评分")
                    .font(.headline)
                Spacer()
                Text(viewModel.abilityLevel.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(colorForName(viewModel.levelColor).opacity(0.15))
                    .foregroundColor(colorForName(viewModel.levelColor))
                    .cornerRadius(12)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(viewModel.overallScore)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(colorForName(viewModel.scoreColor))
                
                Text("/ 100")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: viewModel.levelIcon)
                    .font(.system(size: 40))
                    .foregroundColor(colorForName(viewModel.levelColor).opacity(0.6))
            }
            
            Text(viewModel.scoreDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    // MARK: - 雷达图卡片
    
    private var radarChartCard: some View {
        VStack(spacing: 16) {
            Text("能力维度")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            RadarChartView(
                values: viewModel.dimensionScores.map { $0.score },
                labels: viewModel.dimensionScores.map { $0.name },
                weakDimensions: viewModel.weaknesses.map { $0.rawValue }
            )
            .frame(height: 260)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    // MARK: - 维度详情卡片
    
    private var dimensionDetailCard: some View {
        VStack(spacing: 12) {
            Text("维度详情")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(viewModel.dimensionScores, id: \.dimension) { item in
                HStack(spacing: 12) {
                    // 维度名称
                    Text(item.name)
                        .font(.subheadline)
                        .frame(width: 60, alignment: .leading)
                    
                    // 进度条
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray5))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(viewModel.isWeakness(item.dimension) ? Color.orange : colorForName(viewModel.levelColor))
                                .frame(width: geometry.size.width * item.score, height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    // 得分百分比
                    Text("\(Int(item.score * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.isWeakness(item.dimension) ? .orange : .secondary)
                        .frame(width: 40, alignment: .trailing)
                    
                    // 等级标签
                    Text(item.level)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(8)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if viewModel.selectedDimension == item.dimension {
                        viewModel.deselectDimension()
                    } else {
                        viewModel.selectDimension(item.dimension)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    // MARK: - 历史趋势卡片
    
    private var trendChartCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text(viewModel.selectedDimension != nil ? "\(viewModel.selectedDimension!.rawValue)趋势" : "综合评分趋势")
                    .font(.headline)
                
                Spacer()
                
                if viewModel.selectedDimension != nil {
                    Button("查看综合") {
                        viewModel.deselectDimension()
                    }
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
            }
            
            if viewModel.scoreTrend.isEmpty && viewModel.dimensionTrend.isEmpty {
                emptyChartPlaceholder(message: "暂无足够数据生成趋势图")
            } else {
                let data = viewModel.selectedDimension != nil ? viewModel.dimensionTrend : viewModel.scoreTrend
                
                Chart(data) { item in
                    LineMark(
                        x: .value("日期", item.date, unit: .day),
                        y: .value("评分", item.score)
                    )
                    .foregroundStyle(Color.accentColor)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("日期", item.date, unit: .day),
                        y: .value("评分", item.score)
                    )
                    .foregroundStyle(Color.accentColor.opacity(0.1))
                    .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: 0...100)
                .chartYAxis {
                    AxisMarks(position: .leading, values: .stride(by: 20)) {
                        AxisValueLabel()
                        AxisGridLine()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) {
                        AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
                        AxisGridLine()
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    // MARK: - 薄弱环节卡片
    
    private var weaknessesCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("薄弱环节")
                    .font(.headline)
                Spacer()
            }
            
            ForEach(viewModel.weaknesses, id: \.self) { weakness in
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text(weakness.rawValue)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(viewModel.levelForDimension(weakness))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    // MARK: - 改善建议卡片
    
    private var suggestionsCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("改善建议")
                    .font(.headline)
                Spacer()
            }
            
            if viewModel.suggestions.isEmpty {
                Text("暂无建议")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(viewModel.suggestions) { suggestion in
                    SuggestionRow(suggestion: suggestion)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    // MARK: - 推荐训练卡片
    
    private var recommendationsCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "figure.core.training")
                    .foregroundColor(.blue)
                Text("推荐训练")
                    .font(.headline)
                Spacer()
            }
            
            if viewModel.recommendations.isEmpty {
                Text("各维度发展均衡，继续当前训练计划")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(viewModel.recommendations, id: \.category) { rec in
                    HStack(spacing: 12) {
                        Image(systemName: iconForCategory(rec.category))
                            .foregroundColor(colorForName(categoryColor(rec.category)))
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(categoryName(rec.category))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(rec.reason)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    // MARK: - Helper Methods
    
    private func colorForName(_ name: String) -> Color {
        switch name {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "gray": return .gray
        default: return .accentColor
        }
    }
    
    private func iconForCategory(_ category: TrainingCategory) -> String {
        switch category {
        case .kegel: return "heart.circle.fill"
        case .stopStart: return "hand.raised.fill"
        case .squeeze: return "hand.point.right.fill"
        case .breathing: return "wind"
        case .pelvicFloor: return "figure.core.training"
        }
    }
    
    private func categoryColor(_ category: TrainingCategory) -> String {
        switch category {
        case .kegel: return "red"
        case .stopStart: return "blue"
        case .squeeze: return "purple"
        case .breathing: return "green"
        case .pelvicFloor: return "orange"
        }
    }
    
    private func categoryName(_ category: TrainingCategory) -> String {
        switch category {
        case .kegel: return "凯格尔运动"
        case .stopStart: return "停-动技术"
        case .squeeze: return "挤压技术"
        case .breathing: return "呼吸训练"
        case .pelvicFloor: return "骨盆底肌训练"
        }
    }
}

// MARK: - 建议行视图

struct SuggestionRow: View {
    let suggestion: ImprovementSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: suggestion.category.icon)
                    .foregroundColor(colorForCategory(suggestion.category))
                    .font(.caption)
                
                Text(suggestion.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(suggestion.priority.label)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(priorityColor.opacity(0.15))
                    .foregroundColor(priorityColor)
                    .cornerRadius(8)
            }
            
            Text(suggestion.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if let dimension = suggestion.relatedDimension {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.caption2)
                    Text(dimension.rawValue)
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var priorityColor: Color {
        switch suggestion.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
    
    private func colorForCategory(_ category: SuggestionCategory) -> Color {
        switch category {
        case .training: return .blue
        case .lifestyle: return .green
        case .general: return .orange
        }
    }
}

// MARK: - 空图表占位

private func emptyChartPlaceholder(message: String) -> some View {
    VStack(spacing: 8) {
        Image(systemName: "chart.line.flattrend.xyaxis")
            .font(.largeTitle)
            .foregroundColor(.secondary.opacity(0.5))
        Text(message)
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 40)
}