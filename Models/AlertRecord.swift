import Foundation
import SwiftData

@Model
final class AlertRecord {
    var symbol: String
    var stockName: String
    var changePercent: Double
    var pnlAmountCNY: Double
    var aiAnalysis: String?
    var createdAt: Date
    var isRead: Bool

    init(symbol: String, stockName: String, changePercent: Double, pnlAmountCNY: Double, aiAnalysis: String? = nil) {
        self.symbol = symbol
        self.stockName = stockName
        self.changePercent = changePercent
        self.pnlAmountCNY = pnlAmountCNY
        self.aiAnalysis = aiAnalysis
        self.createdAt = Date()
        self.isRead = false
    }
}
