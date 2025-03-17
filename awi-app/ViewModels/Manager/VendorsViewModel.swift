import SwiftUI

class VendorsViewModel: ObservableObject {
    @Published var vendors: [Vendeur] = []
    @Published var loading = false
    @Published var errorMessage: String?

    func loadVendors() {
        loading = true
        Task {
            do {
                let fetched = try await VendeurService.shared.fetchAllVendeurs()
                await MainActor.run {
                    self.vendors = fetched
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur chargement vendeurs: \(error)"
                    self.loading = false
                }
            }
        }
    }

    func createVendor(_ v: Vendeur) {
        loading = true
        Task {
            do {
                let newV = try await VendeurService.shared.createVendeur(v)
                await MainActor.run {
                    self.vendors.append(newV)
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur creation vendeur: \(error)"
                    self.loading = false
                }
            }
        }
    }

    func deleteVendor(id: Int) {
        loading = true
        Task {
            do {
                try await VendeurService.shared.deleteVendeur(id: id)
                await MainActor.run {
                    self.vendors.removeAll { $0.id == id }
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur suppression vendeur: \(error)"
                    self.loading = false
                }
            }
        }
    }
}
