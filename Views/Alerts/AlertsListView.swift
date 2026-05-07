import SwiftUI

struct AlertsListView: View {
    @Environment(\.portfolioViewModel) private var vm

    var body: some View {
        NavigationStack {
            Group {
                if let vm = vm {
                    if vm.alertRecords.isEmpty {
                        ContentUnavailableView(
                            "暂无提醒",
                            systemImage: "bell.slash",
                            description: Text("当股票涨跌幅超过阈值时将收到推送通知")
                        )
                    } else {
                        List {
                            ForEach(vm.alertRecords, id: \.persistentModelID) { alert in
                                AlertRowView(alert: alert)
                                    .onTapGesture {
                                        vm.markAlertAsRead(alert)
                                    }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    let alert = vm.alertRecords[index]
                                    vm.markAlertAsRead(alert)
                                }
                            }
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("提醒")
            .toolbar {
                if let vm = vm, !vm.alertRecords.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("清空") {
                            vm.clearAllAlerts()
                        }
                    }
                }
            }
        }
    }
}

struct AlertRowView: View {
    let alert: AlertRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: alert.changePercent >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundStyle(MarketColor.forChange(alert.changePercent))
                    .font(.caption)

                Text("\(alert.stockName) (\(alert.symbol))")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(alert.changePercent.formattedPercent())
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(MarketColor.forChange(alert.changePercent))
            }

            Text("盈亏: \(alert.pnlAmountCNY.formattedCNY())")
                .font(.caption)
                .foregroundStyle(MarketColor.forChange(alert.pnlAmountCNY))

            if let analysis = alert.aiAnalysis {
                Text(analysis)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            HStack {
                Text(alert.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Text(alert.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Spacer()

                if !alert.isRead {
                    Circle()
                        .fill(.blue)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(alert.isRead ? 0.6 : 1)
    }
}

#Preview {
    AlertsListView()
}
