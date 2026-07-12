import SwiftUI

/// 自绘雷达图（iOS 15 兼容，不用 Charts）
/// scores: 维度名 → 0-100 评分；维度顺序决定顶点位置
struct RadarChartView: View {
    let scores: [(label: String, value: Double)]
    var maxValue: Double = 100

    private var dimensions: Int { max(scores.count, 3) }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size / 2 - 36
            let angleStep = (2 * CGFloat.pi) / CGFloat(dimensions)

            ZStack {
                // 图形部分（网格、轴线、数据多边形、顶点）用 Canvas 绘制，
                // 避免 SwiftUI Shape.fill/stroke 在 iOS 15 部署目标下的可用性争议
                Canvas { context, _ in
                    // 网格圈层
                    for level in 1...4 {
                        let r = radius * CGFloat(level) / 4
                        var path = Path()
                        for i in 0..<dimensions {
                            let angle = -CGFloat.pi / 2 + angleStep * CGFloat(i)
                            let p = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
                            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
                        }
                        path.closeSubpath()
                        context.stroke(path, with: .color(Color.ylTextSecondary.opacity(0.25)), lineWidth: 1)
                    }

                    // 轴线
                    var axisPath = Path()
                    for i in 0..<dimensions {
                        let angle = -CGFloat.pi / 2 + angleStep * CGFloat(i)
                        let p = CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
                        axisPath.move(to: center)
                        axisPath.addLine(to: p)
                    }
                    context.stroke(axisPath, with: .color(Color.ylTextSecondary.opacity(0.3)), lineWidth: 1)

                    // 数据多边形
                    var dataPath = Path()
                    for i in 0..<scores.count {
                        let angle = -CGFloat.pi / 2 + angleStep * CGFloat(i)
                        let v = CGFloat(min(max(scores[i].value, 0), maxValue) / maxValue)
                        let p = CGPoint(x: center.x + radius * v * cos(angle), y: center.y + radius * v * sin(angle))
                        if i == 0 { dataPath.move(to: p) } else { dataPath.addLine(to: p) }
                    }
                    dataPath.closeSubpath()
                    context.fill(dataPath, with: .color(Color.ylGreen.opacity(0.25)))
                    context.stroke(dataPath, with: .color(Color.ylGreen), lineWidth: 2)

                    // 顶点圆点
                    for (i, item) in scores.enumerated() {
                        let angle = -CGFloat.pi / 2 + angleStep * CGFloat(i)
                        let v = CGFloat(min(max(item.value, 0), maxValue) / maxValue)
                        let p = CGPoint(x: center.x + radius * v * cos(angle), y: center.y + radius * v * sin(angle))
                        var dot = Path(ellipseIn: CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6))
                        context.fill(dot, with: .color(Color.ylGreen))
                    }
                }

                // 标签部分用 SwiftUI Text 叠加（不依赖 Shape 修饰符）
                verticesAndLabels(center: center, radius: radius, angleStep: angleStep)
            }
        }
    }

    private func verticesAndLabels(center: CGPoint, radius: CGFloat, angleStep: CGFloat) -> some View {
        ForEach(Array(scores.enumerated()), id: \.offset) { i, item in
            let angle = -CGFloat.pi / 2 + angleStep * CGFloat(i)
            let labelP = CGPoint(x: center.x + (radius + 22) * cos(angle), y: center.y + (radius + 22) * sin(angle))
            Text(item.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.ylText)
                .position(labelP)
            Text("\(Int(item.value))")
                .font(.system(size: 11))
                .foregroundColor(.ylTextSecondary)
                .position(CGPoint(x: labelP.x, y: labelP.y + 15))
        }
    }
}
