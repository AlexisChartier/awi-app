import SwiftUI

struct AdminTabView: View {
    @EnvironmentObject var vm: AuthViewModel

    init() {
        UITabBar.appearance().backgroundColor = UIColor.systemGroupedBackground
    }

    var body: some View {
        TabView {
            NavigationStack {
                UserManagementView()
                    .navigationTitle("Utilisateurs")
            }
            .tabItem {
                Label("Utilisateurs", systemImage: "person.3.fill")
            }

            NavigationStack {
                SessionManagementView()
                    .navigationTitle("Sessions")
            }
            .tabItem {
                Label("Sessions", systemImage: "calendar.badge.clock")
            }

            NavigationStack {
                StatsView()
                    .navigationTitle("Statistiques")
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }

            NavigationStack {
                SettingsView(vm: vm)
            }
            .tabItem {
                Label("Compte", systemImage: "gear")
            }
        }
        .accentColor(.indigo)
    }
}
