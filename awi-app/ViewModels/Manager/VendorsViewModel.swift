import SwiftUI

class VendorsViewModel: ObservableObject {
    @Published var vendors: [Vendeur] = []
    @Published var loading: Bool = false
    @Published var errorMessage: String?

    // Recherche & Pagination
    @Published var searchTerm: String = ""
    @Published var currentPage: Int = 1
    let pageSize: Int = 10

    // Création / Édition
    @Published var isEditMode: Bool = false
    @Published var currentVendor: Vendeur = Vendeur(id: 0, nom: "", email: "", telephone: "")
    @Published var showFormSheet: Bool = false

    // Suppression
    @Published var showDeleteConfirm: Bool = false
    @Published var vendorToDelete: Vendeur?

    // Initial load
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

    func createVendor(nom: String, email: String, telephone: String) {
        loading = true
        Task {
            do {
                let newV = Vendeur(id: nil, nom: nom, email: email, telephone: telephone)
                let created = try await VendeurService.shared.createVendeur(newV)
                await MainActor.run {
                    //self.vendors.append(created)
                    loadVendors()
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur création vendeur: \(error)"
                    print(error)
                    self.loading = false
                }
            }
        }
    }

    func updateVendor(id: Int, nom: String, email: String, telephone: String) {
        loading = true
        Task {
            do {
                let updatedVend = Vendeur(id: id, nom: nom, email: email, telephone: telephone)
                let updated = try await VendeurService.shared.updateVendeur(updatedVend)
                await MainActor.run {
                    if let idx = self.vendors.firstIndex(where: { $0.id == id }) {
                        self.vendors[idx] = updated
                    }
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur mise à jour vendeur: \(error)"
                    self.loading = false
                }
            }
        }
    }

    func deleteVendor() {
        guard let vendorToDelete = vendorToDelete else { return }
        loading = true
        Task {
            do {
                try await VendeurService.shared.deleteVendeur(id: vendorToDelete.id!)
                await MainActor.run {
                    self.vendors.removeAll { $0.id == vendorToDelete.id }
                    self.vendorToDelete = nil
                    self.showDeleteConfirm = false
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

    // MARK: Recherche
    var filteredVendors: [Vendeur] {
        let lowerSearch = searchTerm.lowercased()
        if lowerSearch.isEmpty { return vendors }
        return vendors.filter {
            $0.nom.lowercased().contains(lowerSearch)
            || $0.email.lowercased().contains(lowerSearch)
        }
    }

    // MARK: Pagination
    var totalPages: Int {
        let count = filteredVendors.count
        return count == 0 ? 1 : Int(ceil(Double(count) / Double(pageSize)))
    }

    var paginatedVendors: [Vendeur] {
        let startIndex = (currentPage - 1) * pageSize
        if startIndex >= filteredVendors.count { return [] }
        let endIndex = min(startIndex + pageSize, filteredVendors.count)
        return Array(filteredVendors[startIndex..<endIndex])
    }

    func goToPage(_ page: Int) {
        currentPage = max(1, min(page, totalPages))
    }

    // MARK: Formulaire
    func openCreateForm() {
        isEditMode = false
        currentVendor = Vendeur(id: 0, nom: "", email: "", telephone: "")
        showFormSheet = true
    }

    func openEditForm(vendor: Vendeur) {
        isEditMode = true
        currentVendor = vendor
        showFormSheet = true
    }

    func closeForm() {
        showFormSheet = false
    }

    func saveVendorForm() {
        if isEditMode {
            updateVendor(id: currentVendor.id!,
                         nom: currentVendor.nom,
                         email: currentVendor.email,
                         telephone: currentVendor.telephone)
        } else {
            createVendor(nom: currentVendor.nom,
                         email: currentVendor.email,
                         telephone: currentVendor.telephone)
        }
        closeForm()
    }
}
