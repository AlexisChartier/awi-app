import SwiftUI

@MainActor
class BuyersViewModel: ObservableObject {
    // MARK: - Données principales
    @Published var buyers: [Acheteur] = []
    @Published var loading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Recherche & Pagination
    @Published var searchTerm: String = ""
    @Published var currentPage: Int = 1
    private let pageSize: Int = 10

    // MARK: - Création / Édition
    @Published var isEditMode: Bool = false
    @Published var currentBuyer: Acheteur = Acheteur(id: 0, nom: "", email: nil, telephone: nil, adresse: nil)
    @Published var showFormSheet: Bool = false

    // MARK: - Suppression
    @Published var showDeleteConfirm: Bool = false
    @Published var buyerToDelete: Acheteur?

    // MARK: - Chargement initial
    func loadBuyers() {
        loading = true
        Task {
            do {
                let fetched = try await AcheteurService.shared.fetchAllAcheteurs()
                buyers = fetched
            } catch {
                print(error)
                errorMessage = "Erreur lors du chargement des acheteurs: \(error)"
            }
            loading = false
        }
    }

    // MARK: - Création
    func createBuyer(nom: String, email: String?, telephone: String?, adresse: String?) {
        loading = true
        Task {
            do {
                let newBuyer = Acheteur(id: 0, nom: nom, email: email, telephone: telephone, adresse: adresse)
                let _ = try await AcheteurService.shared.createAcheteur(newBuyer)
                // Après création, on recharge la liste pour rester cohérent
                loadBuyers()
            } catch {
                errorMessage = "Erreur lors de la création de l'acheteur: \(error)"
                loading = false
            }
        }
    }

    // MARK: - Édition
    func updateBuyer(buyer: Acheteur) {
        loading = true
        Task {
            do {
                let updated = try await AcheteurService.shared.updateAcheteur(buyer)
                // On met à jour localement l'acheteur
                if let index = buyers.firstIndex(where: { $0.id == updated.id }) {
                    buyers[index] = updated
                }
            } catch {
                errorMessage = "Erreur lors de la mise à jour de l'acheteur: \(error)"
            }
            loading = false
        }
    }

    // MARK: - Suppression
    func deleteBuyer() {
        guard let buyerToDelete = buyerToDelete else { return }
        loading = true
        Task {
            do {
                try await AcheteurService.shared.deleteAcheteur(id: buyerToDelete.id)
                // Retrait local après suppression
                buyers.removeAll { $0.id == buyerToDelete.id }
                self.buyerToDelete = nil
                self.showDeleteConfirm = false
            } catch {
                errorMessage = "Erreur lors de la suppression de l'acheteur: \(error)"
            }
            loading = false
        }
    }

    // MARK: - Recherche
    var filteredBuyers: [Acheteur] {
        let lowerSearch = searchTerm.lowercased()
        guard !lowerSearch.isEmpty else { return buyers }
        return buyers.filter {
            $0.nom.lowercased().contains(lowerSearch)
            || ($0.email?.lowercased().contains(lowerSearch) ?? false)
        }
    }

    // MARK: - Pagination
    var totalPages: Int {
        let count = filteredBuyers.count
        return count == 0 ? 1 : Int(ceil(Double(count) / Double(pageSize)))
    }

    var paginatedBuyers: [Acheteur] {
        let startIndex = (currentPage - 1) * pageSize
        if startIndex >= filteredBuyers.count { return [] }
        let endIndex = min(startIndex + pageSize, filteredBuyers.count)
        return Array(filteredBuyers[startIndex..<endIndex])
    }

    func goToPage(_ page: Int) {
        currentPage = max(1, min(page, totalPages))
    }

    // MARK: - Formulaire
    func openCreateForm() {
        isEditMode = false
        currentBuyer = Acheteur(id: 0, nom: "", email: nil, telephone: nil, adresse: nil)
        showFormSheet = true
    }

    func openEditForm(buyer: Acheteur) {
        isEditMode = true
        currentBuyer = buyer
        showFormSheet = true
    }

    func closeForm() {
        showFormSheet = false
    }

    func saveBuyerForm() {
        if isEditMode {
            updateBuyer(buyer: currentBuyer)
        } else {
            createBuyer(
                nom: currentBuyer.nom,
                email: currentBuyer.email,
                telephone: currentBuyer.telephone,
                adresse: currentBuyer.adresse
            )
        }
        closeForm()
    }
}
