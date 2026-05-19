import Foundation

enum Constants {
    enum SinaFinance {
        static let baseURL = "https://hq.sinajs.cn/list"
    }

    enum ExchangeRateAPI {
        static let baseURL = "https://api.exchangerate-api.com/v4/latest/"
        static let fallbackUSD = "https://open.er-api.com/v6/latest/USD"
        static let fallbackHKD = "https://open.er-api.com/v6/latest/HKD"
    }


    static let maxStockCount = 20
    static let refreshInterval: TimeInterval = 15 * 60
    static let snapshotInterval: TimeInterval = 1800
    static let defaultThresholdPercent: Double = 5.0
    static let defaultMinAmountCNY: Double = 1000.0

    enum UserDefaults {
        static let lastRefreshKey = "lastRefreshTime"
        static let disclaimerAccepted = "disclaimerAccepted"
        static let hasSeenOnboarding = "hasSeenOnboarding"
    }

    static let disclaimerText = """
    本 App 提供的所有数据、分析和信息仅供参考，不构成任何投资建议。\
    股票行情数据可能存在延迟，AI 分析内容由人工智能生成，仅供参考。\
    投资有风险，决策需谨慎。
    """
}
