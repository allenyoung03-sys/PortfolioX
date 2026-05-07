import Foundation
import SwiftData

actor StockQuoteService {
    static let shared = StockQuoteService()

    private var cachedQuotes: [String: (quote: MarketQuote, timestamp: Date)] = [:]

    private init() {}

    func fetchQuote(for symbol: String, market: Market) async throws -> MarketQuote {
        let cacheKey = "\(market.rawValue):\(symbol)"

        if let cached = cachedQuotes[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < 60 {
            return cached.quote
        }

        let result = try await fetchTencentQuotes(symbols: [symbol], market: market)
        guard let quote = result[symbol] else {
            throw ServiceError.parseError
        }

        cachedQuotes[cacheKey] = (quote, Date())
        return quote
    }

    func fetchQuotes(for holdings: [StockHolding]) async throws -> [String: MarketQuote] {
        var results: [String: MarketQuote] = [:]
        var usSymbols: [String] = []
        var hkSymbols: [String] = []
        var aSymbols: [String] = []

        for h in holdings {
            switch h.marketEnum {
            case .us: usSymbols.append(h.symbol)
            case .hk: hkSymbols.append(h.symbol)
            case .aShare: aSymbols.append(h.symbol)
            }
        }

        // Each market's fetch is independent — one failure doesn't block others
        try await withThrowingTaskGroup(of: [String: MarketQuote].self) { group in
            if !usSymbols.isEmpty {
                group.addTask { (try? await self.fetchTencentQuotes(symbols: usSymbols, market: .us)) ?? [:] }
            }
            if !hkSymbols.isEmpty {
                group.addTask { (try? await self.fetchTencentQuotes(symbols: hkSymbols, market: .hk)) ?? [:] }
            }
            if !aSymbols.isEmpty {
                group.addTask { (try? await self.fetchSinaQuotes(symbols: aSymbols)) ?? [:] }
            }

            for try await batch in group {
                results.merge(batch) { $1 }
            }
        }

        if results.isEmpty {
            throw ServiceError.parseError
        }
        return results
    }

    // MARK: - Tencent Finance (美股 & 港股)

    private func fetchTencentQuotes(symbols: [String], market: Market) async throws -> [String: MarketQuote] {
        let prefix = (market == .us) ? "us" : "hk"

        // Tencent API requires HK symbols in 5-digit format (e.g. "00700" not "0700")
        let apiSymbols = symbols.map { symbol -> String in
            if market == .hk, let code = Int(symbol) {
                return String(format: "%05d", code)
            }
            return symbol
        }
        // Track mapping: API symbol → original symbol for HK stocks
        var symbolMap: [String: String] = [:]
        for (orig, api) in zip(symbols, apiSymbols) {
            symbolMap[api] = orig
        }

        let joined = apiSymbols.map { "\(prefix)\($0)" }.joined(separator: ",")
        let urlString = "https://qt.gtimg.cn/q=\(joined)"
        guard let url = URL(string: urlString) else { throw ServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ServiceError.networkError(URLError(.badServerResponse))
        }

        // Try GB18030 (Tencent API uses GBK/GB18030 encoding for Chinese characters),
        // fall back to UTF-8, then to ISO Latin-1 which never fails.
        let gbkEncoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
        let text: String
        if let decoded = String(data: data, encoding: gbkEncoding) {
            text = decoded
        } else if let decoded = String(data: data, encoding: .utf8) {
            text = decoded
        } else {
            // isoLatin1 maps every byte to a Unicode character — always succeeds.
            // The Chinese stock name field will be garbled, but all ASCII fields
            // (prices, separators, v_ prefix) are preserved correctly.
            text = String(data: data, encoding: .isoLatin1) ?? ""
        }

        var quotes: [String: MarketQuote] = [:]
        for line in text.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix("v_"),
                  let valueStart = trimmed.firstIndex(of: "\""),
                  let valueEnd = trimmed.lastIndex(of: "\"") else { continue }

            let value = trimmed[trimmed.index(after: valueStart)..<valueEnd]
            let parts = value.components(separatedBy: "~")
            guard parts.count >= 36 else { continue }

            // parts[3] = current price, parts[4] = previous close
            guard let price = Double(parts[3]), let prevClose = Double(parts[4]) else { continue }

            let change = price - prevClose
            let changePercent = prevClose > 0 ? (change / prevClose) * 100 : 0

            // Extract symbol from the Tencent variable name (v_usSYMBOL or v_hkSYMBOL)
            // For HK stocks, map the 5-digit API symbol back to the original stored symbol
            let varPrefix = market == .us ? "v_us" : "v_hk"
            let extractedSymbol = trimmed
                .dropFirst(varPrefix.count)
                .prefix(while: { $0 != "=" })
            let apiSymbol = String(extractedSymbol)
            let symbol = symbolMap[apiSymbol] ?? apiSymbol

            let quote = MarketQuote(
                symbol: symbol,
                price: price,
                change: change,
                changePercent: changePercent,
                currency: market.currency.rawValue
            )
            quotes[symbol] = quote
        }

        if quotes.isEmpty { throw ServiceError.parseError }
        return quotes
    }

    // MARK: - Sina Finance (A股)

    private func fetchSinaQuotes(symbols: [String]) async throws -> [String: MarketQuote] {
        let joined = symbols.map { "\(aSharePrefix(for: $0))\($0)" }.joined(separator: ",")
        let urlString = "\(Constants.SinaFinance.baseURL)=\(joined)"
        guard let url = URL(string: urlString) else { throw ServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.setValue("https://finance.sina.com.cn", forHTTPHeaderField: "Referer")

        let (data, _) = try await URLSession.shared.data(for: request)
        return try parseSinaResponse(data: data)
    }

    private func parseSinaResponse(data: Data) throws -> [String: MarketQuote] {
        let gbkEncoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
        let text: String
        if let decoded = String(data: data, encoding: gbkEncoding) {
            text = decoded
        } else if let decoded = String(data: data, encoding: .utf8) {
            text = decoded
        } else {
            text = String(data: data, encoding: .isoLatin1) ?? ""
        }

        var quotes: [String: MarketQuote] = [:]
        let lines = text.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty }

        for line in lines {
            guard let valueStr = line.components(separatedBy: "\"").dropFirst().first else { continue }
            let parts = valueStr.components(separatedBy: ",")
            guard parts.count >= 32 else { continue }

            let price = Double(parts[3]) ?? 0
            let prevClose = Double(parts[2]) ?? price
            let change = price - prevClose
            let changePercent = prevClose > 0 ? (change / prevClose) * 100 : 0

            guard let varPart = line.components(separatedBy: "\"").first else { continue }

            // varPart = "var hq_str_sh600519=" → extract "600519"
            let raw = varPart
                .replacingOccurrences(of: "var hq_str_", with: "")
                .replacingOccurrences(of: ";", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "="))
            let symbol = String(raw.dropFirst(2))

            quotes[symbol] = MarketQuote(
                symbol: symbol,
                price: price,
                change: change,
                changePercent: changePercent,
                currency: "CNY"
            )
        }

        if quotes.isEmpty { throw ServiceError.parseError }
        return quotes
    }

    /// Determine Shanghai (sh) or Shenzhen (sz) prefix for A-share symbols
    /// Shanghai: 5 (funds/ETFs), 6, 7 (科创板), 9
    /// Shenzhen: 0, 2, 3
    private func aSharePrefix(for symbol: String) -> String {
        if symbol.hasPrefix("5") || symbol.hasPrefix("6") || symbol.hasPrefix("7") || symbol.hasPrefix("9") {
            return "sh"
        }
        return "sz"
    }

    enum ServiceError: Error, LocalizedError {
        case invalidURL
        case parseError
        case networkError(Error)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "无效的URL"
            case .parseError: return "数据解析失败"
            case .networkError(let e): return "网络错误: \(e.localizedDescription)"
            }
        }
    }
}
