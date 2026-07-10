import SwiftUI

/// 打卡视图 - 打卡日历、统计和成就
struct CheckInView: View {
    @StateObject private var viewModel = CheckInViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 打卡状态卡片
                    checkInStatusCard
                        .padding(.horizontal)
                    
                    // 打卡统计
                    statisticsCard
                        .padding(.horizontal)
                    
                    // 打卡日历
                    calendarCard
                        .padding(.horizontal)
                    
                    // 补签入口
                    makeUpCheckInCard
                        .padding(.horizontal)
                    
                    // 成就展示
                    achievementsCard
                        .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
                .padding(.top, 16)
            }
            .navigationTitle("每日打卡")
            .onAppear {
                viewModel.loadData()
            }
            .overlay {
                // 打卡成功动画覆盖层
                if viewModel.showCheckInAnimation {
                    checkInAnimationOverlay
                }
            }
            .alert("补签结果", isPresented: .constant(viewModel.makeUpResult != nil)) {
                Button("确定") {
                    viewModel.clearMakeUpResult()
                }
            } message: {
                Text(viewModel.makeUpResult?.errorMessage ?? "补签成功！")
            }
        }
    }
    
    // MARK: - 打卡状态卡片
    
    private var checkInStatusCard: some View {
        VStack(spacing: 20) {
            // 连续打卡天数
            VStack(spacing: 8) {
                Text("连续打卡")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline) {
                    Text("\(viewModel.consecutiveDays)")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(.orange)
                    Text("天")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Text(viewModel.encouragement)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // 打卡按钮
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    viewModel.performCheckIn()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.todayCheckedIn ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                    Text(viewModel.todayCheckedIn ? "今日已打卡" : "立即打卡")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(viewModel.todayCheckedIn ? Color.green : Color.orange)
                .cornerRadius(27)
            }
            .disabled(viewModel.todayCheckedIn)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    // MARK: - 打卡统计卡片
    
    private var statisticsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("打卡统计")
                .font(.headline)
            
            HStack(spacing: 0) {
                // 总打卡天数
                statItem(
                    icon: "calendar",
                    iconColor: .blue,
                    title: "累计打卡",
                    value: "\(viewModel.statistics?.totalDays ?? 0)",
                    unit: "天"
                )
                
                Divider().frame(height: 40)
                
                // 本月打卡率
                statItem(
                    icon: "chart.pie",
                    iconColor: .green,
                    title: "本月打卡率",
                    value: "\(viewModel.statistics?.monthlyCheckInRatePercent ?? 0)",
                    unit: "%"
                )
                
                Divider().frame(height: 40)
                
                // 剩余补签
                statItem(
                    icon: "pencil.circle",
                    iconColor: .orange,
                    title: "剩余补签",
                    value: "\(viewModel.statistics?.remainingMakeUpCount ?? 0)",
                    unit: "次"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    private func statItem(icon: String, iconColor: Color, title: String, value: String, unit: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 打卡日历卡片
    
    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 月份导航
            HStack {
                Button(action: { viewModel.changeMonth(-1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                Text(viewModel.monthTitle)
                    .font(.headline)
                
                Spacer()
                
                Button(action: { viewModel.changeMonth(1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.accentColor)
                }
            }
            
            // 星期标题
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 日历格子
            let days = calendarDays
            let firstWeekday = viewModel.firstWeekdayOfMonth
            let adjustedWeekday = (firstWeekday == 1) ? 7 : firstWeekday - 1 // 调整为周一开始
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                // 前置空白
                ForEach(0..<max(0, adjustedWeekday - 1), id: \.self) { _ in
                    Color.clear
                        .frame(height: 36)
                }
                
                // 日期格子
                ForEach(days, id: \.self) { date in
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
        let day = calendar.component(.day, from: date)
        let isCheckedIn = viewModel.isCheckedIn(date: date)
        let isToday = viewModel.isToday(date: date)
        let isFuture = viewModel.isFuture(date: date)
        
        return VStack(spacing: 2) {
            Text("\(day)")
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isToday ? .white : (isFuture ? .secondary : .primary))
            
            Circle()
                .fill(isCheckedIn ? Color.green : (isFuture ? Color.gray.opacity(0.1) : Color.gray.opacity(0.2)))
                .frame(width: 6, height: 6)
        }
        .frame(height: 36)
        .frame(maxWidth: .infinity)
        .background(isToday ? Color.accentColor : Color.clear)
        .cornerRadius(8)
    }
    
    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        return ["一", "二", "三", "四", "五", "六", "日"]
    }
    
    private var calendarDays: [Date] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: viewModel.displayedMonth)
        guard let firstDay = calendar.date(from: components) else { return [] }
        
        let daysCount = viewModel.daysInMonth
        return (0..<daysCount).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: firstDay)
        }
    }
    
    // MARK: - 补签入口卡片
    
    private var makeUpCheckInCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.orange)
                Text("补签")
                    .font(.headline)
                Spacer()
                
                if let stats = viewModel.statistics {
                    Text("本月剩余 \(stats.remainingMakeUpCount) 次")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if viewModel.makeUpDates.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("暂无可补签日期")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            } else {
                // 可补签日期列表
                ForEach(viewModel.makeUpDates, id: \.self) { date in
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.orange)
                        
                        Text(viewModel.formatDateForMakeUp(date))
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.performMakeUpCheckIn(for: date)
                        }) {
                            Text("补签")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.orange)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
    
    // MARK: - 成就展示卡片
    
    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text("打卡成就")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.unlockedAchievementCount)/\(viewModel.achievements.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 连续打卡成就
            VStack(alignment: .leading, spacing: 8) {
                Text("连续打卡")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.streakAchievements) { achievement in
                            AchievementBadge(achievement: achievement)
                        }
                    }
                }
            }
            
            Divider()
            
            // 累计打卡成就
            VStack(alignment: .leading, spacing: 8) {
                Text("累计打卡")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.totalAchievements) { achievement in
                            AchievementBadge(achievement: achievement)
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
    
    // MARK: - 打卡成功动画覆盖层
    
    private var checkInAnimationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.3)) {
                        viewModel.hideCheckInAnimation()
                    }
                }
            
            VStack(spacing: 24) {
                // 打卡成功动画
                CheckInSuccessAnimation()
                    .frame(width: 150, height: 150)
                
                Text("打卡成功！")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text(viewModel.encouragement)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                if viewModel.consecutiveDays > 1 {
                    Text("已连续打卡 \(viewModel.consecutiveDays) 天")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
                
                Button("确定") {
                    withAnimation(.easeOut(duration: 0.3)) {
                        viewModel.hideCheckInAnimation()
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(Color.orange)
                .cornerRadius(25)
            }
            .padding(32)
            .background(Color(.systemBackground).opacity(0.95))
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        }
        .transition(.opacity)
    }
}

// MARK: - 成就徽章组件

struct AchievementBadge: View {
    let achievement: CheckInAchievement
    
    var body: some View {
        VStack(spacing: 6) {
            // 图标
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(achievement.isUnlocked ? .yellow : .gray.opacity(0.4))
            }
            .overlay(
                Circle()
                    .stroke(achievement.isUnlocked ? Color.yellow : Color.gray.opacity(0.3), lineWidth: 2)
            )
            
            // 标题
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                .lineLimit(1)
            
            // 描述
            Text(achievement.description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            // 进度
            if !achievement.isUnlocked {
                Text("\(achievement.currentValue)/\(achievement.requiredValue)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .frame(width: 80)
    }
}

// MARK: - 打卡成功动画

struct CheckInSuccessAnimation: View {
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var checkScale: CGFloat = 0
    @State private var ringRotation: Double = 0
    
    var body: some View {
        ZStack {
            // 外环旋转
            Circle()
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.orange, .yellow, .orange]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(ringRotation))
            
            // 内圆
            Circle()
                .fill(Color.orange.opacity(0.2))
                .scaleEffect(scale)
            
            // 对勾
            Image(systemName: "checkmark")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(.orange)
                .scaleEffect(checkScale)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.2)) {
                checkScale = 1.0
            }
            
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
        }
    }
}

#Preview {
    CheckInView()
}