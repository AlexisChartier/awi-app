import SwiftUI

@MainActor
class SaleViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var selectedSessionId: Int?
    @Published var sales: [VenteRequest] = []
    @Published var errorMessage: String?
    @Published var loading = false

    // tri
    enum SortField { case date, montant }
    @Published var sortField: SortField = .date
    @Published var sortAsc: Bool = true

    // pagination
    let perPage = 10
    @Published var currentPage = 1

    // detail
    @Published var showDetailModal = false
    @Published var selectedSale: VenteRequest?
    @Published var saleDetails: [VenteJeuRequest] = []
    @Published var allGames: [Jeu] = []

    // acheteur
    @Published var buyer: Acheteur?

    func loadInitial() {
        Task {
            do {
                let allS = try await SessionService.shared.getAll()
                self.sessions = allS
                self.allGames = try await JeuService.shared.getAllJeux()
                
                // 🔥 Sélectionner la session active automatiquement
                if let activeSession = allS.first(where: { $0.statut == "active" }) {
                    self.selectedSessionId = activeSession.id
                    self.loadSales()
                }

            } catch {
                errorMessage = "Erreur chargement sessions"
            }
        }
    }

    
    func gameForDepotId(_ depotId: Int?) -> Jeu? {
        guard let depotId = depotId else { return nil }
        // Tu peux ajuster selon comment relier dépôt → jeu
        return allGames.first(where: { $0.id == depotId })
    }

    func loadSales() {
        guard let sid = selectedSessionId else {
            self.sales = []
            return
        }
        loading = true
        Task {
            do {
                let s = try await VenteService.shared.getSalesBySession(sessionId: sid)
                self.sales = s
                self.currentPage = 1
                applySort()
            } catch {
                errorMessage = "Erreur chargement ventes"
                print(error)
            }
            loading = false
        }
    }

    func applySort() {
        switch sortField {
        case .date:
            sales.sort {
                let d1 = $0.date_vente ?? ""
                let d2 = $1.date_vente ?? ""
                if sortAsc {
                    return d1 < d2
                } else {
                    return d1 > d2
                }
            }
        case .montant:
            sales.sort {
                let m1 = $0.montant_total
                let m2 = $1.montant_total
                if sortAsc {
                    return m1 < m2
                } else {
                    return m1 > m2
                }
            }
        }
    }

    var filteredSales: [VenteRequest] {
        // on pourrait filtrer par acheteur...
        return sales
    }

    var totalPages: Int {
        let count = filteredSales.count
        return count == 0 ? 1 : Int(ceil(Double(count) / Double(perPage)))
    }

    var currentSales: [VenteRequest] {
        let idxLast = currentPage * perPage
        let idxFirst = idxLast - perPage
        guard idxFirst < filteredSales.count else { return [] }
        let slice = filteredSales[idxFirst..<min(idxLast, filteredSales.count)]
        return Array(slice)
    }

    func goToPage(_ page: Int) {
        guard page >= 1 && page <= totalPages else { return }
        currentPage = page
    }

    func sortBy(_ field: SortField) {
        if sortField == field {
            sortAsc.toggle()
        } else {
            sortField = field
            sortAsc = true
        }
        applySort()
    }

    // modal detail
    func openSaleDetail(_ sale: VenteRequest) {
        selectedSale = sale
        showDetailModal = true

        // charger details
        Task {
            do {
                let vid = sale.vente_id
                    let detail = try await VenteService.shared.getSalesDetails(venteId: vid!)
                    self.saleDetails = detail
                if let aid = sale.acheteur_id {
                        self.buyer = try await AcheteurService.shared.fetchAcheteur(id: aid)
                    } else {
                        self.buyer = nil
                    }
                
            } catch {
                errorMessage = "Erreur chargement details"
                print(error)
            }
        }
    }

    func closeDetailModal() {
        showDetailModal = false
        selectedSale = nil
        saleDetails = []
        buyer = nil
    }
}
