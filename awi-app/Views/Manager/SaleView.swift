import SwiftUI

struct SaleView: View {
    @StateObject var vm = SaleViewModel()

    var body: some View {
        VStack {
            if vm.loading {
                ProgressView()
            } else {
                // Ex. un bouton pour créer une vente
                Button("Créer Vente") {
                    let newVente = VenteRequest(vente_id: nil, acheteur_id: nil, date_vente: nil, montant_total: 100.0, session_id: 1)
                    Task {
                        _ = await vm.createVente(newVente)
                    }
                }
                // Affichage des ventes
                List(vm.ventes, id: \.vente_id) { vente in
                    Text("Vente #\(vente.vente_id ?? 0) - Montant: \(vente.montant_total)")
                }
            }
        }
        .navigationTitle("Ventes")
        .onAppear {
            vm.loadSalesBySession(1)
        }
    }
}
