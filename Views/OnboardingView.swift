import SwiftUI

struct OnboardingView: View {
    @Binding var isShowing: Bool

    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            systemImage: "chart.pie.fill",
            title: "欢迎使用合盈",
            subtitle: "多市场投资组合追踪",
            description: "一站式管理你的 A 股、美股、港股持仓，\n随时掌握资产全貌。"
        ),
        OnboardingPage(
            systemImage: "building.columns.fill",
            title: "多市场支持",
            subtitle: "A 股 · 美股 · 港股",
            description: "同时管理三个市场的股票持仓，\n各市场资产自动汇总到总览。"
        ),
        OnboardingPage(
            systemImage: "arrow.triangle.2.circlepath",
            title: "实时行情与汇率",
            subtitle: "自动获取最新数据",
            description: "自动获取股票实时报价和当日涨跌，\n美元/港币资产按汇率换算为人民币。"
        ),
        OnboardingPage(
            systemImage: "bell.badge.fill",
            title: "智能预警通知",
            subtitle: "不错过重要波动",
            description: "自定义涨跌幅阈值，触发时推送通知，\nAI 分析帮你快速了解市场动态。"
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Page content
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Page indicator
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(currentPage == index ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: currentPage == index ? 24 : 8, height: 8)
                        .animation(.spring(duration: 0.3), value: currentPage)
                }
            }
            .padding(.bottom, 24)

            // Action button
            Button {
                if currentPage < pages.count - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    isShowing = false
                }
            } label: {
                Text(currentPage < pages.count - 1 ? "下一步" : "开始使用")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 12)

            if currentPage < pages.count - 1 {
                Button("跳过") {
                    isShowing = false
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 40)
            } else {
                // Last page: show disclaimer
                Text(Constants.disclaimerText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground))
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: page.systemImage)
                .font(.system(size: 72))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, options: .speed(0.5), value: currentPage)

            VStack(spacing: 8) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)

                Text(page.subtitle)
                    .font(.headline)
                    .foregroundStyle(.green)
            }

            Text(page.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)

            Spacer()
        }
    }
}

private struct OnboardingPage {
    let systemImage: String
    let title: String
    let subtitle: String
    let description: String
}
