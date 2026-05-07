import SwiftUI

struct MarketSectionView: View {
    let marketPnL: PortfolioViewModel.MarketPnL

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Market header with summary
            VStack(spacing: 6) {
                HStack {
                    Label(marketPnL.market.rawValue, systemImage: "building.columns.fill")
                        .font(.headline)
                        .foregroundStyle(MarketColor.forMarket(marketPnL.market.rawValue))

                    Spacer()
                }

                HStack(spacing: 0) {
                    Spacer()
                    Text("总资产")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                    Text("今日")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                    Text("浮动盈亏")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 4)

                HStack(spacing: 0) {
                    Spacer()
                    Text(marketPnL.totalMarketValue.formattedCNY())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text(marketPnL.totalDayPnL.formattedCNY())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundStyle(MarketColor.forChange(marketPnL.totalDayPnL))
                    Text(marketPnL.totalUnrealizedPnL.formattedCNY())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundStyle(MarketColor.forChange(marketPnL.totalUnrealizedPnL))
                }
                .padding(.horizontal, 4)

                Divider()
            }

            ForEach(marketPnL.stocks, id: \.holding.symbol) { stock in
                OverviewStockRowView(stock: stock)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
