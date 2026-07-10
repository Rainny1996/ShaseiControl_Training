import SwiftUI

/// 计划视图 - 训练计划管理主页面
struct PlanView: View {
    @StateObject private var viewModel = PlanViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("加载中...")
                } else if !viewModel.hasActivePlan {
                    noPlanView
                } else {
                    planContentView
                }
            }
            .navigationTitle("训练计划")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { viewModel.showTemplateSelection = true }) {
                            Label("选择模板", systemImage: "doc.text")
                        }
                        Button(action: { viewModel.regeneratePlan() }) {
                            Label("重新生成", systemImage: "arrow.clockwise")
                        }
                        Button(action: { viewModel.adjustPlanIfNeeded() }) {
                            Label("智能调整", systemImage: "wand.and.stars")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAssessment) {
                AssessmentView()
                    .environmentObject(appState)
                    .onDisappear {
                        viewModel.loadPlan()
                    }
            }
            .sheet(isPresented: $viewModel.showTemplateSelection) {
                TemplateSelectionView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.loadPlan()
            }
        }
    }
    
    // MARK: - 无计划视图
    
    private var noPlanView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundColor(.accentColor.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("还没有训练计划")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text("完成初始评估，获取个性化训练计划")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                // 开始评估按钮
                Button(action: { viewModel.showAssessment = true }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("开始初始评估")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                // 选择模板按钮
                Button(action: { viewModel.showTemplateSelection = true }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("选择计划模板")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(.accentColor)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
    
    // MARK: - 计划内容视图
    
    private var planContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 计划进度卡片
                planProgressCard
                    .padding(.horizontal)
                
                // 今日训练卡片
                todayTrainingCard
                    .padding(.horizontal)
                
                // 周日历视图
                weekCalendarCard
                    .padding(.horizontal)
                
                // 训练提醒设置
                reminderSettingsCard
                    .padding(.horizontal)
                
                // 训练项目列表
                planItemsList
                    .padding(.horizontal)
                
                Spacer(minLength: 20)
            }
            .padding(.top, 16)
        }
    }
    
    // MARK: - 计划进度卡片
    
    private var planProgressCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("计划进度")
                        .font(.headline)
                    Text(viewModel.planGoal)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(viewModel.progressPercent)%")
                    .font(.title2.bold())
                    .foregroundColor(.accentColor)
            }
            
            // 进度条
            ProgressView(value: Double(viewModel.progressPercent) / 100.0)
                .tint(.accentColor)
                .scaleEffect(y: 1.5)
            
            // 统计信息
            HStack(spacing: 0) {
                statItem(title: "剩余天数", value: "\(viewModel.remainingDays)", unit: "天")
                Divider().frame(height: 30)
                statItem(title: "本周完成", value: "\(viewModel.weekCompletedCount)", unit: "/\(viewModel.weekTotalCount)")
                Divider().frame(height: 30)
                statItem(title: "今日任务", value: "\(viewModel.todayCompletedCount)", unit: "/\(viewModel.todayTotalCount)")
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    private func statItem(title: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.accentColor)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 今日训练卡片
    
    private var todayTrainingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日训练")
                    .font(.headline)
                Spacer()
                if viewModel.todayItems.isEmpty {
                    Text("休息日")
                        .font(.subheadline)
                        .foregroundColor(.green)
                } else {
                    Text("\(viewModel.todayCompletedCount)/\(viewModel.todayTotalCount) 已完成")
                        .font(.subheadline)
                        .foregroundColor(viewModel.todayCompletedCount == viewModel.todayTotalCount ? .green : .secondary)
                }
            }
            
            if viewModel.todayItems.isEmpty {
                // 休息日
                VStack(spacing: 12) {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 36))
                        .foregroundColor(.blue.opacity(0.5))
                    Text("今天是休息日，好好恢复")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // 今日训练项列表
                ForEach(viewModel.todayItems) { item in
                    TodayPlanItemRow(item: item) {
                        viewModel.markItemCompleted(item.id)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    // MARK: - 周日历卡片
    
    private var weekCalendarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("本周日历")
                    .font(.headline)
                Spacer()
                Text(weekRangeText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 星期标题行
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 日历格子
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(weekDates, id: \.self) { date in
                    calendarDayCell(date)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    private func calendarDayCell(_ date: Date) -> some View {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        let hasItems = viewModel.hasItemsOnDate(date)
        let isCompleted = viewModel.isDateCompleted(date)
        let isPartial = viewModel.isDatePartiallyCompleted(date)
        
        return VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: date))")
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isToday ? .white : .primary)
            
            Circle()
                .fill(dotColor(hasItems: hasItems, isCompleted: isCompleted, isPartial: isPartial))
                .frame(width: 6, height: 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(isToday ? Color.accentColor : Color.clear)
        .cornerRadius(8)
    }
    
    private func dotColor(hasItems: Bool, isCompleted: Bool, isPartial: Bool) -> Color {
        if isCompleted { return .green }
        if isPartial { return .orange }
        if hasItems { return .accentColor.opacity(0.5) }
        return .gray.opacity(0.2)
    }
    
    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return Array(formatter.shortWeekdaySymbols!.prefix(7))
    }
    
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: startOfWeek)! }
    }
    
    private var weekRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        let start = weekDates.first!
        let end = weekDates.last!
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    // MARK: - 提醒设置卡片
    
    private var reminderSettingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("训练提醒")
                .font(.headline)
            
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(viewModel.reminderEnabled ? .accentColor : .gray)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("每日提醒")
                        .font(.subheadline)
                    Text(viewModel.reminderEnabled ? "每天 \(String(format: "%02d:%02d", viewModel.reminderHour, viewModel.reminderMinute)) 提醒训练" : "未开启")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $viewModel.reminderEnabled)
                    .labelsHidden()
                    .onChange(of: viewModel.reminderEnabled) { _ in
                        viewModel.toggleReminder()
                    }
            }
            .padding(.vertical, 4)
            
            if viewModel.reminderEnabled {
                // 时间选择器
                DatePicker("提醒时间", selection: Binding(
                    get: {
                        let calendar = Calendar.current
                        var components = calendar.dateComponents([.year, .month, .day], from: Date())
                        components.hour = viewModel.reminderHour
                        components.minute = viewModel.reminderMinute
                        return calendar.date(from: components) ?? Date()
                    },
                    set: { date in
                        let calendar = Calendar.current
                        viewModel.updateReminderTime(
                            hour: calendar.component(.hour, from: date),
                            minute: calendar.component(.minute, from: date)
                        )
                    }
                ), displayedComponents: .hourAndMinute)
                .datePickerStyle(.compact)
                .labelsHidden()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    // MARK: - 训练项目列表
    
    private var planItemsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("训练项目")
                    .font(.headline)
                Spacer()
                Text("本周 \(viewModel.weekTotalCount) 项")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if viewModel.weekItems.isEmpty {
                Text("暂无训练项目")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                // 按日期分组显示
                let groupedItems = Dictionary(grouping: viewModel.weekItems) { item in
                    Calendar.current.startOfDay(for: item.date)
                }
                
                let sortedDates = groupedItems.keys.sorted()
                
                ForEach(sortedDates, id: \.self) { date in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(dateString(date))
                                .font(.subheadline.bold())
                                .foregroundColor(.secondary)
                            if Calendar.current.isDateInToday(date) {
                                Text("今天")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor)
                                    .cornerRadius(4)
                            }
                        }
                        
                        ForEach(groupedItems[date] ?? []) { item in
                            PlanItemRow(item: item)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

// MARK: - 今日计划项行

struct TodayPlanItemRow: View {
    let item: PlanItem
    let onComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 完成按钮
            Button(action: {
                if !item.isCompleted {
                    onComplete()
                }
            }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(item.isCompleted ? .green : .gray.opacity(0.4))
            }
            .disabled(item.isCompleted)
            
            // 训练信息
            VStack(alignment: .leading, spacing: 4) {
                Text(item.methodName)
                    .font(.subheadline.bold())
                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                    .strikethrough(item.isCompleted)
                
                Text(formatDuration(item.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 状态
            if item.isCompleted {
                Text("已完成")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(item.isCompleted ? Color.green.opacity(0.05) : Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)分钟"
    }
}

// MARK: - 计划项行

struct PlanItemRow: View {
    let item: PlanItem
    
    var body: some View {
        HStack(spacing: 12) {
            // 状态指示
            Circle()
                .fill(item.isCompleted ? Color.green : Color.accentColor.opacity(0.3))
                .frame(width: 8, height: 8)
            
            // 训练信息
            VStack(alignment: .leading, spacing: 2) {
                Text(item.methodName)
                    .font(.subheadline)
                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                    .strikethrough(item.isCompleted)
                
                Text(formatDuration(item.duration))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if item.isCompleted {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)分钟"
    }
}

// MARK: - 模板选择视图

struct TemplateSelectionView: View {
    @ObservedObject var viewModel: PlanViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("选择适合您的训练模板")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    ForEach(PlanService.planTemplates()) { template in
                        TemplateCard(template: template) {
                            viewModel.createPlanFromTemplate(template)
                            dismiss()
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("计划模板")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 模板卡片

struct TemplateCard: View {
    let template: PlanTemplate
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // 图标
                Image(systemName: template.icon)
                    .font(.title)
                    .foregroundColor(.accentColor)
                    .frame(width: 50, height: 50)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(12)
                
                // 信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        Label(template.difficulty.rawValue, systemImage: "signal")
                            .font(.caption2)
                            .foregroundColor(difficultyColor)
                        
                        Label("每周\(template.frequency)天", systemImage: "calendar")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Label(template.goal.rawValue, systemImage: "target")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    private var difficultyColor: Color {
        switch template.difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

#Preview {
    PlanView()
        .environmentObject(AppState())
}