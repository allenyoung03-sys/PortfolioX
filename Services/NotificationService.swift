import UIKit
import UserNotifications

actor NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func sendAlert(
        stockName: String,
        symbol: String,
        changePercent: Double,
        pnlAmountCNY: Double,
        aiAnalysis: String?
    ) async {
        let isDrop = changePercent < 0
        let emoji = isDrop ? "📉" : "📈"
        let percentStr = String(format: "%.1f", abs(changePercent))
        let direction = isDrop ? "下跌" : "上涨"
        let pnlStr = String(format: "%.0f", abs(pnlAmountCNY))
        let pnlDirection = isDrop ? "损失" : "收益"

        let title = "\(emoji) \(stockName) (\(symbol)) \(direction) \(percentStr)%"

        var body = "您今日\(pnlDirection)约 ¥\(pnlStr)"
        if let analysis = aiAnalysis {
            body += "\n\(analysis)"
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if isDrop {
            content.sound = .defaultCritical
        }

        let identifier = "alert-\(symbol)-\(Calendar.current.component(.day, from: Date()))"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to send notification: \(error)")
        }
    }

    func removeDelivered(for symbol: String) async {
        let center = UNUserNotificationCenter.current()
        let identifiers = await center.deliveredNotifications()
            .filter { $0.request.identifier.hasPrefix("alert-\(symbol)-") }
            .map { $0.request.identifier }
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}
