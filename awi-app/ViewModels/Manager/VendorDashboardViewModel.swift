//
//  VendorDashboardViewModel.swift
//  awi-app
//
//  Created by etud on 19/03/2025.
//

import SwiftUI

/// Structure de stats calculées
struct VendorDashboardStats {
    let totalDepotsEnVente: Int
    let totalDepotsVendus: Int
    let totalDepotsRetires: Int
    let totalVentes: Int
    let montantTotalVentes: Double
    let fraisDepotPayes: Double
    let commissionsDeduites: Double
    let gainsNets: Double
    let solde: Double
}

/// Une structure pour un "depot" + "vente"
struct DepotAvecVente: Identifiable {
    var id = UUID()

    var depot: DepotJeuRequest
    var identifiantUnique: String?
    var vente: VenteRequest?
    var venteJeu: VenteJeuRequest?
}

/// Le ViewModel
@MainActor
class VendorDashboardViewModel: ObservableObject {
    // MARK: - Published State
    @Published var errorMessage: String?
    @Published var loading = false

    @Published var tabIndex: Int = 0  // 0: en vente, 1: vendus, 2: retirés, 3: stats

    // Données globales
    @Published var games: [Jeu] = []
    @Published var sessions: [Session] = []
    @Published var vendeurs: [Vendeur] = []

    // Session active
    @Published var sessionActive: Session?

    // Dépôts catégorisés
    @Published var depotsEnVente: [DepotAvecVente] = []
    @Published var depotsVendus: [DepotAvecVente] = []
    @Published var depotsRetires: [DepotAvecVente] = []

    // Stats
    @Published var stats = VendorDashboardStats(
        totalDepotsEnVente: 0,
        totalDepotsVendus: 0,
        totalDepotsRetires: 0,
        totalVentes: 0,
        montantTotalVentes: 0,
        fraisDepotPayes: 0,
        commissionsDeduites: 0,
        gainsNets: 0,
        solde: 0
    )

    // Le vendeur concerné
    let vendor: Vendeur

    // MARK: - Init
    init(vendor: Vendeur) {
        self.vendor = vendor
    }

    // MARK: - Chargement initial
    func loadData() {
        loading = true
        Task {
            do {
                // Chargement en parallèle
                async let g = JeuService.shared.getAllJeux()
                async let v = VendeurService.shared.fetchAllVendeurs()
                async let s = SessionService.shared.getAll()

                let (gamesFetched, vendorsFetched, sessionsFetched) = try await (g, v, s)

                self.games = gamesFetched
                self.vendeurs = vendorsFetched
                self.sessions = sessionsFetched

                // Charger la session active et les dépôts
                await fetchSessionActive(vendorId: vendor.id!)
            } catch {
                self.errorMessage = "Erreur lors du chargement initial."
            }
            // Quelle que soit l’issue, on quitte le “loading” ici
            self.loading = false
        }
    }

    // MARK: - Charger la session active + dépôts
    func fetchSessionActive(vendorId: Int) async {
        do {
            guard let activeSession = try? await SessionService.shared.getSessionActive() else {
                self.errorMessage = "Aucune session active trouvée."
                return
            }
            self.sessionActive = activeSession

            // Récupération des dépôts du vendeur pour la session active
            let depots = try await DepotJeuService.shared.getDepotByVendeurAndSession(
                vendeurId: vendorId,
                sessionId: activeSession.id
            )

            // Séparer par statut
            let enVenteRaw = depots.filter { $0.statut == "en vente" }
            let retiresRaw = depots.filter { $0.statut == "retiré" }

            // Convertir en [DepotAvecVente]
            let enVente: [DepotAvecVente] = enVenteRaw.map { d in
                DepotAvecVente(depot: d,
                               identifiantUnique: d.identifiant_unique,
                               vente: nil,
                               venteJeu: nil)
            }
            let retires: [DepotAvecVente] = retiresRaw.map { d in
                DepotAvecVente(depot: d,
                               identifiantUnique: d.identifiant_unique,
                               vente: nil,
                               venteJeu: nil)
            }

            // Récupération des ventes pour la session active
            let ventes = try await VenteService.shared.getSalesBySession(sessionId: activeSession.id)
            var vendus: [DepotAvecVente] = []

            for vente in ventes {
                // Charger details
                if let venteId = vente.vente_id {
                    let details = try await VenteService.shared.getSalesDetails(venteId: venteId)
                    for detail in details {
                        // Trouver le depot correspondant
                        if let depot = depots.first(where: { $0.depot_jeu_id == detail.depot_jeu_id }) {
                            let dv = DepotAvecVente(
                                depot: depot,
                                identifiantUnique: depot.identifiant_unique,
                                vente: vente,
                                venteJeu: detail
                            )
                            vendus.append(dv)
                        }
                    }
                }
            }

            self.depotsEnVente = enVente
            self.depotsRetires = retires
            self.depotsVendus = vendus

            // Calculer stats
            computeStats()
        } catch {
            self.errorMessage = "Erreur lors du chargement de la session active ou des dépôts."
            print(error)
        }
    }

    // MARK: - Calcul des stats
    func computeStats() {
        let enVenteCount = depotsEnVente.count
        let vendusCount  = depotsVendus.count
        let retiresCount = depotsRetires.count

        let totalVentes  = vendusCount

        // Somme des prix_vente
        let montantTotalVentes = depotsVendus.reduce(into: 0.0) { acc, dv in
            acc += (dv.venteJeu?.prix_vente ?? dv.depot.prix_vente)
        }

        // Calcul frais / remise
        var totalRemise = 0.0
        var totalFrais  = 0.0
        for d in (depotsEnVente + depotsVendus + depotsRetires) {
            totalRemise += d.depot.remise ?? 0
            totalFrais  += d.depot.frais_depot
        }
        let fraisPayes = totalFrais - totalRemise

        // Commissions
        var totalCommissions = 0.0
        for d in depotsVendus {
            totalCommissions += d.venteJeu?.commission ?? 0
        }

        let gainsNets = montantTotalVentes - (fraisPayes + totalCommissions)
        let solde     = montantTotalVentes - totalCommissions

        self.stats = VendorDashboardStats(
            totalDepotsEnVente: enVenteCount,
            totalDepotsVendus: vendusCount,
            totalDepotsRetires: retiresCount,
            totalVentes: totalVentes,
            montantTotalVentes: montantTotalVentes,
            fraisDepotPayes: fraisPayes,
            commissionsDeduites: totalCommissions,
            gainsNets: gainsNets,
            solde: solde
        )
    }

    // MARK: - Changer d'onglet
    func setTab(index: Int) {
        tabIndex = index
    }

    // MARK: - Générer l'identifiant unique
    func genererIdentifiant(_ depot: DepotJeuRequest) {
        Task {
            do {
                let updated = try await DepotJeuService.shared.genererIdentifiantUnique(depotId: depot.depot_jeu_id!)
                // Mettre à jour la liste enVente
                if let idx = depotsEnVente.firstIndex(where: { $0.depot.depot_jeu_id == depot.depot_jeu_id! }) {
                    var copy = depotsEnVente[idx]
                    copy.identifiantUnique = updated.identifiant_unique
                    copy.depot = updated
                    depotsEnVente[idx] = copy
                }
                // Recalculer les stats
                computeStats()
            } catch {
                self.errorMessage = "Erreur lors de la génération de l'identifiant."
            }
        }
    }

    // MARK: - Changer statut (retirer, remettre en vente)
    func setDepotStatut(_ depot: DepotJeuRequest, newStatut: String) {
        Task {
            do {
                try await DepotJeuService.shared.updateDepotStatut(depotId: depot.depot_jeu_id!, statut: newStatut)
                // Re-fetch
                if let _ = sessionActive?.id {
                    await fetchSessionActive(vendorId: vendor.id!)
                }
            } catch {
                self.errorMessage = "Erreur lors du changement de statut."
            }
        }
    }

    // MARK: - Helpers
    func getGameName(jeuId: Int?) -> String {
        guard let jId = jeuId else { return "-" }
        return games.first(where: { $0.id == jId })?.nom ?? "Jeu #\(jId)"
    }

    func getGameImage(jeuId: Int?) -> String {
        guard let jId = jeuId else { return "https://via.placeholder.com/70" }
        return games.first(where: { $0.id == jId })?.image ?? "https://via.placeholder.com/70"
    }

    func getVendorName(vendeurId: Int?) -> String {
        guard let vId = vendeurId else { return "-" }
        return vendeurs.first(where: { $0.id == vId })?.nom ?? "Vendeur #\(vId)"
    }
}
