import SwiftUI

struct StatsView: View {
    @StateObject var vm = StatsViewModel()

    var body: some View {
        VStack {
            if vm.loading {
                ProgressView()
            } else if let stats = vm.stats {
                Text("Ventes totales: \(stats.totalVentes)")
                Text("CA: \(stats.totalCA, format: .number)")
            } else if let error = vm.errorMessage {
                Text(error).foregroundColor(.red)
            } else {
                Text("Aucune donnée de stats.")
            }
        }
        .navigationTitle("Statistiques")
        .onAppear {
            vm.loadStats()
        }
    }
}
