import SwiftUI

@MainActor
class StatsViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var selectedSessionId: Int?
    @Published var loading = false
    @Published var errorMessage: String?

    // Indicateurs
    @Published var totalGamesDeposited: Int = 0
    @Published var totalSalesAmount: Double = 0
    @Published var totalCommissions: Double = 0
    @Published var totalDepositFees: Double = 0
    @Published var totalBuyers: Int = 0
    @Published var maxSale: Double = 0

    // Additional
    @Published var activeVendorsCount: Int = 0
    @Published var numberOfSales: Int = 0
    @Published var amountDueToVendors: Double = 0
    @Published var treasuryTotal: Double = 0
    @Published var salesRate: Double = 0
    @Published var averageSaleValue: Double = 0
    @Published var averageDepotValue: Double = 0

    // Graph data
    @Published var salesOverTime: [SomePoint] = []  // un struct interne
    @Published var maxSaleOverTime: [SomePoint] = []
    // etc.
    
    struct SomePoint {
      let label: String
      let value: Double
    }

    // pour le camembert par vendeur
    @Published var allDepots: [DepotJeu] = []
    @Published var vendors: [Vendeur] = []
    
    // etc.

    func loadSessions() {
        Task {
            do {
                let allS = try await SessionService.shared.getAll()
                self.sessions = allS
            } catch {
                errorMessage = "Erreur chargement sessions"
            }
        }
    }

    func loadStats() {
        guard let sid = selectedSessionId else { return }
        loading = true
        Task {
            do {
                // On récupère tous les depots =>
                // On calcule totalGamesDeposited, depotsVendus, etc.
                // On récupère ventes => totalSalesAmount, etc.
                // Cf. logic from adminStats
                // ...
            } catch {
                errorMessage = "Erreur stats"
            }
            loading = false
        }
    }
}
