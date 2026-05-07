import Foundation
import SwiftData

@Model
final class AlertSetting {
    var thresholdPercent: Double
    var minAmountCNY: Double
    var isEnabled: Bool
    var aiAnalysisEnabled: Bool

    init(thresholdPercent: Double = 5.0, minAmountCNY: Double = 1000, isEnabled: Bool = true, aiAnalysisEnabled: Bool = true) {
        self.thresholdPercent = thresholdPercent
        self.minAmountCNY = minAmountCNY
        self.isEnabled = isEnabled
        self.aiAnalysisEnabled = aiAnalysisEnabled
    }
}
