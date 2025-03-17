import SwiftUI

class SaleViewModel: ObservableObject {
    @Published var ventes: [VenteRequest] = []
    @Published var loading: Bool = false
    @Published var errorMessage: String?

    func loadSalesBySession(_ sessionId: Int) {
        loading = true
        Task {
            do {
                let results = try await VenteService.shared.getSalesBySession(sessionId: sessionId)
                await MainActor.run {
                    self.ventes = results
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur chargement ventes"
                    self.loading = false
                }
            }
        }
    }

    func createVente(_ data: VenteRequest) async -> Int? {
        loading = true
        do {
            let venteId = try await VenteService.shared.createVente(venteData: data)
            await MainActor.run {
                self.loading = false
            }
            return venteId
        } catch {
            await MainActor.run {
                self.errorMessage = "Erreur creation vente"
                self.loading = false
            }
            return nil
        }
    }

    func createVenteJeux(_ venteJeuData: [VenteJeuRequest]) {
        loading = true
        Task {
            do {
                try await VenteService.shared.createVenteJeux(venteJeuData)
                await MainActor.run {
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur creation venteJeux"
                    self.loading = false
                }
            }
        }
    }

    func finalizeSale(venteData: VenteRequest, venteJeuxData: [VenteJeuRequest]) {
        loading = true
        Task {
            do {
                let _ = try await VenteService.shared.finalizeSale(venteData: venteData, venteJeuxData: venteJeuxData)
                // On obtient la vente finalisée
                await MainActor.run {
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur finalisation vente"
                    self.loading = false
                }
            }
        }
    }
}
