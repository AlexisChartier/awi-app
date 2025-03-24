import SwiftUI

@MainActor
class CatalogViewModel: ObservableObject {
    @Published var jeux: [Jeu] = []
    @Published var searchTerm: String = ""
    @Published var filterEditeur: String = ""
    @Published var sortKey: SortKey? = .nom // 🔥 tri alphabétique par défaut
    @Published var sortAsc: Bool = true

    @Published var selectedGames: Set<Int> = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    // Pagination
    @Published var currentPage: Int = 0
    let itemsPerPage = 8

    // Création / Édition
    @Published var showFormDialog = false
    @Published var isEditMode = false
    @Published var currentGame: Jeu? = nil

    // Suppression individuelle
    @Published var showDeleteDialog = false
    @Published var gameToDelete: Jeu? = nil

    // CSV Import
    @Published var csvFileData: Data? = nil
    
    @Published var showDetailSheet = false
    @Published var detailGame: Jeu? = nil

    // Tri possible
    enum SortKey {
        case nom, auteur, editeur
    }

    func loadGames() {
        isLoading = true
        Task {
            do {
                let fetched = try await JeuService.shared.getAllJeux()
                self.jeux = fetched
                self.sortKey = .nom       // tri par défaut
                self.sortAsc = true
            } catch {
                self.errorMessage = "Erreur chargement catalogue: \(error)"
            }
            self.isLoading = false
        }
    }


    // Filtrage
    var filteredJeux: [Jeu] {
        // Aucun filtre → retourner tous les jeux
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


    // Tri
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
            if sortAsc {
                return strA < strB
            } else {
                return strA > strB
            }
        }
        return array
    }

    // Pagination
    var totalPages: Int {
        let c = sortedJeux.count
        return c == 0 ? 1 : Int(ceil(Double(c) / Double(itemsPerPage)))
    }

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

    // Sélection
    func toggleSelectGame(_ jeuId: Int) {
        if selectedGames.contains(jeuId) {
            selectedGames.remove(jeuId)
        } else {
            selectedGames.insert(jeuId)
        }
    }
    func deleteSelectedGames() {
        Task {
            do {
                for jeuId in selectedGames {
                    try await JeuService.shared.delete(id:jeuId)
                }
                await loadGames()
                selectedGames.removeAll()
            } catch {
                errorMessage = "Erreur suppression groupée"
            }
        }
    }

    // Individuelle
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
                try await JeuService.shared.delete(id:jid)
                await loadGames()
            } catch {
                errorMessage = "Erreur suppression jeu"
            }
            showDeleteDialog = false
        }
    }

    // Création / Édition
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
                    // Update
                    let updated = try await JeuService.shared.update(id:jid, data:newGame)
                } else {
                    // Create
                    if let fileData = imageFile {
                        // createWithImage => FormData
                        // vous devrez adapter si votre code stocke un Data ou un UIImage
                        // Cf. Swift concurrency + multipart...
                        // On simplifie l'exemple
                        //try await JeuService.shared.createWithImage(newGame, imageData: fileData)
                    } else {
                        try await JeuService.shared.create(data: newGame)
                    }
                }
                await loadGames()
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
                //try await JeuService.shared.importCsv(csvData: data, fileName: <#String#>)
                await loadGames()
            } catch {
                errorMessage = "Erreur import CSV"
            }
        }
    }
}
