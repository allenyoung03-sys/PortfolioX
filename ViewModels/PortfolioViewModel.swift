import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class PortfolioViewModel {
    private let modelContext: ModelContext

    var holdings: [StockHolding] = []
    var quotes: [String: MarketQuote] = [:]
    var exchangeRate: ExchangeRate?
    var alertRecords: [AlertRecord] = []
    var alertSetting: AlertSetting?

    var isLoading = false
    var errorMessage: String?
    var lastRefreshTime: Date?

    private let quoteService = StockQuoteService.shared
    private let rateService = ExchangeRateService.shared
    private let aiService = AIService.shared
    private let notificationService = NotificationService.shared

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadCache()
    }

    // MARK: - Cache Loading

    func loadCache() {
        loadHoldings()
        loadQuotes()
        loadExchangeRate()
        loadAlertRecords()
        loadAlertSetting()
    }

    private func loadHoldings() {
        let descriptor = FetchDescriptor<StockHolding>(sortBy: [SortDescriptor(\.sortOrder)])
        holdings = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func loadQuotes() {
        let descriptor = FetchDescriptor<MarketQuote>()
        let cached = (try? modelContext.fetch(descriptor)) ?? []
        quotes = Dictionary(uniqueKeysWithValues: cached.map { ($0.symbol, $0) })
    }

    private func loadExchangeRate() {
        let descriptor = FetchDescriptor<ExchangeRate>()
        exchangeRate = (try? modelContext.fetch(descriptor))?.last
    }

    private func loadAlertRecords() {
        let descriptor = FetchDescriptor<AlertRecord>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        alertRecords = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func loadAlertSetting() {
        let descriptor = FetchDescriptor<AlertSetting>()
        if let existing = (try? modelContext.fetch(descriptor))?.last {
            alertSetting = existing
        } else {
            let defaultSetting = AlertSetting()
            modelContext.insert(defaultSetting)
            try? modelContext.save()
            alertSetting = defaultSetting
        }
    }

    // MARK: - Holdings Management

    func addHolding(symbol: String, name: String, market: Market, shares: Double, avgCost: Double?) {
        guard holdings.count < Constants.maxStockCount else {
            errorMessage = "最多支持 \(Constants.maxStockCount) 支股票"
            return
        }

        let holding = StockHolding(
            symbol: symbol.uppercased(),
            name: name,
            market: market,
            shares: shares,
            avgCost: avgCost,
            sortOrder: holdings.count
        )
        modelContext.insert(holding)
        try? modelContext.save()
        loadHoldings()
    }

    func updateHolding(_ holding: StockHolding, shares: Double, avgCost: Double?) {
        holding.shares = shares
        holding.avgCost = avgCost
        try? modelContext.save()
    }

    func deleteHolding(_ holding: StockHolding) {
        modelContext.delete(holding)
        try? modelContext.save()
        loadHoldings()
    }

    // MARK: - Data Refresh

    func refreshAll() async {
        isLoading = true
        errorMessage = nil

        // Fetch exchange rates
        do {
            let fetchedRates = try await rateService.fetchAllRates()
            let rate = ExchangeRate(usdToCny: fetchedRates.usdToCny, hkdToCny: fetchedRates.hkdToCny)
            modelContext.insert(rate)
            exchangeRate = rate
        } catch {
            errorMessage = "汇率获取失败: \(error.localizedDescription)"
        }

        // Fetch stock quotes (independent of exchange rates)
        if !holdings.isEmpty {
            do {
                let fetchedQuotes = try await quoteService.fetchQuotes(for: holdings)
                for (symbol, quote) in fetchedQuotes {
                    if let existing = quotes[symbol] {
                        existing.price = quote.price
                        existing.change = quote.change
                        existing.changePercent = quote.changePercent
                        existing.updatedAt = Date()
                    } else {
                        modelContext.insert(quote)
                    }
                }
                quotes = fetchedQuotes
            } catch {
                let msg = "报价获取失败: \(error.localizedDescription)"
                errorMessage = errorMessage == nil ? msg : "\(errorMessage!)\n\(msg)"
            }
        }

        try? modelContext.save()
        lastRefreshTime = Date()
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Constants.UserDefaults.lastRefreshKey)

        await checkAlerts()
        isLoading = false
    }

    // MARK: - P&L Calculations

    struct MarketPnL {
        let market: Market
        var stocks: [StockPnL]
        var totalDayPnL: Double { stocks.reduce(0) { $0 + $1.dayPnLCNY } }
        var totalUnrealizedPnL: Double { stocks.reduce(0) { $0 + $1.unrealizedPnLCNY } }
        var totalMarketValue: Double { stocks.reduce(0) { $0 + $1.marketValueCNY } }
    }

    struct StockPnL: Identifiable {
        var id: String { holding.symbol }
        let holding: StockHolding
        let quote: MarketQuote?
        let exchangeRate: ExchangeRate?

        var price: Double { quote?.price ?? 0 }
        var change: Double { quote?.change ?? 0 }
        var changePercent: Double { quote?.changePercent ?? 0 }

        var rate: Double {
            guard let rate = exchangeRate else { return 1 }
            switch holding.marketEnum {
            case .us: return rate.usdToCny
            case .hk: return rate.hkdToCny
            case .aShare: return 1
            }
        }

        var marketValueCNY: Double {
            price * holding.shares * rate
        }

        var dayPnLCNY: Double {
            change * holding.shares * rate
        }

        var unrealizedPnLCNY: Double {
            guard let cost = holding.avgCost, cost > 0 else { return 0 }
            return (price - cost) * holding.shares * rate
        }

        var costBasisCNY: Double {
            guard let cost = holding.avgCost, cost > 0 else { return 0 }
            return cost * holding.shares * rate
        }

        var dayPnLPercent: Double {
            guard let quote = quote, quote.price > 0 else { return 0 }
            return quote.changePercent
        }
    }

    var portfolioSummary: (totalValue: Double, totalDayPnL: Double, totalDayPnLPercent: Double, totalUnrealizedPnL: Double, totalUnrealizedPnLPercent: Double) {
        let stocks = allStockPnLs
        let totalValue = stocks.reduce(0) { $0 + $1.marketValueCNY }
        let totalDay = stocks.reduce(0) { $0 + $1.dayPnLCNY }
        let totalUnrealized = stocks.reduce(0) { $0 + $1.unrealizedPnLCNY }
        let totalDayPercent: Double = {
            let yestValue = stocks.reduce(0) { sum, s in
                let prevPrice = s.quote.map { $0.price - $0.change } ?? 0
                return sum + prevPrice * s.holding.shares * s.rate
            }
            return yestValue > 0 ? (totalDay / yestValue) * 100 : 0
        }()
        let totalCost = stocks.reduce(0) { $0 + $1.costBasisCNY }
        let totalUnrealizedPnLPercent = totalCost > 0 ? (totalUnrealized / totalCost) * 100 : 0
        return (totalValue, totalDay, totalDayPercent, totalUnrealized, totalUnrealizedPnLPercent)
    }

    var allStockPnLs: [StockPnL] {
        holdings.map { StockPnL(holding: $0, quote: quotes[$0.symbol], exchangeRate: exchangeRate) }
    }

    var marketPnLs: [MarketPnL] {
        var result: [MarketPnL] = []
        for market in Market.allCases {
            let stocks = holdings.filter { $0.marketEnum == market }
            if !stocks.isEmpty {
                let stockPnLs = stocks
                    .map { StockPnL(holding: $0, quote: quotes[$0.symbol], exchangeRate: exchangeRate) }
                    .sorted { $0.marketValueCNY > $1.marketValueCNY }
                result.append(MarketPnL(market: market, stocks: stockPnLs))
            }
        }
        return result
    }

    // MARK: - Alerts

    func checkAlerts() async {
        guard let setting = alertSetting, setting.isEnabled else { return }

        let calendar = Calendar.current
        let today = calendar.component(.day, from: Date())

        for holding in holdings {
            guard let quote = quotes[holding.symbol] else { continue }

            let absPercent = abs(quote.changePercent)
            let pnl = quote.change * holding.shares * getRate(for: holding)
            let absPnl = abs(pnl)

            guard absPercent >= setting.thresholdPercent || absPnl >= setting.minAmountCNY else { continue }

            let alreadyNotifiedToday = alertRecords.contains {
                $0.symbol == holding.symbol &&
                calendar.component(.day, from: $0.createdAt) == today
            }

            guard !alreadyNotifiedToday else { continue }

            var analysis: String?
            if setting.aiAnalysisEnabled {
                do {
                    analysis = try await aiService.generateAnalysis(
                        stockName: holding.name,
                        symbol: holding.symbol,
                        changePercent: quote.changePercent,
                        market: holding.marketEnum.rawValue
                    )
                } catch {
                    analysis = nil
                }
            }

            let record = AlertRecord(
                symbol: holding.symbol,
                stockName: holding.name,
                changePercent: quote.changePercent,
                pnlAmountCNY: pnl
            )
            record.aiAnalysis = analysis
            modelContext.insert(record)

            await notificationService.sendAlert(
                stockName: holding.name,
                symbol: holding.symbol,
                changePercent: quote.changePercent,
                pnlAmountCNY: pnl,
                aiAnalysis: analysis
            )
        }

        try? modelContext.save()
        loadAlertRecords()
    }

    private func getRate(for holding: StockHolding) -> Double {
        guard let rate = exchangeRate else { return 1 }
        switch holding.marketEnum {
        case .us: return rate.usdToCny
        case .hk: return rate.hkdToCny
        case .aShare: return 1
        }
    }

    func markAlertAsRead(_ alert: AlertRecord) {
        alert.isRead = true
        try? modelContext.save()
    }

    func clearAllAlerts() {
        for alert in alertRecords {
            modelContext.delete(alert)
        }
        try? modelContext.save()
        alertRecords = []
    }

    func loadLastRefreshTime() {
        let ts = UserDefaults.standard.double(forKey: Constants.UserDefaults.lastRefreshKey)
        if ts > 0 {
            lastRefreshTime = Date(timeIntervalSince1970: ts)
        }
    }

    func triggerRefresh() {
        Task {
            await refreshAll()
        }
    }
}

// MARK: - ViewModel Factory (for SwiftUI environment)

struct PortfolioViewModelKey: EnvironmentKey {
    static let defaultValue: PortfolioViewModel? = nil
}

extension EnvironmentValues {
    var portfolioViewModel: PortfolioViewModel? {
        get { self[PortfolioViewModelKey.self] }
        set { self[PortfolioViewModelKey.self] = newValue }
    }
}
