import SwiftUI

struct OverviewView: View {
    @Environment(\.portfolioViewModel) private var vm

    var body: some View {
        NavigationStack {
            ScrollView {
                if let vm = vm {
                    VStack(spacing: 16) {
                        summaryCard
                        trendChart
                        marketSections
                    }
                    .padding()
                } else {
                    ProgressView()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("总览")
            .refreshable {
                await vm?.refreshAll()
            }
            .overlay(alignment: .top) {
                VStack(spacing: 4) {
                    if vm?.isLoading == true {
                        ProgressView()
                            .padding(.top, 44)
                    }
                    if let error = vm?.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.8))
                            .clipShape(Capsule())
                            .padding(.top, 4)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .onTapGesture { vm?.errorMessage = nil }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var summaryCard: some View {
        if let vm = vm {
            let summary = vm.portfolioSummary
            VStack(spacing: 12) {
                Text("组合总市值")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(summary.totalValue.formattedCNY())
                    .font(.system(size: 34, weight: .bold, design: .monospaced))

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("今日盈亏")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Text(summary.totalDayPnL.formattedCNY())
                                .font(.headline)
                            Text(summary.totalDayPnLPercent.formattedPercent())
                                .font(.caption)
                        }
                        .foregroundStyle(MarketColor.forChange(summary.totalDayPnL))
                    }

                    Divider().frame(height: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("总浮盈")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 4) {
                            Text(summary.totalUnrealizedPnL.formattedCNY())
                                .font(.headline)
                            Text(summary.totalUnrealizedPnLPercent.formattedPercent())
                                .font(.caption)
                        }
                        .foregroundStyle(MarketColor.forChange(summary.totalUnrealizedPnL))
                    }
                }

                if let refreshTime = vm.lastRefreshTime {
                    Text("更新时间: \(refreshTime, style: .time)")
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

    @ViewBuilder
    private var trendChart: some View {
        if let vm = vm, !vm.holdings.isEmpty {
            PortfolioTrendChartView(snapshots: vm.snapshots)
        }
    }

    @ViewBuilder
    private var marketSections: some View {
        if let vm = vm {
            ForEach(vm.marketPnLs, id: \.market) { marketPnL in
                VStack(alignment: .leading, spacing: 8) {
                    // Market header - two line layout
                    VStack(spacing: 6) {
                        HStack(spacing: 0) {
                            Label(marketPnL.market.rawValue, systemImage: "building.columns.fill")
                                .font(.headline)
                                .foregroundStyle(MarketColor.forMarket(marketPnL.market.rawValue))

                            Spacer()

                            HStack(spacing: 4) {
                                Text("总资产")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                Text(marketPnL.totalMarketValue.formattedCNY())
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }

                        HStack(spacing: 0) {
                            HStack(spacing: 4) {
                                Text("今日")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                Text(marketPnL.totalDayPnL.formattedCNY())
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(MarketColor.forChange(marketPnL.totalDayPnL))
                            }

                            Spacer()

                            HStack(spacing: 4) {
                                Text("浮盈")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                Text(marketPnL.totalUnrealizedPnL.formattedCNY())
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(MarketColor.forChange(marketPnL.totalUnrealizedPnL))
                            }
                        }
                    }

                    ForEach(marketPnL.stocks, id: \.holding.symbol) { stock in
                        OverviewStockRowView(stock: stock)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            if vm.holdings.isEmpty {
                ContentUnavailableView(
                    "暂无持仓",
                    systemImage: "tray",
                    description: Text("点击「添加」标签开始添加你的股票持仓")
                )
                .padding(.top, 40)
            }
        }
    }
}

#Preview {
    OverviewView()
}
