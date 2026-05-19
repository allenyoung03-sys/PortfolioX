import Foundation
import SwiftData

@Model
final class PortfolioSnapshot {
    @Attribute(.unique) var id: UUID
    var totalValueCNY: Double
    var totalUnrealizedPnL: Double
    var timestamp: Date

    init(totalValueCNY: Double, totalUnrealizedPnL: Double) {
        self.id = UUID()
        self.totalValueCNY = totalValueCNY
        self.totalUnrealizedPnL = totalUnrealizedPnL
        self.timestamp = Date()
    }
}
