import SwiftUI

struct DepositsView: View {
    @StateObject var vm = DepositsViewModel()

    // On pourrait avoir un sessionId si on veut charger un certain session
    @State var selectedSessionId: Int = 1

    var body: some View {
        VStack {
            if vm.loading {
                ProgressView()
            } else {
                List(vm.depots, id: \.depot_jeu_id) { depot in
                    VStack(alignment: .leading) {
                        Text("Jeu #\(depot.jeu_id) – Vendeur #\(depot.vendeur_id)")
                        Text("Statut: \(depot.statut)")
                    }
                }
            }
        }
        .navigationTitle("Dépôts")
        .onAppear {
            vm.loadDepotsForSession(selectedSessionId)
        }
    }
}
