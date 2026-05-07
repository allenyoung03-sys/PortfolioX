import SwiftUI

struct SettingsView: View {
    @Environment(\.portfolioViewModel) private var vm
    @State private var thresholdText = ""
    @State private var minAmountText = ""
    @State private var alertEnabled = true
    @State private var aiEnabled = true
    @State private var apiKey = ""
    @State private var showDisclaimer = false
    @State private var showAPIKeySaved = false

    var body: some View {
        NavigationStack {
            Form {
                Section("预警设置") {
                    Toggle("启用波动预警", isOn: $alertEnabled)
                        .onChange(of: alertEnabled) { _, newValue in
                            vm?.alertSetting?.isEnabled = newValue
                        }

                    if alertEnabled {
                        HStack {
                            Text("涨跌幅阈值 (%)")
                            Spacer()
                            TextField("5.0", text: $thresholdText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .onSubmit {
                                    if let val = Double(thresholdText) {
                                        vm?.alertSetting?.thresholdPercent = val
                                    }
                                }
                        }

                        HStack {
                            Text("金额阈值 (¥)")
                            Spacer()
                            TextField("1000", text: $minAmountText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .onSubmit {
                                    if let val = Double(minAmountText) {
                                        vm?.alertSetting?.minAmountCNY = val
                                    }
                                }
                        }
                    }

                    Toggle("AI 分析", isOn: $aiEnabled)
                        .onChange(of: aiEnabled) { _, newValue in
                            vm?.alertSetting?.aiAnalysisEnabled = newValue
                        }
                }

                Section("AI 分析") {
                    Text("AI 行情分析功能即将上线，敬请期待。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Button("免责声明") {
                        showDisclaimer = true
                    }
                }

                Section {
                    Text(Constants.disclaimerText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("免责声明")
                }
            }
            .navigationTitle("设置")
            .alert("已保存", isPresented: $showAPIKeySaved) {
                Button("好的", role: .cancel) {}
            } message: {
                Text("API Key 已保存，AI 分析功能将使用此 Key")
            }
            .sheet(isPresented: $showDisclaimer) {
                disclaimerView
            }
            .onAppear {
                loadSettings()
            }
        }
    }

    private func loadSettings() {
        guard let setting = vm?.alertSetting else { return }
        thresholdText = String(format: "%.1f", setting.thresholdPercent)
        minAmountText = String(format: "%.0f", setting.minAmountCNY)
        alertEnabled = setting.isEnabled
        aiEnabled = setting.aiAnalysisEnabled
    }

    private var disclaimerView: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.yellow)

                Text("免责声明")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(Constants.disclaimerText)
                    .font(.body)
                    .foregroundStyle(.secondary)

                Text("数据来源说明")
                    .font(.headline)
                    .padding(.top)

                VStack(alignment: .leading, spacing: 8) {
                    Text("• 美股行情数据来自 Yahoo Finance，延迟约 15 分钟")
                    Text("• A股行情数据来自新浪财经，延迟约 15 分钟")
                    Text("• 港股行情数据来自 Yahoo Finance，延迟约 15 分钟")
                    Text("• 汇率数据来自 ExchangeRate-API，每日更新")
                    Text("• AI 分析由 Anthropic Claude 生成")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") { showDisclaimer = false }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
