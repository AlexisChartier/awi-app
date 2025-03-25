//
//  BuyersViewModel.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//

import SwiftUI

/// ViewModel dédié à la gestion des acheteurs : création, édition, suppression, recherche.
@MainActor
class BuyersViewModel: ObservableObject {
    // Liste des acheteurs
    @Published var buyers: [Acheteur] = []
    @Published var loading: Bool = false
    @Published var errorMessage: String?

    // Recherche & pagination
    @Published var searchTerm: String = ""
    @Published var currentPage: Int = 1
    private let pageSize: Int = 10

    // Formulaire d'édition / création
    @Published var isEditMode: Bool = false
    @Published var currentBuyer: Acheteur = Acheteur(id: 0, nom: "", email: nil, telephone: nil, adresse: nil)
    @Published var showFormSheet: Bool = false

    // Suppression
    @Published var showDeleteConfirm: Bool = false
    @Published var buyerToDelete: Acheteur?

    /// Charge tous les acheteurs depuis l’API.
    func loadBuyers() {
        loading = true
        Task {
            do {
                let fetched = try await AcheteurService.shared.fetchAllAcheteurs()
                buyers = fetched
            } catch {
                errorMessage = "Erreur lors du chargement des acheteurs: \(error)"
            }
            loading = false
        }
    }

    /// Crée un nouvel acheteur.
    func createBuyer(nom: String, email: String?, telephone: String?, adresse: String?) {
        loading = true
        Task {
            do {
                let newBuyer = Acheteur(id: 0, nom: nom, email: email, telephone: telephone, adresse: adresse)
                _ = try await AcheteurService.shared.createAcheteur(newBuyer)
                loadBuyers()
            } catch {
                errorMessage = "Erreur lors de la création de l'acheteur: \(error)"
                loading = false
            }
        }
    }

    /// Met à jour un acheteur existant.
    func updateBuyer(buyer: Acheteur) {
        loading = true
        Task {
            do {
                let updated = try await AcheteurService.shared.updateAcheteur(buyer)
                if let index = buyers.firstIndex(where: { $0.id == updated.id }) {
                    buyers[index] = updated
                }
            } catch {
                errorMessage = "Erreur lors de la mise à jour de l'acheteur: \(error)"
            }
            loading = false
        }
    }

    /// Supprime un acheteur.
    func deleteBuyer() {
        guard let buyerToDelete = buyerToDelete else { return }
        loading = true
        Task {
            do {
                try await AcheteurService.shared.deleteAcheteur(id: buyerToDelete.id)
                buyers.removeAll { $0.id == buyerToDelete.id }
                self.buyerToDelete = nil
                self.showDeleteConfirm = false
            } catch {
                errorMessage = "Erreur lors de la suppression de l'acheteur: \(error)"
            }
            loading = false
        }
    }

    /// Retourne les acheteurs filtrés par nom ou email.
    var filteredBuyers: [Acheteur] {
        let lowerSearch = searchTerm.lowercased()
        guard !lowerSearch.isEmpty else { return buyers }
        return buyers.filter {
            $0.nom.lowercased().contains(lowerSearch)
            || ($0.email?.lowercased().contains(lowerSearch) ?? false)
        }
    }

    /// Nombre total de pages disponibles.
    var totalPages: Int {
        let count = filteredBuyers.count
        return count == 0 ? 1 : Int(ceil(Double(count) / Double(pageSize)))
    }

    /// Retourne les acheteurs de la page active.
    var paginatedBuyers: [Acheteur] {
        let startIndex = (currentPage - 1) * pageSize
        if startIndex >= filteredBuyers.count { return [] }
        let endIndex = min(startIndex + pageSize, filteredBuyers.count)
        return Array(filteredBuyers[startIndex..<endIndex])
    }

    /// Accède à une page donnée.
    func goToPage(_ page: Int) {
        currentPage = max(1, min(page, totalPages))
    }

    /// Ouvre le formulaire pour créer un acheteur.
    func openCreateForm() {
        isEditMode = false
        currentBuyer = Acheteur(id: 0, nom: "", email: nil, telephone: nil, adresse: nil)
        showFormSheet = true
    }

    /// Ouvre le formulaire pour modifier un acheteur.
    func openEditForm(buyer: Acheteur) {
        isEditMode = true
        currentBuyer = buyer
        showFormSheet = true
    }

    /// Ferme le formulaire sans sauvegarde.
    func closeForm() {
        showFormSheet = false
    }

    /// Enregistre l'acheteur courant (création ou mise à jour).
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
