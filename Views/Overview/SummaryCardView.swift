import SwiftUI

struct SummaryCardView: View {
    let totalValue: Double
    let totalDayPnL: Double
    let totalDayPercent: Double
    let totalUnrealizedPnL: Double
    let lastRefreshTime: Date?

    var body: some View {
        VStack(spacing: 12) {
            Text("组合总市值")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(totalValue.formattedCNY())
                .font(.system(size: 34, weight: .bold, design: .monospaced))

            HStack(spacing: 24) {
                VStack(spacing: 2) {
                    Text("今日盈亏")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Text(totalDayPnL.formattedCNY())
                        Text(totalDayPercent.formattedPercent())
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .foregroundStyle(MarketColor.forChange(totalDayPnL))
                }

                Divider().frame(height: 36)

                VStack(spacing: 2) {
                    Text("总浮盈")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(totalUnrealizedPnL.formattedCNY())
                        .font(.subheadline)
                        .foregroundStyle(MarketColor.forChange(totalUnrealizedPnL))
                }
            }

            if let time = lastRefreshTime {
                Text("更新: \(time, style: .time)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    SummaryCardView(
        totalValue: 123456.78,
        totalDayPnL: 1234.56,
        totalDayPercent: 1.23,
        totalUnrealizedPnL: 5678.90,
        lastRefreshTime: Date()
    )
    .padding()
}
