import SwiftUI

class DepositsViewModel: ObservableObject {
    @Published var depots: [DepotJeuRequest] = []
    @Published var loading: Bool = false
    @Published var errorMessage: String?

    func loadDepotsForSession(_ sessionId: Int) {
        loading = true
        Task {
            do {
                let fetched = try await DepotJeuService.shared.getDepotsSessions(sessionId: sessionId)
                await MainActor.run {
                    self.depots = fetched
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur chargement depots: \(error)"
                    self.loading = false
                }
            }
        }
    }

    func createManyDepots(_ depotsToCreate: [DepotJeuRequest]) {
        loading = true
        Task {
            do {
                try await DepotJeuService.shared.createMany(depots: depotsToCreate)
                // Recharger la liste si besoin
                await MainActor.run {
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur creation multiple depots: \(error)"
                    self.loading = false
                }
            }
        }
    }

    func updateDepotStatut(depotId: Int, statut: String) {
        loading = true
        Task {
            do {
                try await DepotJeuService.shared.updateDepotStatut(depotId: depotId, statut: statut)
                // Mettre à jour localement
                await MainActor.run {
                    if let idx = self.depots.firstIndex(where: { $0.depot_jeu_id == depotId }) {
                        self.depots[idx].statut = statut
                    }
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur update statut depot: \(error)"
                    self.loading = false
                }
            }
        }
    }
}
