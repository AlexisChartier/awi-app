import SwiftUI

class GameDepositViewModel: ObservableObject {
    // MARK: - Published properties

    /// Liste des vendeurs
    @Published var vendeurs: [Vendeur] = []

    /// Session active
    @Published var sessionActive: SessionAWI?

    /// Catalogue de jeux
    @Published var catalogGames: [Jeu] = []

    /// Liste de (votre) "dépot items" en cours
    @Published var depositItems: [DepositItem] = []

    /// Erreur / succès
    @Published var errorMessage: String?
    @Published var successMessage: String?

    /// Indicateurs
    @Published var isLoading: Bool = false

    // Sélections
    @Published var selectedVendeurId: Int?
    // la session est gérée par sessionActive
    @Published var selectedGame: Jeu?
    @Published var searchTerm: String = ""
    @Published var filterEditeur: String = ""

    /// Champs pour l'ajout du jeu choisi
    @Published var tempPrice: Double = 0
    @Published var tempQuantity: Int = 1
    @Published var tempEtat: EtatJeu = .Neuf
    @Published var tempDetailEtat: String = ""
    @Published var tempRemise: Double = 0

    // MARK: - Types internes
    enum EtatJeu: String {
        case Neuf, Occasion
    }

    struct DepositItem: Identifiable {
        let id = UUID()
        let jeuId: Int
        let nom: String
        var prixVente: Double
        var etat: EtatJeu
        var detailEtat: String?
        var imageURL: String?
        var remise: Double
    }

    // MARK: - Init
    init() {
        // éventuellement on charge tout de suite
        Task {
            await fetchVendeurs()
            await fetchSessionActive()
            await fetchCatalog()
        }
    }

    // MARK: - Fonctions de chargement
    @MainActor
    func fetchVendeurs() async {
        do {
            let data = try await VendeurService.shared.fetchAllVendeurs()
            self.vendeurs = data
        } catch {
            self.errorMessage = "Erreur lors du chargement des vendeurs"
        }
    }

    @MainActor
    func fetchSessionActive() async {
        do {
            // Suppose un SessionService avec une fonction getSessionActive()
            // Ajustez selon vos endpoints
            if let session = try? await SessionService.shared.getSessionActive() {
                self.sessionActive = session
            } else {
                self.errorMessage = "Aucune session active trouvée."
            }
        } catch {
            self.errorMessage = "Aucune session active trouvée."
        }
    }

    @MainActor
    func fetchCatalog() async {
        self.isLoading = true
        do {
            let data = try await JeuService.shared.getAllJeux() // Suppose que vous avez getAllJeux()
            // Si besoin d'ajuster l'URL d'image :
            // for i in 0..<data.count { if !data[i].image.starts(with: "http") { data[i].image = ... } }
            self.catalogGames = data
        } catch {
            self.errorMessage = "Erreur lors du chargement du catalogue"
        }
        self.isLoading = false
    }

    // MARK: - Ajout d'un jeu existant
    func addGameToDeposit() {
        guard let selectedGame = selectedGame else {
            errorMessage = "Aucun jeu sélectionné."
            return
        }
        guard tempQuantity >= 1 else {
            errorMessage = "Quantité invalide."
            return
        }
        guard tempPrice > 0 else {
            errorMessage = "Prix de vente invalide."
            return
        }

        // On créé X items en fonction de la quantité
        var itemsToAdd: [DepositItem] = []
        for _ in 0..<tempQuantity {
            let item = DepositItem(
                jeuId: selectedGame.id,
                nom: selectedGame.nom,
                prixVente: tempPrice,
                etat: tempEtat,
                detailEtat: tempEtat == .Occasion ? tempDetailEtat : nil,
                imageURL: selectedGame.image,
                remise: tempRemise
            )
            itemsToAdd.append(item)
        }

        depositItems.append(contentsOf: itemsToAdd)

        // Reset
        errorMessage = nil
        tempPrice = 0
        tempQuantity = 1
        tempEtat = .Neuf
        tempDetailEtat = ""
        tempRemise = 0
        selectedGame = nil
    }

    // MARK: - Suppression d'un item
    func removeItem(_ item: DepositItem) {
        depositItems.removeAll { $0.id == item.id }
    }

    // MARK: - Calcul des frais / remise
    func calculateTotalRemise() -> Double {
        depositItems.reduce(0) { $0 + $1.remise }
    }

    func calculateTotalDepositFees() -> Double {
        guard let session = sessionActive else { return 0 }
        var total: Double = 0
        for item in depositItems {
            if session.modeFraisDepot == "pourcentage" {
                let frais = item.prixVente * (session.fraisDepot / 100)
                total += frais
            } else {
                // mode fixe
                total += session.fraisDepot
            }
        }
        // On suppose qu'on doit retrancher la remise
        let totalRemise = calculateTotalRemise()
        return max(0, total - totalRemise)
    }

    // MARK: - Valider le dépôt
    func validateDeposit() -> Bool {
        guard let _ = selectedVendeurId,
              let _ = sessionActive else {
            errorMessage = "Veuillez sélectionner un vendeur et une session."
            return false
        }
        guard !depositItems.isEmpty else {
            errorMessage = "Aucun jeu à déposer."
            return false
        }
        if calculateTotalDepositFees() < calculateTotalRemise() {
            errorMessage = "La remise totale est supérieure aux frais de dépôt."
            return false
        }
        return true
    }

    func finalizeDeposit() async {
        guard let vendeurId = selectedVendeurId,
              let session = sessionActive else {
            return
        }
        do {
            let dateString = ISO8601DateFormatter().string(from: Date())
            let depotPayload: [DepotJeuRequest] = depositItems.map { item in
                DepotJeuRequest(
                    jeu_id: item.jeuId,
                    vendeur_id: vendeurId,
                    session_id: session.id,
                    prix_vente: item.prixVente,
                    frais_depot: 0, // calculé côté back si besoin, ou on met la part unitaire
                    remise: item.remise,
                    date_depot: dateString,
                    identifiant_unique: "",
                    statut: "retiré",
                    etat: item.etat.rawValue,
                    detail_etat: item.detailEtat ?? ""
                )
            }
            try await DepotJeuService.shared.createMany(depots: depotPayload)

            // Reset
            await MainActor.run {
                depositItems.removeAll()
                successMessage = "Dépôt enregistré avec succès"
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur lors de l'enregistrement du dépôt"
            }
        }
    }

    // MARK: - Filtrage du catalogue
    func filteredCatalog() -> [Jeu] {
        let sTerm = searchTerm.lowercased()
        return catalogGames.filter { jeu in
            let matchNom = jeu.nom.lowercased().contains(sTerm)
            let matchEd = filterEditeur.isEmpty ? true : (jeu.editeur?.lowercased() == filterEditeur.lowercased())
            return matchNom && matchEd
        }
    }

    func uniqueEditeurs() -> [String] {
        let arr = catalogGames.compactMap { $0.editeur }
        return Array(Set(arr))
    }
}
