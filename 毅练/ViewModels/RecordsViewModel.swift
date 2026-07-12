import Foundation
import Combine

/// 训练记录视图模型：列表与图表数据聚合
final class RecordsViewModel: ObservableObject {
    @Published var sessions: [TrainingSession] = []
    @Published var chartData: [(index: Int, avgControl: Double)] = []

    /// 雷达图维度定义
    static let radarDimensions: [String] = ["控制力", "恢复力", "耐力", "稳定性", "完成度"]

    init() { reload() }

    func reload() {
        sessions = CoreDataStack.shared.allSessions()
        chartData = sessions.enumerated().compactMap { idx, s in
            let arr = s.controlDurationsArray
            guard !arr.isEmpty else { return nil }
            let avg = Double(arr.reduce(0, +)) / Double(arr.count)
            return (index: idx, avgControl: avg)
        }.reversed()
    }

    // MARK: - 最新状态雷达指标（读取时派生，兼容老记录）

    /// 基于最近一条记录派生最新状态评分（0-100）
    func latestRadarScores() -> [String: Double] {
        guard let latest = sessions.first else {
            return Dictionary(uniqueKeysWithValues: Self.radarDimensions.map { ($0, 0) })
        }
        return radarScores(for: latest)
    }

    /// 针对单条记录派生各维度评分（0-100）
    func radarScores(for session: TrainingSession) -> [String: Double] {
        let controls = session.controlDurationsArray
        let avgControl = controls.isEmpty ? 0 : Double(controls.reduce(0, +)) / Double(controls.count)
        let cycleCount = Int(session.cycleCount)
        let total = Int(session.totalDuration)
        let usedSqueeze = session.usedSqueeze
        let premature = session.prematureEjaculation
        let brake = session.brakePoint

        // 控制力：平均可控时长与理想 60s 对比；提前射精重罚
        let control = clamp01(avgControl / 60.0) * 100 - (premature ? 45 : 0)
        // 恢复力：每轮回落/停顿充分度 + 挤捏法辅助加成
        let recover = (clamp01(Double(cycleCount) / 5.0) * 70) + (usedSqueeze ? 30 : 0)
        // 耐力：总时长与循环数综合，目标 30 分钟 / 5 循环
        let endurance = clamp01(Double(total) / 1800.0) * 60 + clamp01(Double(cycleCount) / 5.0) * 40
        // 稳定性：刹车点越接近 7 越稳定（6.5~7 理想），偏离扣分；提前射精重罚
        let brakeDeviation = abs(brake - 7.0)
        let stability = (100 - brakeDeviation * 25) - (premature ? 40 : 0)
        // 完成度：完成循环数与目标 5 对比，提前射精视为未完成
        let completion = clamp01(Double(cycleCount) / 5.0) * 100 - (premature ? 30 : 0)

        return [
            "控制力": max(0.0, min(100.0, control)),
            "恢复力": max(0.0, min(100.0, recover)),
            "耐力": max(0.0, min(100.0, endurance)),
            "稳定性": max(0.0, min(100.0, stability)),
            "完成度": max(0.0, min(100.0, completion))
        ]
    }

    /// 取单条记录每轮的阶段明细。phaseByCycle 索引严格对应 cycle-1。
    func cyclePhaseDetails(for session: TrainingSession) -> [(cycle: Int, phases: [(stage: String, seconds: Double)])] {
        let raw = session.phaseDurationsByCycle
        var result: [(cycle: Int, phases: [(stage: String, seconds: Double)])] = []
        for (i, dict) in raw.enumerated() {
            guard !dict.isEmpty else { continue }
            let phases = dict.sorted { $0.value > $1.value }.map { (stage: $0.key, seconds: $0.value) }
            result.append((cycle: i + 1, phases: phases))
        }
        return result
    }

    /// 导出加密 JSON 分享
    func exportJSON() -> URL? {
        let dicts = sessions.map { $0.toExportDictionary() }
        guard let data = try? JSONSerialization.data(withJSONObject: dicts, options: .prettyPrinted) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("yilian_export.json")
        try? data.write(to: url)
        return url
    }
}

/// 阶段名 → 中文展示
func phaseDisplayName(_ stage: String) -> String {
    switch stage {
    case "prepare": return "准备"
    case "arousal": return "唤醒"
    case "lowArousal": return "低兴奋"
    case "controlZone": return "控制区"
    case "stopWaiting": return "停止回落"
    case "squeeze": return "挤捏法"
    case "ejaculateReady": return "射精许可"
    case "finished": return "完成"
    default: return stage
    }
}

private func clamp01(_ v: Double) -> Double { max(0, min(1, v)) }
