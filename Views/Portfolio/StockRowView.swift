import SwiftUI

struct StockRowView: View {
    let stock: PortfolioViewModel.StockPnL

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.holding.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(stock.holding.symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                Text(stock.price.formattedPrice())
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(stock.change.formattedChange())
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(MarketColor.forChange(stock.change))
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text(stock.dayPnLPercent.formattedPercent())
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundStyle(MarketColor.forChange(stock.changePercent))

                Text(stock.dayPnLCNY.formattedCNY())
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundStyle(MarketColor.forChange(stock.dayPnLCNY))
            }
        }
        .padding(.vertical, 4)
    }
}

struct StockRowSimple: View {
    let name: String
    let symbol: String
    let price: Double
    let change: Double
    let changePercent: Double
    let dayPnLCNY: Double

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(price.formattedPrice())
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(change.formattedChange())
                    .font(.caption)
                    .foregroundStyle(MarketColor.forChange(change))
            }

            VStack(alignment: .trailing, spacing: 2) {
                Text(changePercent.formattedPercent())
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(MarketColor.forChange(changePercent))
                Text(dayPnLCNY.formattedCNY())
                    .font(.caption)
                    .foregroundStyle(MarketColor.forChange(dayPnLCNY))
            }
            .frame(width: 100, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}
