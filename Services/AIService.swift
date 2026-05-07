import Foundation

actor AIService {
    static let shared = AIService()

    private init() {}

    func generateAnalysis(stockName: String, symbol: String, changePercent: Double, market: String) async throws -> String {
        return "AI 行情分析功能即将上线，敬请期待。"
    }
}
