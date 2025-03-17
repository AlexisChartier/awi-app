import SwiftUI

class CatalogViewModel: ObservableObject {
    @Published var jeux: [JeuRequest] = []
    @Published var loading = false
    @Published var errorMessage: String?

    func loadJeux() {
        loading = true
        Task {
            do {
                let data = try await JeuService.shared.getAll()
                await MainActor.run {
                    self.jeux = data
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur chargement jeux: \(error)"
                    self.loading = false
                }
            }
        }
    }

    func createJeu(_ jeu: JeuRequest) {
        loading = true
        Task {
            do {
                let newJeu = try await JeuService.shared.create(data: jeu)
                await MainActor.run {
                    self.jeux.append(newJeu)
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur creation jeu: \(error)"
                    self.loading = false
                }
            }
        }
    }

    func deleteJeu(_ id: Int) {
        loading = true
        Task {
            do {
                try await JeuService.shared.delete(id: id)
                await MainActor.run {
                    self.jeux.removeAll { $0.jeu_id == id }
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur suppression jeu: \(error)"
                    self.loading = false
                }
            }
        }
    }
}
