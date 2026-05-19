import SwiftUI
import Charts

struct PortfolioTrendChartView: View {
    let snapshots: [PortfolioSnapshot]

    @State private var selectedTimeRange: ChartTimeRange = .month
    @State private var showPnL: Bool = false
    @State private var selectedSnapshot: PortfolioSnapshot?

    private var filteredSnapshots: [PortfolioSnapshot] {
        let calendar = Calendar.current
        let now = Date()
        let filtered: [PortfolioSnapshot]

        switch selectedTimeRange {
        case .day:
            filtered = snapshots.filter { calendar.isDateInToday($0.timestamp) }
        case .week:
            guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return [] }
            filtered = snapshots.filter { $0.timestamp >= weekAgo }
        case .month:
            guard let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) else { return [] }
            filtered = snapshots.filter { $0.timestamp >= monthAgo }
        }

        let grouped = Dictionary(grouping: filtered) { snapshot in
            calendar.startOfDay(for: snapshot.timestamp)
        }
        return grouped.values.compactMap { $0.max(by: { $0.timestamp < $1.timestamp }) }
            .sorted { $0.timestamp < $1.timestamp }
    }

    private var chartColor: Color {
        if showPnL, let last = filteredSnapshots.last {
            return last.totalUnrealizedPnL >= 0 ? .green : .red
        }
        return .green
    }

    private var valueChange: Double {
        guard filteredSnapshots.count >= 2,
              let first = filteredSnapshots.first,
              let last = filteredSnapshots.last else { return 0 }
        let firstValue = showPnL ? first.totalUnrealizedPnL : first.totalValueCNY
        let lastValue = showPnL ? last.totalUnrealizedPnL : last.totalValueCNY
        return lastValue - firstValue
    }

    private var valueChangePercent: Double {
        guard filteredSnapshots.count >= 2,
              let first = filteredSnapshots.first else { return 0 }
        let firstValue = showPnL ? first.totalUnrealizedPnL : first.totalValueCNY
        guard firstValue != 0 else { return 0 }
        return (valueChange / firstValue) * 100
    }

    var body: some View {
        VStack(spacing: 12) {
            header
            timeRangePicker
            chartContent
            if filteredSnapshots.count >= 2 {
                summaryFooter
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(showPnL ? "累计盈亏" : "总市值")
                .font(.headline)

            Spacer()

            Button {
                withAnimation { showPnL.toggle() }
            } label: {
                Label("切换", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(showPnL ? chartColor.opacity(0.15) : .clear)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        Picker("时间范围", selection: $selectedTimeRange) {
            ForEach(ChartTimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Chart Content

    @ViewBuilder
    private var chartContent: some View {
        let dataPoints = filteredSnapshots

        if snapshots.isEmpty {
            emptyState
        } else if dataPoints.isEmpty {
            emptyState
        } else if dataPoints.count < 2 {
            singlePointChart(dataPoints: dataPoints)
        } else {
            fullChart(dataPoints: dataPoints)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "暂无历史数据",
            systemImage: "chart.xyaxis.line",
            description: Text("下拉刷新开始记录组合资产变化")
        )
        .frame(height: 220)
    }

    private func singlePointChart(dataPoints: [PortfolioSnapshot]) -> some View {
        Chart(dataPoints) { snapshot in
            PointMark(
                x: .value("时间", snapshot.timestamp),
                y: .value("总市值", snapshot.totalValueCNY)
            )
            .foregroundStyle(.blue)
        }
        .frame(height: 220)
        .overlay {
            Text("数据收集中...\n添加更多数据点后将显示趋势")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func fullChart(dataPoints: [PortfolioSnapshot]) -> some View {
        let yMin = dataPoints.map { showPnL ? $0.totalUnrealizedPnL : $0.totalValueCNY }.min() ?? 0
        let yMax = dataPoints.map { showPnL ? $0.totalUnrealizedPnL : $0.totalValueCNY }.max() ?? 1
        let yRange = yMax - yMin
        let yLower = yMin - yRange * 0.05
        let yUpper = yMax + yRange * 0.05

        return Chart {
            ForEach(dataPoints) { snapshot in
                let value = showPnL ? snapshot.totalUnrealizedPnL : snapshot.totalValueCNY

                AreaMark(
                    x: .value("时间", snapshot.timestamp),
                    y: .value(showPnL ? "累计盈亏" : "总市值", value)
                )
                .foregroundStyle(Gradient(
                    colors: [chartColor.opacity(0.12), chartColor.opacity(0.02)]
                ))
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("时间", snapshot.timestamp),
                    y: .value(showPnL ? "累计盈亏" : "总市值", value)
                )
                .foregroundStyle(chartColor)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
            }

            if let selected = selectedSnapshot {
                let selValue = showPnL ? selected.totalUnrealizedPnL : selected.totalValueCNY

                RuleMark(x: .value("时间", selected.timestamp))
                    .foregroundStyle(.gray.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                PointMark(
                    x: .value("时间", selected.timestamp),
                    y: .value("值", selValue)
                )
                .foregroundStyle(chartColor)
                .symbolSize(60)
            }
        }
        .chartYScale(domain: yLower...yUpper)
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(doubleValue.formattedCNY())
                            .font(.caption2)
                    }
                }
            }
        }
        .chartXAxis {
            if selectedTimeRange == .day {
                AxisMarks(values: .stride(by: .hour)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                }
            } else if selectedTimeRange == .week {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            } else {
                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let origin = geometry[proxy.plotAreaFrame].origin
                                let x = gesture.location.x - origin.x
                                guard x >= 0, x <= geometry[proxy.plotAreaFrame].width else {
                                    selectedSnapshot = nil
                                    return
                                }
                                guard let date: Date = proxy.value(atX: x) else { return }
                                selectedSnapshot = dataPoints.min(by: {
                                    abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date))
                                })
                            }
                            .onEnded { _ in
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { selectedSnapshot = nil }
                                }
                            }
                    )
                    .onTapGesture {
                        withAnimation { selectedSnapshot = nil }
                    }
            }
        }
        .frame(height: 220)
        .overlay(alignment: .top) {
            if let selected = selectedSnapshot {
                let value = showPnL ? selected.totalUnrealizedPnL : selected.totalValueCNY
                HStack(spacing: 12) {
                    Text(selected.timestamp, style: selectedTimeRange == .day ? .time : .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(value.formattedCNY())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(chartColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    // MARK: - Summary Footer

    private var summaryFooter: some View {
        HStack(spacing: 12) {
            Label("区间变化", systemImage: "arrow.up.arrow.down")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(valueChange.formattedCNY())
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(MarketColor.forChange(valueChange))

            Text(valueChangePercent.formattedPercent())
                .font(.caption)
                .foregroundStyle(MarketColor.forChange(valueChangePercent))

            Spacer()
        }
    }
}
