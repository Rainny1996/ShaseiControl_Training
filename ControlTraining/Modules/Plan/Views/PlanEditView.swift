import SwiftUI

/// 当前计划逐条编辑（需求 11 / AC-11.1~11.7）
/// 编辑态为 `PlanViewModel.editingDraft` 内存副本，取消不落库（AC-11.5）。
struct PlanEditView: View {
    @ObservedObject var viewModel: PlanViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var validationErrors: [PlanViewModel.PlanEditValidationError] = []
    @State private var showAddMethodPicker = false
    
    var body: some View {
        NavigationStack {
            Group {
                if let draft = viewModel.editingDraft {
                    editContent(draft: draft)
                } else {
                    ProgressView("加载中...")
                }
            }
            .navigationTitle("编辑计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.cancelPlanEdits()
                    }
                    .accessibilityLabel("取消编辑")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        validationErrors = viewModel.savePlanEdits()
                    }
                    .disabled(viewModel.editingDraft == nil)
                    .accessibilityLabel("保存计划修改")
                }
            }
            .alert("无法保存", isPresented: Binding(
                get: { !validationErrors.isEmpty },
                set: { if !$0 { validationErrors = [] } }
            )) {
                Button("我知道了", role: .cancel) { validationErrors = [] }
            } message: {
                Text(validationErrors.first?.message ?? "")
            }
        }
    }
    
    // MARK: - 编辑内容
    
    private func editContent(draft: PlanEditDraft) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if draft.items.isEmpty {
                    Text("暂无训练项目，点击下方添加")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else {
                    ForEach(draft.items) { item in
                        PlanEditItemRow(
                            item: item,
                            startDate: draft.startDate,
                            endDate: draft.endDate,
                            viewModel: viewModel
                        )
                    }
                }
                
                // 新增项目（从方法池选择，AC-11.3）
                Button(action: { showAddMethodPicker = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("添加训练项目")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(.accentColor)
                    .cornerRadius(12)
                }
                .accessibilityLabel("添加训练项目")
            }
            .padding()
        }
        .sheet(isPresented: $showAddMethodPicker) {
            methodPickerSheet(title: "选择新增训练方法") { method in
                let date = viewModel.editingDraft?.startDate ?? Date()
                viewModel.addItem(method: method, date: date)
                showAddMethodPicker = false
            }
        }
    }
    
    // MARK: - 方法选择 sheet
    
    private func methodPickerSheet(title: String, onSelect: @escaping (TrainingMethod) -> Void) -> some View {
        NavigationStack {
            List(TrainingContentData.allTrainingMethods()) { method in
                Button(action: { onSelect(method) }) {
                    HStack {
                        Image(systemName: method.category.icon)
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(method.name).font(.subheadline)
                            Text(method.difficulty.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .accessibilityLabel("选择 \(method.name)")
                }
                .buttonStyle(.plain)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { showAddMethodPicker = false }
                }
            }
        }
    }
}

/// 单条计划项编辑行（需求 11 / AC-11.2/11.3/11.5）
private struct PlanEditItemRow: View {
    let item: PlanItem
    let startDate: Date
    let endDate: Date
    @ObservedObject var viewModel: PlanViewModel
    
    @State private var showMethodPicker = false
    
    /// 当前项（从 viewModel.editingDraft 实时读取，避免绑定到陈旧值）
    private var liveItem: PlanItem? {
        viewModel.editingDraft?.items.first(where: { $0.id == item.id })
    }
    
    private var minutes: Binding<Int> {
        Binding(
            get: { Int((liveItem?.duration ?? 0) / 60) },
            set: { viewModel.editItemDuration(item.id, duration: TimeInterval($0 * 60)) }
        )
    }
    
    private var selectedDate: Binding<Date> {
        Binding(
            get: { liveItem?.date ?? startDate },
            set: { viewModel.editItemDate(item.id, date: $0) }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 训练方法（点击 → 替换）
            Button(action: { showMethodPicker = true }) {
                HStack {
                    Text(liveItem?.methodName ?? item.methodName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
                .accessibilityLabel("训练方法 \(liveItem?.methodName ?? item.methodName)，点击替换")
            }
            .buttonStyle(.plain)
            
            // 单次训练时长（分钟）
            Stepper(value: minutes, in: 1...180, step: 1) {
                Text("时长：\(minutes.wrappedValue) 分钟")
                    .font(.subheadline)
            }
            .accessibilityLabel("训练时长 \(minutes.wrappedValue) 分钟")
            
            // 所在日期（限定在计划周期内）
            DatePicker(
                "训练日期",
                selection: selectedDate,
                in: startDate...endDate,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            
            // 删除
            Button(action: { viewModel.removeItem(item.id) }) {
                HStack {
                    Image(systemName: "trash")
                    Text("删除此项")
                }
                .font(.subheadline)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
                .accessibilityLabel("删除训练项目")
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .sheet(isPresented: $showMethodPicker) {
            methodPickerSheet
        }
    }
    
    private var methodPickerSheet: some View {
        NavigationStack {
            List(TrainingContentData.allTrainingMethods()) { method in
                Button(action: {
                    viewModel.editItemMethod(item.id, method: method)
                    showMethodPicker = false
                }) {
                    HStack {
                        Image(systemName: method.category.icon)
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(method.name).font(.subheadline)
                            Text(method.difficulty.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .accessibilityLabel("选择 \(method.name)")
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("选择训练方法")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { showMethodPicker = false }
                }
            }
        }
    }
}

#Preview {
    let vm: PlanViewModel = {
        let vm = PlanViewModel()
        let items = [
            PlanItem(date: Date(),
                     methodId: TrainingContentData.allTrainingMethods()[0].id,
                     methodName: TrainingContentData.allTrainingMethods()[0].name,
                     duration: 300)
        ]
        vm.editingDraft = PlanEditDraft(
            planId: UUID(),
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            items: items
        )
        return vm
    }()
    PlanEditView(viewModel: vm)
}
