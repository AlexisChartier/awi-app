//
//  GameSaleViewModel.swift
//  awi-app
//
//  Created by etud on 19/03/2025.
//


import SwiftUI

@MainActor
class GameSaleViewModel: ObservableObject {
    @Published var sessionActive: Session?
    @Published var depotsEnVente: [DepotJeuRequest] = []
    @Published var allGames: [Jeu] = []
    @Published var allVendors: [Vendeur] = []

    @Published var cart: [DepotJeuRequest] = []
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
                    let depots = try await DepotJeuService.shared.getDepotsSessions(sessionId: sess.id)
                    self.depotsEnVente = depots.filter { $0.statut == "en vente" }
                }
                let games = try await JeuService.shared.getAllJeux()
                self.allGames = games
                let vend = try await VendeurService.shared.fetchAllVendeurs()
                self.allVendors = vend
            } catch {
                self.errorMessage = "Erreur chargement data"
                print(error)
            }
            self.loading = false
        }
    }

    var filteredDepots: [DepotJeuRequest] {
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

    var sortedDepots: [DepotJeuRequest] {
        guard let p = priceSort else { return filteredDepots }
        return filteredDepots.sorted {
            if p {
                return $0.prix_vente < $1.prix_vente
            } else {
                return $0.prix_vente > $1.prix_vente
            }
        }
    }

    func addToCart(_ depot: DepotJeuRequest) {
        cart.append(depot)
        depotsEnVente.removeAll { $0.depot_jeu_id == depot.depot_jeu_id }
    }

    func removeFromCart(_ depot: DepotJeuRequest) {
        cart.removeAll { $0.depot_jeu_id == depot.depot_jeu_id }
        depotsEnVente.append(depot)
    }

    var totalSalePrice: Double {
        cart.reduce(0.0) { acc, depot in
            acc + (Double(depot.prix_vente))
        }
    }


    func generateBarcode(_ depot: DepotJeuRequest) {
        Task {
            do {
                let updated = try await DepotJeuService.shared.genererIdentifiantUnique(depotId: depot.depot_jeu_id!)
                // Màj dans depotsEnVente
                if let idx = depotsEnVente.firstIndex(where: { $0.depot_jeu_id == depot.depot_jeu_id }) {
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
    func searchBuyer(email: String) async -> [Acheteur] {
        do {
            return try await AcheteurService.shared.searchBuyer(search: email)
        } catch {
            self.errorMessage = "Erreur lors de la recherche acheteur"
            print(error)
            return []
        }
    }

    func createBuyer(nom: String, email: String, tel: String, adresse: String) async -> Int? {
        do {
            let a = Acheteur(id: 0, nom: nom, email: email, telephone: tel, adresse: adresse)
            let created = try await AcheteurService.shared.createAcheteur(a)
            return created.id
        } catch {
            self.errorMessage = "Erreur lors de la création acheteur"
            return nil
        }
    }

    // ensuite, buyer stuff + confirmSale => SaleService
    func confirmSale() {
        guard let sess = sessionActive else {
            errorMessage = "Pas de session active"
            return
        }
        print(selectedBuyerId ?? -1)

        Task {
            do {
                let montantTotal = cart.reduce(0.0) { acc, depot in
                    acc + (Double(depot.prix_vente))
                }

                let isoFormatter = ISO8601DateFormatter()
                // isoFormatter.timeZone = TimeZone.current // ou .utc, selon votre besoin
                let dateString = isoFormatter.string(from: Date())
                let venteRequest = VenteRequest(
                    vente_id: nil,
                    acheteur_id: needInvoice ? selectedBuyerId : nil,
                    date_vente:dateString,
                    montant_total: montantTotal,
                    session_id: sess.id
                )

                let venteJeuxDetails: [VenteJeuRequest] = cart.map {
                    let prix = Double($0.prix_vente)
                    return VenteJeuRequest(
                        vente_id: nil,
                        depot_jeu_id: $0.depot_jeu_id,
                        prix_vente: prix,
                        commission: prix * (commissionRate / 100.0)
                    )
                }

                let final = try await VenteService.shared.finalizeSale(venteData: venteRequest, venteJeuxData: venteJeuxDetails)

                successMessage = "Vente #\(final.vente_id ?? -1) enregistrée!"
                cart.removeAll()
                showBuyerDialog = false
            } catch {
                print("Erreur confirmSale: \(error)")
                errorMessage = "Erreur lors de l'enregistrement de la vente."
            }
        }
    }

}
