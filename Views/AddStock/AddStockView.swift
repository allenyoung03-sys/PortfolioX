import SwiftUI

struct AddStockView: View {
    @Environment(\.portfolioViewModel) private var vm
    @State private var searchText = ""
    @State private var selectedSymbol: String?
    @State private var stockName = ""
    @State private var selectedMarket: Market = .us
    @State private var sharesText = ""
    @State private var avgCostText = ""
    @State private var showSuccess = false
    @State private var isManualEntry = false

    private let predefinedStocks: [(symbol: String, name: String, market: Market)] = [
        // US
        ("AAPL", "Apple Inc.", .us),
        ("MSFT", "Microsoft Corp.", .us),
        ("GOOGL", "Alphabet Inc.", .us),
        ("AMZN", "Amazon.com Inc.", .us),
        ("NVDA", "NVIDIA Corp.", .us),
        ("META", "Meta Platforms Inc.", .us),
        ("TSLA", "Tesla Inc.", .us),
        ("AMD", "Advanced Micro Devices", .us),
        ("PLTR", "Palantir Technologies", .us),
        ("INTC", "Intel Corp.", .us),
        ("DIS", "Walt Disney Co.", .us),
        ("NFLX", "Netflix Inc.", .us),
        ("ADBE", "Adobe Inc.", .us),
        ("CRM", "Salesforce Inc.", .us),
        ("BABA", "Alibaba Group", .us),
        ("PDD", "PDD Holdings", .us),
        ("JD", "JD.com Inc.", .us),
        ("TSM", "Taiwan Semiconductor", .us),
        ("AVGO", "Broadcom Inc.", .us),
        ("KO", "Coca-Cola Co.", .us),
        ("JPM", "JPMorgan Chase & Co.", .us),
        ("V", "Visa Inc.", .us),
        ("MA", "Mastercard Inc.", .us),
        // HK
        ("0700", "腾讯控股", .hk),
        ("9988", "阿里巴巴-SW", .hk),
        ("0005", "汇丰控股", .hk),
        ("0941", "中国移动", .hk),
        ("939", "中国建设银行", .hk),
        ("1299", "友邦保险", .hk),
        ("2318", "中国平安", .hk),
        ("3968", "招商银行", .hk),
        // A股
        ("600519", "贵州茅台", .aShare),
        ("000858", "五粮液", .aShare),
        ("600036", "招商银行", .aShare),
        ("601318", "中国平安", .aShare),
        ("000333", "美的集团", .aShare),
        ("300750", "宁德时代", .aShare),
        ("600900", "长江电力", .aShare),
        ("002415", "海康威视", .aShare),
    ]

    var filteredStocks: [(symbol: String, name: String, market: Market)] {
        if searchText.isEmpty { return [] }
        return predefinedStocks.filter {
            $0.symbol.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("搜索股票") {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("输入股票代码或名称（如 AAPL、腾讯）", text: $searchText)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }

                if !searchText.isEmpty && !filteredStocks.isEmpty {
                    Section("搜索结果") {
                        ForEach(filteredStocks, id: \.symbol) { stock in
                            Button {
                                selectStock(stock)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(stock.name)
                                            .font(.subheadline)
                                        Text("\(stock.symbol) · \(stock.market.rawValue)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(.green)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if isManualEntry {
                    Section("手动输入") {
                        TextField("股票代码", text: Binding(
                            get: { selectedSymbol ?? "" },
                            set: { selectedSymbol = normalizeSymbol($0, market: selectedMarket) }
                        ))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: selectedMarket) { _, _ in
                            if let symbol = selectedSymbol {
                                selectedSymbol = normalizeSymbol(symbol, market: selectedMarket)
                            }
                        }

                        TextField("股票名称", text: $stockName)

                        Picker("市场", selection: $selectedMarket) {
                            ForEach(Market.allCases, id: \.self) { market in
                                Text(market.rawValue).tag(market)
                            }
                        }
                    }
                }

                if selectedSymbol != nil || isManualEntry {
                    Section("持仓信息") {
                        HStack {
                            Text("持股数")
                            Spacer()
                            TextField("0", text: $sharesText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }

                        HStack {
                            Text("买入均价")
                            Spacer()
                            TextField("可选", text: $avgCostText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        Text("不填买入均价则无法计算总浮盈")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Section {
                        Button(action: saveStock) {
                            HStack {
                                Spacer()
                                if let vm = vm, vm.isLoading {
                                    ProgressView()
                                } else {
                                    Text("添加持仓")
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                            }
                        }
                        .disabled(sharesText.isEmpty || (Double(sharesText) ?? 0) <= 0)
                        .buttonStyle(.borderless)
                    }
                }

                if !isManualEntry {
                    Section {
                        Button("手动输入股票代码") {
                            isManualEntry = true
                        }
                    }
                }
            }
            .navigationTitle("添加股票")
            .alert("添加成功", isPresented: $showSuccess) {
                Button("继续添加", role: .cancel) {
                    resetForm()
                }
                Button("查看持仓") {
                    resetForm()
                }
            } message: {
                Text("\(stockName) (\(selectedSymbol ?? "")) 已添加到持仓")
            }
        }
    }

    private func normalizeSymbol(_ symbol: String, market: Market) -> String {
        switch market {
        case .us:
            return symbol.uppercased()
        case .hk:
            guard let code = Int(symbol) else { return symbol }
            return String(format: "%05d", code)
        case .aShare:
            return symbol
        }
    }

    private func selectStock(_ stock: (symbol: String, name: String, market: Market)) {
        selectedSymbol = stock.symbol
        stockName = stock.name
        selectedMarket = stock.market
        isManualEntry = false
    }

    private func saveStock() {
        guard var symbol = selectedSymbol ?? selectedSymbol, !symbol.isEmpty,
              let shares = Double(sharesText), shares > 0 else { return }

        symbol = normalizeSymbol(symbol, market: selectedMarket)

        let cost = Double(avgCostText)
        vm?.addHolding(
            symbol: symbol,
            name: stockName,
            market: selectedMarket,
            shares: shares,
            avgCost: cost
        )
        showSuccess = true
    }

    private func resetForm() {
        searchText = ""
        selectedSymbol = nil
        stockName = ""
        sharesText = ""
        avgCostText = ""
        isManualEntry = false
    }
}

#Preview {
    AddStockView()
}
