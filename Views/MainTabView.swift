import SwiftUI
import SwiftData
import Combine

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PortfolioViewModel?

    var body: some View {
        ZStack {
            if let vm = viewModel {
                TabView {
                    OverviewView()
                        .tabItem {
                            Label("总览", systemImage: "chart.pie.fill")
                        }

                    PortfolioListView()
                        .tabItem {
                            Label("持仓", systemImage: "list.bullet.rectangle")
                        }

                    AddStockView()
                        .tabItem {
                            Label("添加", systemImage: "plus.circle")
                        }

                    AlertsListView()
                        .tabItem {
                            Label("提醒", systemImage: "bell.fill")
                        }

                    SettingsView()
                        .tabItem {
                            Label("设置", systemImage: "gearshape.fill")
                        }
                }
                .tint(.green)
                .environment(\.portfolioViewModel, vm)
            } else {
                ProgressView("加载中...")
            }
        }
        .task {
            guard viewModel == nil else { return }
            let vm = PortfolioViewModel(modelContext: modelContext)
            viewModel = vm
            vm.loadCache()
            vm.loadLastRefreshTime()
            await vm.refreshAll()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("BackgroundRefresh"))) { _ in
            guard let vm = viewModel else { return }
            Task { await vm.refreshAll() }
        }
    }
}

#Preview {
    MainTabView()
}
