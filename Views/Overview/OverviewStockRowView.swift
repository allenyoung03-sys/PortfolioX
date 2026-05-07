import SwiftUI

struct OverviewStockRowView: View {
    let stock: PortfolioViewModel.StockPnL

    var body: some View {
        VStack(spacing: 4) {
            // Line 1: Name + Day PnL
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(stock.holding.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text(stock.holding.symbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text(stock.dayPnLCNY.formattedCNY())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(stock.dayPnLPercent.formattedPercent())
                        .font(.caption)
                }
                .foregroundStyle(MarketColor.forChange(stock.dayPnLCNY))
            }

            // Line 2: Asset + Unrealized PnL
            HStack(spacing: 0) {
                HStack(spacing: 4) {
                    Text("资产")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(stock.marketValueCNY.formattedCNY())
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("浮盈")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(stock.unrealizedPnLCNY.formattedCNY())
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(MarketColor.forChange(stock.unrealizedPnLCNY))
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
