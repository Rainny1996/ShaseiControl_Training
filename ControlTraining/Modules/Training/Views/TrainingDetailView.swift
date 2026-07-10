import SwiftUI

/// 训练方法详情视图 - 展示原理、步骤、注意事项等完整信息
struct TrainingDetailView: View {
    let method: TrainingMethod
    @ObservedObject var viewModel: TrainingViewModel
    
    @State private var selectedTab: DetailTab = .overview
    @State private var showStartTraining = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 顶部信息区
                headerSection
                
                // 标签切换
                tabBar
                
                // 内容区
                tabContent
            }
        }
        .navigationTitle(method.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    viewModel.toggleFavorite(methodId: method.id)
                }) {
                    Image(systemName: method.isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(method.isFavorite ? .red : .primary)
                }
            }
        }
        .sheet(isPresented: $showStartTraining) {
            NavigationStack {
                TrainingPreparationView(method: method)
            }
        }
    }
    
    // MARK: - 顶部信息区
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // 分类和难度
            HStack {
                // 分类标签
                HStack(spacing: 6) {
                    Image(systemName: method.category.icon)
                        .font(.caption)
                    Text(method.category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(.accentColor)
                .cornerRadius(8)
                
                // 难度标签
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.difficultyColor(for: method.difficulty))
                        .frame(width: 8, height: 8)
                    Text(method.difficulty.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.difficultyColor(for: method.difficulty).opacity(0.1))
                .foregroundColor(Color.difficultyColor(for: method.difficulty))
                .cornerRadius(8)
                
                Spacer()
            }
            
            // 关键信息卡片
            HStack(spacing: 12) {
                InfoCard(icon: "clock", title: "时长", value: method.defaultDuration.formattedDuration)
                InfoCard(icon: "list.number", title: "步骤", value: "\(method.steps.count)步")
                InfoCard(icon: "exclamationmark.triangle", title: "注意", value: "\(method.precautions.count)项")
            }
            
            // 开始训练按钮
            Button(action: {
                showStartTraining = true
            }) {
                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("开始训练")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    // MARK: - 标签切换
    
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 6) {
                        Text(tab.title)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundColor(selectedTab == tab ? .primary : .secondary)
                        
                        Rectangle()
                            .fill(selectedTab == tab ? Color.accentColor : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - 内容区
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:
            overviewContent
        case .steps:
            stepsContent
        case .notes:
            notesContent
        }
    }
    
    // MARK: - 概览内容
    
    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 简介
            SectionCard(title: "简介", icon: "doc.text") {
                Text(method.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(6)
            }
            
            // 训练原理
            SectionCard(title: "训练原理", icon: "lightbulb") {
                Text(method.principle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(6)
            }
            
            // 预期效果
            SectionCard(title: "预期效果", icon: "chart.line.uptrend.xyaxis") {
                Text(method.expectedEffect)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(6)
            }
            
            // 适用人群
            SectionCard(title: "适用人群", icon: "person.2") {
                Text(method.targetAudience)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(6)
            }
            
            // 相关训练推荐
            let related = viewModel.relatedMethods(to: method)
            if !related.isEmpty {
                SectionCard(title: "相关训练", icon: "link") {
                    VStack(spacing: 10) {
                        ForEach(related) { relatedMethod in
                            NavigationLink(destination: TrainingDetailView(method: relatedMethod, viewModel: viewModel)) {
                                HStack {
                                    Image(systemName: relatedMethod.category.icon)
                                        .foregroundColor(.accentColor)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(relatedMethod.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                        Text(relatedMethod.difficulty.rawValue)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            
                            if relatedMethod.id != related.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - 步骤内容
    
    private var stepsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 步骤总览
            HStack {
                Text("共\(method.steps.count)个步骤")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("预计\(method.defaultDuration.formattedDuration)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            // 步骤列表
            ForEach(method.steps) { step in
                TrainingStepCard(step: step, totalSteps: method.steps.count)
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - 注意事项内容
    
    private var notesContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 注意事项标题
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("注意事项")
                    .font(.headline)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            // 注意事项列表
            VStack(spacing: 12) {
                ForEach(Array(method.precautions.enumerated()), id: \.offset) { index, precaution in
                    HStack(alignment: .top, spacing: 12) {
                        // 序号
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 28, height: 28)
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        
                        // 内容
                        Text(precaution)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
                }
            }
            .padding(.horizontal)
            
            // 安全提示
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "shield.checkered")
                        .foregroundColor(.green)
                    Text("安全提示")
                        .font(.headline)
                }
                
                Text("如在训练过程中出现任何不适，请立即停止训练并咨询专业医生。本应用提供的训练方法仅供参考，不能替代专业医疗建议。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding()
            .background(Color.green.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.bottom, 12)

            // AC-C.2 / AC-C.5: 来源标注 + 禁忌人群
            if let source = method.source, !source.isEmpty {
                sourceAttributionSection(source)
            }
            if let contraindication = method.contraindication, !contraindication.isEmpty {
                contraindicationSection(contraindication)
            }

            // 安全提示
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "shield.checkered")
                        .foregroundColor(.green)
                    Text("安全提示")
                        .font(.headline)
                }
                
                Text("如在训练过程中出现任何不适，请立即停止训练并咨询专业医生。本应用提供的训练方法仅供参考，不能替代专业医疗建议。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding()
            .background(Color.green.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }

    // MARK: - AC-C.2 来源标注
    private func sourceAttributionSection(_ source: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "books.vertical")
                    .foregroundColor(.indigo)
                Text("参考文献 / 来源")
                    .font(.headline)
            }
            Text(source)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color.indigo.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.indigo.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.bottom, 12)
    }

    // MARK: - AC-C.5 禁忌人群
    private func contraindicationSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.2.slash")
                    .foregroundColor(.red)
                Text("禁忌人群 / 不适用情况")
                    .font(.headline)
            }
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.bottom, 12)
    }
}

// MARK: - 详情标签枚举

enum DetailTab: String, CaseIterable {
    case overview = "概览"
    case steps = "步骤"
    case notes = "注意"
    
    var title: String { rawValue }
}

// MARK: - 信息卡片

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

// MARK: - 区块卡片

struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .font(.subheadline)
                Text(title)
                    .font(.headline)
            }
            
            content
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - 训练步骤卡片

struct TrainingStepCard: View {
    let step: TrainingStep
    let totalSteps: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // 步骤序号和连接线
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 32, height: 32)
                    Text("\(step.order)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                if step.order < totalSteps {
                    Rectangle()
                        .fill(Color.accentColor.opacity(0.3))
                        .frame(width: 2, height: 30)
                }
            }
            
            // 步骤内容
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(step.title)
                        .font(.headline)
                    
                    if let duration = step.duration {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(duration.formattedDuration)
                                .font(.caption)
                        }
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                
                Text(step.instruction)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding(.bottom, step.order < totalSteps ? 8 : 0)
        }
        .padding(.horizontal)
    }
}

// MARK: - 训练准备视图 - 连接陪练模块

struct TrainingPreparationView: View {
    let method: TrainingMethod
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMode: TrainingMode = .basic
    @State private var navigateToCoach = false
    
    var body: some View {
        VStack(spacing: 24) {
            // 训练方法信息
            VStack(spacing: 12) {
                Image(systemName: method.category.icon)
                    .font(.system(size: 50))
                    .foregroundColor(.accentColor)
                
                Text(method.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 12) {
                    Label(method.difficulty.rawValue, systemImage: "signal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(method.defaultDuration.formattedDuration, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(method.steps.count)步骤", systemImage: "list.number")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 20)
            
            // 训练模式选择
            VStack(alignment: .leading, spacing: 12) {
                Text("选择训练模式")
                    .font(.headline)
                
                ForEach(TrainingMode.allCases, id: \.self) { mode in
                    PreparationModeCard(mode: mode, isSelected: selectedMode == mode) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMode = mode
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // 开始训练按钮
            Button(action: { navigateToCoach = true }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("开始训练")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.accentColor)
                .cornerRadius(27)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .navigationTitle("训练准备")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $navigateToCoach) {
            CoachView(initialMethod: method)
        }
    }
}

// MARK: - 准备页模式选择卡片

struct PreparationModeCard: View {
    let mode: TrainingMode
    let isSelected: Bool
    let action: () -> Void
    
    private var modeIcon: String {
        switch mode {
        case .basic: return "1.circle"
        case .progressive: return "chart.line.uptrend.xyaxis"
        case .interval: return "waveform.path.ecg"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: modeIcon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 36, height: 36)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .padding(12)
            .background(isSelected ? Color.accentColor.opacity(0.08) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        TrainingDetailView(
            method: TrainingContentData.allTrainingMethods()[0],
            viewModel: TrainingViewModel()
        )
    }
}