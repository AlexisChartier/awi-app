//
//  CatalogViewModel.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//

import SwiftUI

/// ViewModel responsable de la gestion du catalogue de jeux (filtrage, tri, pagination, création...).
@MainActor
class CatalogViewModel: ObservableObject {
    @Published var jeux: [Jeu] = []
    @Published var searchTerm: String = ""
    @Published var filterEditeur: String = ""
    @Published var sortKey: SortKey? = .nom
    @Published var sortAsc: Bool = true

    @Published var selectedGames: Set<Int> = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    // Pagination
    @Published var currentPage: Int = 0
    let itemsPerPage = 8

    // Formulaire de création/édition
    @Published var showFormDialog = false
    @Published var isEditMode = false
    @Published var currentGame: Jeu? = nil

    // Suppression
    @Published var showDeleteDialog = false
    @Published var gameToDelete: Jeu? = nil

    // Import CSV
    @Published var csvFileData: Data? = nil

    // Détail
    @Published var showDetailSheet = false
    @Published var detailGame: Jeu? = nil

    /// Clés disponibles pour le tri du catalogue
    enum SortKey {
        case nom, auteur, editeur
    }

    /// Charge tous les jeux du backend
    func loadGames() {
        isLoading = true
        Task {
            do {
                let fetched = try await JeuService.shared.getAllJeux()
                self.jeux = fetched
                self.sortKey = .nom
                self.sortAsc = true
            } catch {
                self.errorMessage = "Erreur chargement catalogue: \(error)"
            }
            self.isLoading = false
        }
    }

    /// Applique le filtrage par nom, auteur ou éditeur
    var filteredJeux: [Jeu] {
        if searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           filterEditeur.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return jeux
        }

        let lower = searchTerm.lowercased()
        return jeux.filter { jeu in
            let matchSearch =
                jeu.nom.lowercased().contains(lower) ||
                (jeu.auteur?.lowercased().contains(lower) ?? false) ||
                (jeu.editeur?.lowercased().contains(lower) ?? false)

            let matchEd = filterEditeur.isEmpty
                || (jeu.editeur?.lowercased() == filterEditeur.lowercased())

            return matchSearch && matchEd
        }
    }

    /// Applique le tri en fonction du champ sélectionné
    var sortedJeux: [Jeu] {
        var array = filteredJeux
        guard let sk = sortKey else { return array }

        array.sort {
            let strA: String
            let strB: String
            switch sk {
            case .nom:
                strA = $0.nom.lowercased()
                strB = $1.nom.lowercased()
            case .auteur:
                strA = $0.auteur?.lowercased() ?? ""
                strB = $1.auteur?.lowercased() ?? ""
            case .editeur:
                strA = $0.editeur?.lowercased() ?? ""
                strB = $1.editeur?.lowercased() ?? ""
            }
            return sortAsc ? strA < strB : strA > strB
        }

        return array
    }

    /// Nombre de pages disponibles
    var totalPages: Int {
        let c = sortedJeux.count
        return c == 0 ? 1 : Int(ceil(Double(c) / Double(itemsPerPage)))
    }

    /// Jeux affichés à la page actuelle
    var pageJeux: [Jeu] {
        let start = currentPage * itemsPerPage
        guard start < sortedJeux.count else { return [] }
        let end = min(start + itemsPerPage, sortedJeux.count)
        return Array(sortedJeux[start..<end])
    }

    func nextPage() {
        if currentPage < totalPages - 1 {
            currentPage += 1
        }
    }

    func prevPage() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }

    /// Ajoute ou retire un jeu de la sélection multiple
    func toggleSelectGame(_ jeuId: Int) {
        if selectedGames.contains(jeuId) {
            selectedGames.remove(jeuId)
        } else {
            selectedGames.insert(jeuId)
        }
    }

    /// Supprime tous les jeux sélectionnés
    func deleteSelectedGames() {
        Task {
            do {
                for jeuId in selectedGames {
                    try await JeuService.shared.delete(id: jeuId)
                }
                loadGames()
                selectedGames.removeAll()
            } catch {
                errorMessage = "Erreur suppression groupée"
            }
        }
    }

    // Suppression individuelle
    func openDeleteDialog(_ jeu: Jeu) {
        gameToDelete = jeu
        showDeleteDialog = true
    }

    func closeDeleteDialog() {
        showDeleteDialog = false
        gameToDelete = nil
    }

    func confirmDeleteGame() {
        guard let toDel = gameToDelete, let jid = toDel.id else { return }
        Task {
            do {
                try await JeuService.shared.delete(id: jid)
                loadGames()
            } catch {
                errorMessage = "Erreur suppression jeu"
            }
            showDeleteDialog = false
        }
    }

    // Formulaire
    func openCreateDialog() {
        isEditMode = false
        currentGame = Jeu(
            id: nil, nom: "", auteur: nil, editeur: nil,
            nbJoueurs: nil, ageMin: nil, duree: nil,
            typeJeu: nil, notice: nil, themes: nil, description: nil,
            image: nil, logo: nil
        )
        showFormDialog = true
    }

    func openEditDialog(_ jeu: Jeu) {
        isEditMode = true
        currentGame = jeu
        showFormDialog = true
    }

    func closeFormDialog() {
        showFormDialog = false
        errorMessage = nil
    }

    func openDetailDialog(_ jeu: Jeu) {
        detailGame = jeu
        showDetailSheet = true
    }

    func closeDetailDialog() {
        showDetailSheet = false
        detailGame = nil
    }

    func saveGame(_ newGame: Jeu, imageFile: Data?) {
        Task {
            do {
                if isEditMode, let jid = newGame.id {
                    _ = try await JeuService.shared.update(id: jid, data: newGame)
                } else {
                    if let _ = imageFile {
                        // à implémenter : JeuService.shared.createWithImage(...)
                    } else {
                        _ = try await JeuService.shared.create(data: newGame)
                    }
                }
                loadGames()
            } catch {
                errorMessage = "Erreur enregistrement jeu: \(error)"
            }
            showFormDialog = false
        }
    }

    // Import CSV
    func importCsv(_ data: Data) {
        Task {
            do {
                // À implémenter : importCsv(csvData: data)
                loadGames()
            } catch {
                errorMessage = "Erreur import CSV"
            }
        }
    }
}
