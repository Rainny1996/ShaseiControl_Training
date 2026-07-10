import SwiftUI

/// 复盘问卷弹窗 - 训练结束后弹出，收集自我感受、训练难度、身体反应和文字备注
struct ReviewQuestionnaireView: View {
    
    /// 关联的训练记录ID
    let trainingRecordId: UUID
    
    /// 保存成功回调
    var onSaved: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ReviewViewModel()
    
    // MARK: - 问卷状态
    
    /// 自我感受评分 (1-5)
    @State private var feelingScore: Int = 0
    /// 训练难度评分 (1-5)
    @State private var difficultyScore: Int = 0
    /// 选中的身体反应标签
    @State private var selectedBodyReactions: Set<String> = []
    /// 自定义身体反应输入
    @State private var customBodyReaction: String = ""
    /// 文字备注
    @State private var notes: String = ""
    /// 是否正在保存
    @State private var isSaving: Bool = false
    /// 是否已保存
    @State private var hasSaved: Bool = false
    /// 显示提示
    @State private var showValidationAlert: Bool = false
    
    // MARK: - 身体反应预设选项
    
    private let bodyReactionOptions = [
        "肌肉酸胀", "轻微疲劳", "精力充沛",
        "呼吸顺畅", "心跳加速", "身体放松",
        "轻微不适", "出汗较多", "状态良好"
    ]
    
    // MARK: - 评分描述
    
    private let feelingDescriptions = [
        1: "很差",
        2: "较差",
        3: "一般",
        4: "较好",
        5: "很好"
    ]
    
    private let difficultyDescriptions = [
        1: "很轻松",
        2: "较轻松",
        3: "适中",
        4: "较困难",
        5: "很困难"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // 顶部提示
                    headerSection
                    
                    // 自我感受评分
                    feelingScoreSection
                    
                    // 训练难度评分
                    difficultyScoreSection
                    
                    // 身体反应选择
                    bodyReactionSection
                    
                    // 文字备注
                    notesSection
                    
                    // 保存按钮
                    saveButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .navigationTitle("训练复盘")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("跳过") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .alert("请完成评分", isPresented: $showValidationAlert) {
                Button("好的", role: .cancel) {}
            } message: {
                Text("请至少完成自我感受和训练难度评分")
            }
        }
    }
    
    // MARK: - 顶部提示
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(.accentColor)
            
            Text("记录你的训练感受")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }
    
    // MARK: - 自我感受评分
    
    private var feelingScoreSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "自我感受", icon: "face.smiling")
            
            // 星级评分
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { score in
                    Button(action: { feelingScore = score }) {
                        Image(systemName: score <= feelingScore ? "star.fill" : "star")
                            .font(.system(size: 32))
                            .foregroundColor(score <= feelingScore ? .yellow : .gray.opacity(0.3))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // 评分描述
            if feelingScore > 0 {
                Text(feelingDescriptions[feelingScore] ?? "")
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: feelingScore)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 训练难度评分
    
    private var difficultyScoreSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "训练难度", icon: "gauge.with.dots.needle.33percent")
            
            // 星级评分
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { score in
                    Button(action: { difficultyScore = score }) {
                        Image(systemName: score <= difficultyScore ? "star.fill" : "star")
                            .font(.system(size: 32))
                            .foregroundColor(score <= difficultyScore ? .orange : .gray.opacity(0.3))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // 评分描述
            if difficultyScore > 0 {
                Text(difficultyDescriptions[difficultyScore] ?? "")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: difficultyScore)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 身体反应选择
    
    private var bodyReactionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "身体反应", icon: "figure.core.training")
            
            // 预设标签
            FlowLayout(spacing: 8) {
                ForEach(bodyReactionOptions, id: \.self) { option in
                    BodyReactionTag(
                        text: option,
                        isSelected: selectedBodyReactions.contains(option),
                        action: {
                            if selectedBodyReactions.contains(option) {
                                selectedBodyReactions.remove(option)
                            } else {
                                selectedBodyReactions.insert(option)
                            }
                        }
                    )
                }
            }
            
            // 自定义输入
            HStack(spacing: 8) {
                TextField("其他反应...", text: $customBodyReaction)
                    .textFieldStyle(.roundedBorder)
                    .font(.subheadline)
                
                if !customBodyReaction.isEmpty {
                    Button(action: {
                        if !customBodyReaction.trimmingCharacters(in: .whitespaces).isEmpty {
                            selectedBodyReactions.insert(customBodyReaction.trimmingCharacters(in: .whitespaces))
                            customBodyReaction = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            
            // 已选自定义标签
            if selectedBodyReactions.contains(where: { !bodyReactionOptions.contains($0) }) {
                FlowLayout(spacing: 8) {
                    ForEach(Array(selectedBodyReactions.filter { !bodyReactionOptions.contains($0) }), id: \.self) { tag in
                        BodyReactionTag(
                            text: tag,
                            isSelected: true,
                            action: { selectedBodyReactions.remove(tag) }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 文字备注
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "训练心得", icon: "pencil.and.outline")
            
            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("记录今天的训练感受、进步或需要改进的地方...")
                        .font(.subheadline)
                        .foregroundColor(.placeholder)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 10)
                }
                
                TextEditor(text: $notes)
                    .font(.subheadline)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
            }
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - 保存按钮
    
    private var saveButton: some View {
        VStack(spacing: 8) {
            Button(action: saveReviewNote) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else if hasSaved {
                        Image(systemName: "checkmark")
                    }
                    Text(hasSaved ? "已保存" : "保存复盘")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(hasSaved ? Color.green : Color.accentColor)
                .cornerRadius(27)
            }
            .disabled(isSaving || hasSaved)
            
            Text("复盘数据仅自己可见，帮助你追踪进步")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 辅助视图
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.accentColor)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
    
    // MARK: - 保存操作
    
    private func saveReviewNote() {
        // 验证必填项
        guard feelingScore > 0 && difficultyScore > 0 else {
            showValidationAlert = true
            return
        }
        
        isSaving = true
        
        // 合并身体反应描述
        let bodyReactionText = selectedBodyReactions.sorted().joined(separator: "、")
        
        let reviewNote = ReviewNote(
            trainingRecordId: trainingRecordId,
            feelingScore: feelingScore,
            difficultyScore: difficultyScore,
            bodyReaction: bodyReactionText,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        viewModel.saveReviewNote(reviewNote)
        
        // 模拟短暂延迟以提供保存反馈
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isSaving = false
            hasSaved = true
            
            // 延迟关闭弹窗
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                onSaved?()
                dismiss()
            }
        }
    }
}

// MARK: - 身体反应标签

private struct BodyReactionTag: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                }
                Text(text)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.tertiarySystemGroupedBackground))
            .foregroundColor(isSelected ? .accentColor : .primary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 流式布局

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
    ReviewQuestionnaireView(trainingRecordId: UUID())
}