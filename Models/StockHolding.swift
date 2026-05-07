import Foundation
import SwiftData

enum Market: String, Codable, CaseIterable {
    case us = "美股"
    case aShare = "A股"
    case hk = "港股"

    var currency: Currency {
        switch self {
        case .us: return .usd
        case .aShare: return .cny
        case .hk: return .hkd
        }
    }

    var exchangeSuffix: String {
        switch self {
        case .us: return ""
        case .aShare: return ""
        case .hk: return ".HK"
        }
    }

    var tencentPrefix: String {
        switch self {
        case .us: return "us"
        case .aShare: return ""
        case .hk: return "hk"
        }
    }

    var displayColor: String {
        switch self {
        case .us: return "blue"
        case .aShare: return "red"
        case .hk: return "green"
        }
    }
}

enum Currency: String, Codable {
    case usd = "USD"
    case hkd = "HKD"
    case cny = "CNY"
}

@Model
final class StockHolding {
    @Attribute(.unique) var symbol: String
    var name: String
    var market: String // Market rawValue
    var shares: Double
    var avgCost: Double?
    var createdAt: Date
    var sortOrder: Int

    init(symbol: String, name: String, market: Market, shares: Double, avgCost: Double? = nil, sortOrder: Int = 0) {
        self.symbol = symbol
        self.name = name
        self.market = market.rawValue
        self.shares = shares
        self.avgCost = avgCost
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }

    var marketEnum: Market {
        Market(rawValue: market) ?? .us
    }
}
