import SwiftUI

enum MarketColor {
    static func forChange(_ value: Double) -> Color {
        if value > 0 { return .green }
        if value < 0 { return .red }
        return .primary
    }

    static func forMarket(_ market: String) -> Color {
        switch market {
        case "美股": return .blue
        case "A股": return .red
        case "港股": return .green
        default: return .gray
        }
    }

    static let positive = Color.green
    static let negative = Color.red
}
