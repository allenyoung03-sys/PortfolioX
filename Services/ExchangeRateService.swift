import Foundation

actor ExchangeRateService {
    static let shared = ExchangeRateService()

    private init() {}

    func fetchRateUSD() async throws -> Double {
        guard let url = URL(string: "\(Constants.ExchangeRateAPI.fallbackUSD)") else {
            throw ServiceError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let rates = json?["rates"] as? [String: Any],
              let cny = rates["CNY"] as? Double else {
            throw ServiceError.parseError
        }
        return cny
    }

    func fetchRateHKD() async throws -> Double {
        guard let url = URL(string: "\(Constants.ExchangeRateAPI.fallbackHKD)") else {
            throw ServiceError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let rates = json?["rates"] as? [String: Any],
              let cny = rates["CNY"] as? Double else {
            throw ServiceError.parseError
        }
        return cny
    }

    func fetchAllRates() async throws -> (usdToCny: Double, hkdToCny: Double) {
        async let usd = fetchRateUSD()
        async let hkd = fetchRateHKD()
        return try await (usd, hkd)
    }

    enum ServiceError: Error, LocalizedError {
        case invalidURL
        case parseError

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "无效的URL"
            case .parseError: return "汇率数据解析失败"
            }
        }
    }
}
