import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewModel: PomodoroViewModel
    
    var body: some View {
        TabView(selection: $appState.activeView) {
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(AppState.MainViewType.stats)
            
            SettingsView()
                .environmentObject(viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(AppState.MainViewType.settings)
        }
        .frame(minWidth: 400, idealWidth: 450, minHeight: 480, idealHeight: 550)
    }
} 