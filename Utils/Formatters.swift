import Foundation

enum Formatters {
    static let currencyCNY: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CNY"
        f.currencySymbol = "¥"
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }()

    static let currencyUSD: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.currencySymbol = "$"
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }()

    static let percent: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        f.multiplier = 1
        return f
    }()

    static let price: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        f.groupingSeparator = ","
        return f
    }()

    static let shares: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 0
        return f
    }()

    static func formatCNY(_ value: Double) -> String {
        // Handle negative values with -¥ prefix instead of locale-dependent parentheses
        let absValue = abs(value)
        let formatted = currencyCNY.string(from: NSNumber(value: absValue)) ?? "¥0.00"
        if value < 0 {
            return "-\(formatted)"
        }
        return formatted
    }

    static func formatUSD(_ value: Double) -> String {
        currencyUSD.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    static func formatPercent(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        // NumberFormatter with .percent style already appends "%"
        return "\(sign)\(percent.string(from: NSNumber(value: value)) ?? "0.00")"
    }

    static func formatPrice(_ value: Double) -> String {
        price.string(from: NSNumber(value: value)) ?? "0.00"
    }

    static func formatChange(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(price.string(from: NSNumber(value: value)) ?? "0.00")"
    }
}

extension Double {
    func formattedCNY() -> String { Formatters.formatCNY(self) }
    func formattedPercent() -> String { Formatters.formatPercent(self) }
    func formattedPrice() -> String { Formatters.formatPrice(self) }
    func formattedChange() -> String { Formatters.formatChange(self) }
}
