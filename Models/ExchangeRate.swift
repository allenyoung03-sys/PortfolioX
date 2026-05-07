import Foundation
import SwiftData

@Model
final class ExchangeRate {
    var usdToCny: Double
    var hkdToCny: Double
    var updatedAt: Date

    init(usdToCny: Double, hkdToCny: Double, updatedAt: Date = .now) {
        self.usdToCny = usdToCny
        self.hkdToCny = hkdToCny
        self.updatedAt = updatedAt
    }
}
