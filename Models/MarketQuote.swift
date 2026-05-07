import Foundation
import SwiftData

@Model
final class MarketQuote {
    @Attribute(.unique) var symbol: String
    var price: Double
    var change: Double
    var changePercent: Double
    var currency: String
    var updatedAt: Date

    init(symbol: String, price: Double, change: Double, changePercent: Double, currency: String, updatedAt: Date = .now) {
        self.symbol = symbol
        self.price = price
        self.change = change
        self.changePercent = changePercent
        self.currency = currency
        self.updatedAt = updatedAt
    }
}
