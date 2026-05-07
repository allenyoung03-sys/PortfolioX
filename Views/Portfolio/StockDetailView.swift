import SwiftUI

struct StockDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.portfolioViewModel) private var vm
    let stock: PortfolioViewModel.StockPnL

    @State private var editShares: String = ""
    @State private var editAvgCost: String = ""
    @State private var showEdit = false

    var body: some View {
        NavigationStack {
            List {
                Section("基本信息") {
                    detailRow("名称", stock.holding.name)
                    detailRow("代码", stock.holding.symbol)
                    detailRow("市场", stock.holding.marketEnum.rawValue)
                    detailRow("持股数", stock.holding.shares.formattedPrice())
                    if let cost = stock.holding.avgCost {
                        detailRow("买入均价", cost.formattedPrice())
                    } else {
                        detailRow("买入均价", "未设置")
                    }
                }

                Section("实时行情") {
                    detailRow("当前价格", stock.price.formattedPrice())
                    detailRow("今日涨跌", stock.change.formattedChange())
                    detailRow("涨跌幅", stock.changePercent.formattedPercent())
                }

                Section("收益分析") {
                    detailRow("当日盈亏 (CNY)", stock.dayPnLCNY.formattedCNY())
                    detailRow("持仓市值 (CNY)", stock.marketValueCNY.formattedCNY())
                    if stock.holding.avgCost != nil {
                        detailRow("总浮盈 (CNY)", stock.unrealizedPnLCNY.formattedCNY())
                    }
                }

                Section {
                    Button(role: .destructive) {
                        vm?.deleteHolding(stock.holding)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Label("删除持仓", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(stock.holding.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("编辑") { showEdit = true }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
            }
            .sheet(isPresented: $showEdit) {
                editSheet
            }
        }
    }

    private var editSheet: some View {
        NavigationStack {
            Form {
                Section("编辑持仓") {
                    HStack {
                        Text("持股数")
                        TextField("股数", text: $editShares)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("买入均价")
                        TextField("均价（可选）", text: $editAvgCost)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("编辑 \(stock.holding.symbol)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showEdit = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let shares = Double(editShares) ?? stock.holding.shares
                        let cost = Double(editAvgCost)
                        vm?.updateHolding(stock.holding, shares: shares, avgCost: cost)
                        showEdit = false
                    }
                }
            }
            .onAppear {
                editShares = String(format: "%.2f", stock.holding.shares)
                if let cost = stock.holding.avgCost {
                    editAvgCost = String(format: "%.2f", cost)
                }
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
