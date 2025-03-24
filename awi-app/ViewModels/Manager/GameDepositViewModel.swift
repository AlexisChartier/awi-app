import SwiftUI

class GameDepositViewModel: ObservableObject {
    @Published var vendeurs: [Vendeur] = []
    @Published var sessionActive: Session?
    @Published var catalogGames: [Jeu] = []
    @Published var depositItems: [DepositItem] = []
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isLoading: Bool = false

    @Published var selectedVendeurId: Int?
    @Published var selectedGame: Jeu? = nil
    @Published var searchTerm: String = ""
    @Published var filterEditeur: String = ""

    @Published var tempPrice: Double = 0
    @Published var tempQuantity: Int = 1
    @Published var tempEtat: EtatJeu = .Neuf
    @Published var tempDetailEtat: String = ""
    @Published var tempRemise: Double = 0

    // ✅ Pagination support
    @Published var currentPage: Int = 0
    let pageSize = 8

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

    init() {
        Task {
            await fetchVendeurs()
            await fetchSessionActive()
            await fetchCatalog()
        }
    }

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
            let session = try await SessionService.shared.getSessionActive()
            self.sessionActive = session
        } catch {
            self.errorMessage = "Aucune session active trouvée."
        }
    }

    @MainActor
    func fetchCatalog() async {
        self.isLoading = true
        do {
            let data = try await JeuService.shared.getAllJeux()
            self.catalogGames = data
        } catch {
            self.errorMessage = "Erreur lors du chargement du catalogue"
        }
        self.isLoading = false
    }

    func addGameToDeposit() {
        guard let selectedGame = self.selectedGame else {
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

        var itemsToAdd: [DepositItem] = []
        for _ in 0..<tempQuantity {
            let item = DepositItem(
                jeuId: selectedGame.id!,
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

        errorMessage = nil
        tempPrice = 0
        tempQuantity = 1
        tempEtat = .Neuf
        tempDetailEtat = ""
        tempRemise = 0
        self.selectedGame = nil
    }

    func removeItem(_ item: DepositItem) {
        depositItems.removeAll { $0.id == item.id }
    }

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
                total += session.fraisDepot
            }
        }
        let totalRemise = calculateTotalRemise()
        return max(0, total - totalRemise)
    }
    
    func calculateDepositFeesAvantRemise() -> Double {
        guard let session = sessionActive else { return 0 }
        var total: Double = 0
        for item in depositItems {
            if session.modeFraisDepot == "pourcentage" {
                let frais = item.prixVente * (session.fraisDepot / 100)
                total += frais
            } else {
                total += session.fraisDepot
            }
        }
        return total
    }

    func validateDeposit() -> Bool {
        print(calculateTotalRemise())
        print(calculateTotalDepositFees())
        guard let _ = selectedVendeurId,
              let _ = sessionActive else {
            errorMessage = "Veuillez sélectionner un vendeur et une session."
            return false
        }
        guard !depositItems.isEmpty else {
            errorMessage = "Aucun jeu à déposer."
            return false
        }
        if calculateDepositFeesAvantRemise() == calculateTotalRemise(){
            return true
        }
        if calculateDepositFeesAvantRemise() < calculateTotalRemise() {
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
                    depot_jeu_id: nil,
                    vendeur_id: vendeurId,
                    session_id: session.id,
                    prix_vente: item.prixVente,
                    frais_depot: 0,
                    remise: item.remise,
                    date_depot: dateString,
                    identifiant_unique: "",
                    statut: "retiré",
                    etat: item.etat.rawValue,
                    detail_etat: item.detailEtat ?? ""
                )
            }
            try await DepotJeuService.shared.createMany(depots: depotPayload)

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

    // 🔍 Filtrage
    func filteredCatalog() -> [Jeu] {
        let sTerm = searchTerm.lowercased()
        let base = catalogGames.sorted(by: { $0.nom.localizedCompare($1.nom) == .orderedAscending })
        return base.filter { jeu in
            let matchNom = sTerm.isEmpty || jeu.nom.lowercased().contains(sTerm)
            let matchEd = filterEditeur.isEmpty || (jeu.editeur?.lowercased() == filterEditeur.lowercased())
            return matchNom && matchEd
        }
    }


    // 📦 Pagination
    func paginatedCatalog() -> [Jeu] {
        let filtered = filteredCatalog()
        let start = currentPage * pageSize
        let end = min(start + pageSize, filtered.count)
        return Array(filtered[start..<end])
    }

    var totalPages: Int {
        let total = filteredCatalog().count
        return Int(ceil(Double(total) / Double(pageSize)))
    }

    func uniqueEditeurs() -> [String] {
        let arr = catalogGames.compactMap { $0.editeur }
        return Array(Set(arr))
    }
}
