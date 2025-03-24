import Foundation
import SwiftUI
import Charts

struct Statistics {
    let totalGamesDeposited: Int
    let totalSalesAmount: Double
    let totalCommissions: Double
    let totalDepositFees: Double
    let totalBuyers: Int
    let depotsVendus: [DepotJeuRequest]
    let maxVente: Double
}

struct AdditionalStats {
    var activeVendorsCount: Int = 0
    var numberOfSales: Int = 0
    var amountDueToVendors: Double = 0
    var treasuryTotal: Double = 0
    var salesRate: Double = 0
    var averageSaleValue: Double = 0
    var averageDepotValue: Double = 0
}


class StatsViewModel: ObservableObject {
    enum PieChartType { case all, sold }
    enum PieMetric { case count, value }

    // 📊 Chargement initial
    @Published var sessions: [Session] = []
    @Published var selectedSessionId: Int?

    // 🔢 Statistiques
    @Published var stats: Statistics?
    @Published var additionalStats = AdditionalStats()

    // 📈 Données graphiques
    @Published var salesOverTimeData: [ChartDataPoint]?
    @Published var maxSaleOverTimeData: [ChartDataPoint]?
    
    // 🥧 Pie chart
    @Published var pieChartType: PieChartType = .all
    @Published var pieMetric: PieMetric = .count

    // 🧾 Tous dépôts et vendeurs
    private var allDepots: [DepotJeuRequest] = []
    private var vendors: [Vendeur] = []

    // ⚠️
    @Published var errorMessage: String?

    func loadSessions() {
        Task {
            do {
                self.sessions = try await SessionService.shared.getAll()
            } catch {
                self.errorMessage = "Erreur chargement des sessions."
            }
        }
    }

    func loadStats(for sessionId: Int) {
        Task {
            self.errorMessage = nil
            self.stats = nil
            self.additionalStats = AdditionalStats()
            self.salesOverTimeData = nil
            self.maxSaleOverTimeData = nil

            do {
                // 📦 Dépôts
                let depots = try await DepotJeuService.shared.getDepotsSessions(sessionId: sessionId)
                self.allDepots = depots

                // 🧍‍♂️ Vendeurs
                self.vendors = try await VendeurService.shared.fetchAllVendeurs()

                let depotsVendus = depots.filter { $0.statut == "vendu" }
                let totalGamesDeposited = depots.count

                // 💸 Dépôt fees
                let totalFrais = depots.compactMap { Double($0.frais_depot ?? -1) }.reduce(0, +)
                let totalRemise = depots.compactMap { Double($0.remise ?? -1) }.reduce(0, +)
                let totalDepositFees = totalFrais - totalRemise

                // 🛒 Ventes
                let ventes = try await VenteService.shared.getSalesBySession(sessionId: sessionId)
                let totalSalesAmount = ventes.map { Double($0.montant_total ?? -1) ?? 0 }.reduce(0, +)
                let maxVente = ventes.map { Double($0.montant_total ?? -1) ?? 0 }.max() ?? 0
                let numberOfSales = ventes.count

                var totalCommissions: Double = 0
                for vente in ventes {
                    if let id = vente.vente_id {
                        let details = try await VenteService.shared.getSalesDetails(venteId: id)
                        totalCommissions += details.map { Double($0.commission ?? -1) ?? 0 }.reduce(0, +)
                    }
                }

                let buyerIds = Set(ventes.compactMap { $0.acheteur_id })
                let totalBuyers = buyerIds.count
                let activeVendorCount = Set(depots.compactMap { $0.vendeur_id }).count

                let amountDueToVendors = totalSalesAmount - totalCommissions
                let treasury = totalDepositFees + totalSalesAmount
                let salesRate = totalGamesDeposited > 0 ? (Double(depotsVendus.count) / Double(totalGamesDeposited)) * 100 : 0
                let averageSaleValue = numberOfSales > 0 ? totalSalesAmount / Double(numberOfSales) : 0
                let averageDepotValue = depotsVendus.count > 0 ? totalSalesAmount / Double(depotsVendus.count) : 0

                await MainActor.run {
                    self.stats = Statistics(
                        totalGamesDeposited: totalGamesDeposited,
                        totalSalesAmount: totalSalesAmount,
                        totalCommissions: totalCommissions,
                        totalDepositFees: totalDepositFees,
                        totalBuyers: totalBuyers,
                        depotsVendus: depotsVendus,
                        maxVente: maxVente
                    )

                    self.additionalStats = AdditionalStats(
                        activeVendorsCount: activeVendorCount,
                        numberOfSales: numberOfSales,
                        amountDueToVendors: amountDueToVendors,
                        treasuryTotal: treasury,
                        salesRate: salesRate,
                        averageSaleValue: averageSaleValue,
                        averageDepotValue: averageDepotValue
                    )

                    self.salesOverTimeData = ChartBuilder.buildCumulativeChart(from: ventes)
                    self.maxSaleOverTimeData = ChartBuilder.buildMaxChart(from: ventes)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur lors du chargement des stats."
                }
            }
        }
    }

    func generatePieChartData() -> [PieSliceData] {
        let relevantDepots: [DepotJeuRequest] = pieChartType == .all
            ? allDepots
            : allDepots.filter { $0.statut == "vendu" }

        let grouped = Dictionary(grouping: relevantDepots.filter { $0.vendeur_id != nil }, by: { $0.vendeur_id })

        return grouped.compactMap { (vendorId, depots) in
            guard let v = vendors.first(where: { $0.id == vendorId }) else {
                return PieSliceData(label: "Inconnu", value: 0)
            }

            let label = v.nom

            let value: Double
            if pieMetric == .count {
                value = Double(depots.count)
            } else {
                let numericValues = depots.compactMap { depot in
                    Double(depot.prix_vente ?? -1)
                }
                value = numericValues.reduce(0, +)
            }

            return PieSliceData(label: label, value: value)
        }
    }

}
