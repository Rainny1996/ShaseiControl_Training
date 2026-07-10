import SwiftUI

/// 训练方法列表视图 - 支持分类筛选、难度筛选、搜索和收藏
struct TrainingListView: View {
    @StateObject private var viewModel = TrainingViewModel()
    @State private var showingFavoritesOnly = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 收藏快捷入口
                    favoritesSection
                    
                    // 分类筛选
                    categoryFilter
                    
                    // 难度筛选
                    difficultyFilter
                    
                    // 训练方法列表
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.filteredMethods.isEmpty {
                        emptyView
                    } else {
                        trainingList
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("训练方法")
            .searchable(text: $viewModel.searchText, prompt: "搜索训练方法")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        viewModel.showFavoritesOnly.toggle()
                    }) {
                        Image(systemName: viewModel.showFavoritesOnly ? "heart.fill" : "heart")
                            .foregroundColor(viewModel.showFavoritesOnly ? .red : .primary)
                    }
                }
                
                if viewModel.hasActiveFilters {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("清除筛选") {
                            viewModel.clearAllFilters()
                        }
                        .font(.subheadline)
                    }
                }
            }
            .onAppear {
                viewModel.loadTrainingMethods()
            }
            .refreshable {
                viewModel.refresh()
            }
        }
    }
    
    // MARK: - 收藏快捷入口
    
    private var favoritesSection: some View {
        Group {
            if !viewModel.favoriteMethods.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.subheadline)
                        Text("我的收藏")
                            .font(.headline)
                        Spacer()
                        Text("\(viewModel.favoriteMethods.count)个")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.favoriteMethods) { method in
                                NavigationLink(destination: TrainingDetailView(method: method, viewModel: viewModel)) {
                                    FavoriteMethodCard(method: method)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
            }
        }
    }
    
    // MARK: - 分类筛选
    
    private var categoryFilter: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("训练分类")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    CategoryChip(
                        title: "全部",
                        icon: nil,
                        count: viewModel.allMethods.count,
                        isSelected: viewModel.selectedCategory == nil
                    ) {
                        viewModel.selectedCategory = nil
                    }
                    
                    ForEach(TrainingCategory.allCases, id: \.self) { category in
                        let count = viewModel.allMethods.filter { $0.category == category }.count
                        CategoryChip(
                            title: category.rawValue,
                            icon: category.icon,
                            count: count,
                            isSelected: viewModel.selectedCategory == category
                        ) {
                            viewModel.selectedCategory = viewModel.selectedCategory == category ? nil : category
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 难度筛选
    
    private var difficultyFilter: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("难度等级")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 10) {
                DifficultyChip(
                    level: nil,
                    isSelected: viewModel.selectedDifficulty == nil
                ) {
                    viewModel.selectedDifficulty = nil
                }
                
                ForEach(DifficultyLevel.allCases, id: \.self) { level in
                    DifficultyChip(
                        level: level,
                        isSelected: viewModel.selectedDifficulty == level
                    ) {
                        viewModel.selectedDifficulty = viewModel.selectedDifficulty == level ? nil : level
                    }
                }
            }
        }
    }
    
    // MARK: - 训练方法列表
    
    private var trainingList: some View {
        LazyVStack(spacing: 14) {
            ForEach(viewModel.filteredMethods) { method in
                NavigationLink(destination: TrainingDetailView(method: method, viewModel: viewModel)) {
                    TrainingMethodCard(method: method, viewModel: viewModel)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - 加载视图
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("正在加载训练方法...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 60)
    }
    
    // MARK: - 空状态视图
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text(viewModel.showFavoritesOnly ? "暂无收藏的训练方法" : "没有找到匹配的训练方法")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if viewModel.hasActiveFilters {
                Button("清除筛选条件") {
                    viewModel.clearAllFilters()
                }
                .font(.subheadline)
                .foregroundColor(.accentColor)
            }
        }
        .padding(.top, 60)
    }
}

// MARK: - 收藏方法卡片

struct FavoriteMethodCard: View {
    let method: TrainingMethod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: method.category.icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text(method.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.difficultyColor(for: method.difficulty))
                    .frame(width: 6, height: 6)
                Text(method.difficulty.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(width: 100)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

// MARK: - 分类筛选芯片

struct CategoryChip: View {
    let title: String
    let icon: String?
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
                if count > 0 {
                    Text("(\(count))")
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - 难度筛选芯片

struct DifficultyChip: View {
    let level: DifficultyLevel?
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let level = level {
                    Circle()
                        .fill(Color.difficultyColor(for: level))
                        .frame(width: 8, height: 8)
                    Text(level.rawValue)
                        .font(.subheadline)
                } else {
                    Text("全部难度")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - 训练方法卡片

struct TrainingMethodCard: View {
    let method: TrainingMethod
    @ObservedObject var viewModel: TrainingViewModel
    
    var body: some View {
        HStack(spacing: 14) {
            // 左侧图标
            VStack(spacing: 4) {
                Image(systemName: method.category.icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(12)
            }
            
            // 中间信息
            VStack(alignment: .leading, spacing: 6) {
                Text(method.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(method.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    // 难度标签
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.difficultyColor(for: method.difficulty))
                            .frame(width: 6, height: 6)
                        Text(method.difficulty.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 时长
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(method.defaultDuration.formattedDuration)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    // 步骤数
                    HStack(spacing: 4) {
                        Image(systemName: "list.number")
                            .font(.caption2)
                        Text("\(method.steps.count)步")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 右侧收藏按钮
            Button(action: {
                viewModel.toggleFavorite(methodId: method.id)
            }) {
                Image(systemName: method.isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(method.isFavorite ? .red : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

#Preview {
    TrainingListView()
}