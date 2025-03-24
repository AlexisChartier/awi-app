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
                Label("Utilisateurs", systemImage: "person.2.fill")
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
                Label("Stats", systemImage: "chart.bar.xaxis")
            }

            NavigationStack {
                SettingsView(vm: vm)
            }
            .tabItem {
                Label("Compte", systemImage: "gear")
            }
        }
        .accentColor(.blue) // Personnalise la couleur principale du TabView
    }
}
