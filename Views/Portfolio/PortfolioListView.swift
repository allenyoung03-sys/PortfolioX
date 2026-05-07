import SwiftUI

struct PortfolioListView: View {
    @Environment(\.portfolioViewModel) private var vm
    @State private var selectedStock: PortfolioViewModel.StockPnL?
    @State private var showDetail = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm = vm {
                    if vm.holdings.isEmpty {
                        ContentUnavailableView(
                            "暂无持仓",
                            systemImage: "tray",
                            description: Text("点击下方「添加」标签开始添加股票")
                        )
                    } else {
                        List {
                            ForEach(Market.allCases, id: \.self) { market in
                                let marketStocks = vm.allStockPnLs.filter { $0.holding.marketEnum == market }
                                if !marketStocks.isEmpty {
                                    Section {
                                        ForEach(marketStocks, id: \.holding.symbol) { stock in
                                            StockRowView(stock: stock)
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    selectedStock = stock
                                                    showDetail = true
                                                }
                                                .swipeActions(edge: .trailing) {
                                                    Button(role: .destructive) {
                                                        withAnimation {
                                                            vm.deleteHolding(stock.holding)
                                                        }
                                                    } label: {
                                                        Label("删除", systemImage: "trash")
                                                    }
                                                }
                                        }
                                    } header: {
                                        HStack {
                                            Text(market.rawValue)
                                                .font(.headline)
                                                .foregroundStyle(MarketColor.forMarket(market.rawValue))
                                            Spacer()
                                            HStack(spacing: 12) {
                                                let dayPnL = marketStocks.reduce(0) { $0 + $1.dayPnLCNY }
                                                VStack(alignment: .trailing, spacing: 1) {
                                                    Text("今日")
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                    Text(dayPnL.formattedCNY())
                                                        .font(.subheadline)
                                                        .foregroundStyle(MarketColor.forChange(dayPnL))
                                                }
                                                let unrealized = marketStocks.reduce(0) { $0 + $1.unrealizedPnLCNY }
                                                VStack(alignment: .trailing, spacing: 1) {
                                                    Text("浮盈")
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                    Text(unrealized.formattedCNY())
                                                        .font(.subheadline)
                                                        .foregroundStyle(MarketColor.forChange(unrealized))
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("持仓")
            .refreshable {
                await vm?.refreshAll()
            }
            .sheet(isPresented: $showDetail) {
                if let stock = selectedStock {
                    StockDetailView(stock: stock)
                }
            }
        }
    }
}

#Preview {
    PortfolioListView()
}
