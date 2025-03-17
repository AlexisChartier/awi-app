import SwiftUI

class BuyersViewModel: ObservableObject {
    @Published var acheteurs: [Acheteur] = []
    @Published var loading = false
    @Published var errorMessage: String?

    func loadAcheteurs() {
        loading = true
        Task {
            do {
                let data = try await AcheteurService.shared.fetchAllAcheteurs()
                await MainActor.run {
                    self.acheteurs = data
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur chargement acheteurs: \(error)"
                    self.loading = false
                }
            }
        }
    }

    func createAcheteur(_ a: Acheteur) {
        loading = true
        Task {
            do {
                let created = try await AcheteurService.shared.createAcheteur(a)
                await MainActor.run {
                    self.acheteurs.append(created)
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur creation acheteur: \(error)"
                    self.loading = false
                }
            }
        }
    }
}
