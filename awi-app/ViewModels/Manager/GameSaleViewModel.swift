import SwiftUI

@MainActor
class GameSaleViewModel: ObservableObject {
    @Published var sessionActive: SessionAWI?
    @Published var depotsEnVente: [DepotJeu] = []
    @Published var allGames: [Jeu] = []
    @Published var allVendors: [Vendeur] = []

    @Published var cart: [DepotJeu] = []
    @Published var commissionRate: Double = 0

    @Published var filterVendorId: Int?
    @Published var filterGameName: String = ""
    @Published var filterEtat: String = ""
    @Published var filterBarcode: String = ""
    // Tri par prix asc/desc
    @Published var priceSort: Bool? = nil   // nil => pas de tri, true => asc, false => desc

    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var loading = false

    // Buyer dialog
    @Published var showBuyerDialog = false
    @Published var needInvoice = false
    // buyer selection
    @Published var selectedBuyerId: Int?
    // etc.

    func loadData() {
        loading = true
        Task {
            do {
                let sActive = try? await SessionService.shared.getSessionActive()
                self.sessionActive = sActive
                if let sess = sActive {
                    self.commissionRate = sess.commissionRate
                    let depots = try await DepotJeuService.shared.getDepotsSessions(sess.id)
                    self.depotsEnVente = depots.filter { $0.statut == "en vente" }
                }
                let games = try await GameService.shared.getAll()
                self.allGames = games
                let vend = try await VendeurService.shared.fetchAllVendeurs()
                self.allVendors = vend
            } catch {
                self.errorMessage = "Erreur chargement data"
            }
            self.loading = false
        }
    }

    var filteredDepots: [DepotJeu] {
        depotsEnVente.filter { d in
            if let vid = filterVendorId, vid != d.vendeur_id { return false }
            if !filterGameName.isEmpty {
                // check gameName
                guard let game = allGames.first(where: {$0.id == d.jeu_id}) else { return false }
                if !game.nom.lowercased().contains(filterGameName.lowercased()) { return false }
            }
            if !filterBarcode.isEmpty {
                if !(d.identifiant_unique?.contains(filterBarcode) ?? false) { return false }
            }
            if filterEtat == "Neuf" && d.etat != "Neuf" { return false }
            if filterEtat == "Occasion" && d.etat != "Occasion" { return false }
            return true
        }
    }

    var sortedDepots: [DepotJeu] {
        guard let p = priceSort else { return filteredDepots }
        return filteredDepots.sorted {
            if p {
                return $0.prix_vente < $1.prix_vente
            } else {
                return $0.prix_vente > $1.prix_vente
            }
        }
    }

    func addToCart(_ depot: DepotJeu) {
        cart.append(depot)
        depotsEnVente.removeAll { $0.id == depot.id }
    }

    func removeFromCart(_ depot: DepotJeu) {
        cart.removeAll { $0.id == depot.id }
        depotsEnVente.append(depot)
    }

    var totalSalePrice: Double {
        cart.reduce(0) { $0 + $1.prix_vente }
    }

    func generateBarcode(_ depot: DepotJeu) {
        Task {
            do {
                let updated = try await DepotJeuService.shared.genererIdentifiantUnique(depot.id!)
                // Màj dans depotsEnVente
                if let idx = depotsEnVente.firstIndex(where: { $0.id == depot.id }) {
                    depotsEnVente[idx] = updated
                }
            } catch {
                errorMessage = "Erreur génération identifiant"
            }
        }
    }

    func finalizeSale() {
        if cart.isEmpty {
            errorMessage = "Panier vide"
            return
        }
        showBuyerDialog = true
    }

    // ensuite, buyer stuff + confirmSale => SaleService
    func confirmSale() {
        guard let sess = sessionActive else {
            errorMessage = "Pas de session active"
            return
        }
        Task {
            do {
                let vente = Vente(
                    // acheteur_id => needInvoice ? selectedBuyerId : nil
                    acheteur_id: needInvoice ? selectedBuyerId : nil,
                    montant_total: totalSalePrice,
                    session_id: sess.id
                )
                // On suppose qu’on a un struct “VenteJeuRequest”
                let details = cart.map { d in
                    VenteJeuRequest(
                        depot_jeu_id: d.id,
                        prix_vente: d.prix_vente,
                        commission: d.prix_vente * (commissionRate / 100.0)
                    )
                }
                let final = try await SaleService.shared.finalizeSale(venteData: vente, venteJeuxData: details)
                successMessage = "Vente #\(final.id ?? -1) enregistrée!"
                cart.removeAll()
                showBuyerDialog = false
            } catch {
                errorMessage = "Erreur finalisation vente"
            }
        }
    }
}
