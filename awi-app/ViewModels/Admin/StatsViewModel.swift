//
//  StatsViewModel.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//

import Foundation
import SwiftUI
import Charts

/// Représente les statistiques principales calculées pour une session.
struct Statistics {
    let totalGamesDeposited: Int
    let totalSalesAmount: Double
    let totalCommissions: Double
    let totalDepositFees: Double
    let totalBuyers: Int
    let depotsVendus: [DepotJeuRequest]
    let maxVente: Double
}

/// Représente des statistiques complémentaires à afficher dans des cartes ou indicateurs.
struct AdditionalStats {
    var activeVendorsCount: Int = 0
    var numberOfSales: Int = 0
    var amountDueToVendors: Double = 0
    var treasuryTotal: Double = 0
    var salesRate: Double = 0
    var averageSaleValue: Double = 0
    var averageDepotValue: Double = 0
}

/// ViewModel dédié à l’affichage des statistiques dans le tableau de bord.
class StatsViewModel: ObservableObject {
    enum PieChartType { case all, sold }
    enum PieMetric { case count, value }

    @Published var sessions: [Session] = []
    @Published var selectedSessionId: Int?

    @Published var stats: Statistics?
    @Published var additionalStats = AdditionalStats()

    @Published var salesOverTimeData: [ChartDataPoint]?
    @Published var maxSaleOverTimeData: [ChartDataPoint]?

    @Published var pieChartType: PieChartType = .all
    @Published var pieMetric: PieMetric = .count

    private var allDepots: [DepotJeuRequest] = []
    private var vendors: [Vendeur] = []

    @Published var errorMessage: String?

    /// Charge les sessions disponibles et sélectionne la session active par défaut.
    func loadSessions() {
        Task {
            do {
                let all = try await SessionService.shared.getAll()
                await MainActor.run {
                    self.sessions = all
                    if self.selectedSessionId == nil {
                        self.selectedSessionId = all.first(where: { $0.statut == "active" })?.id
                    }
                }
            } catch {
                self.errorMessage = "Erreur chargement des sessions."
            }
        }
    }

    /// Charge les statistiques pour une session donnée.
    func loadStats(for sessionId: Int) {
        Task {
            do {
                // Réinitialisation UI
                await MainActor.run {
                    self.errorMessage = nil
                    self.stats = nil
                    self.additionalStats = AdditionalStats()
                    self.salesOverTimeData = nil
                    self.maxSaleOverTimeData = nil
                }

                let depots = try await DepotJeuService.shared.getDepotsSessions(sessionId: sessionId)
                self.allDepots = depots

                self.vendors = try await VendeurService.shared.fetchAllVendeurs()
                let depotsVendus = depots.filter { $0.statut == "vendu" }

                let totalGamesDeposited = depots.count
                let totalFrais = depots.compactMap { Double($0.frais_depot) }.reduce(0, +)
                let totalRemise = depots.compactMap { Double($0.remise ?? 0) }.reduce(0, +)
                let totalDepositFees = totalFrais - totalRemise

                let ventes = try await VenteService.shared.getSalesBySession(sessionId: sessionId)
                let totalSalesAmount = ventes.map { Double($0.montant_total) }.reduce(0, +)
                let maxVente = ventes.map { Double($0.montant_total) }.max() ?? 0
                let numberOfSales = ventes.count

                var totalCommissions: Double = 0
                for vente in ventes {
                    if let id = vente.vente_id {
                        let details = try await VenteService.shared.getSalesDetails(venteId: id)
                        totalCommissions += details.map { Double($0.commission ?? 0) }.reduce(0, +)
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

                let computedStats = Statistics(
                    totalGamesDeposited: totalGamesDeposited,
                    totalSalesAmount: totalSalesAmount,
                    totalCommissions: totalCommissions,
                    totalDepositFees: totalDepositFees,
                    totalBuyers: totalBuyers,
                    depotsVendus: depotsVendus,
                    maxVente: maxVente
                )

                await MainActor.run {
                    self.stats = computedStats
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

    /// Génère les données nécessaires à l'affichage du graphique circulaire (pie chart).
    func generatePieChartData() -> [PieSliceData] {
        let relevantDepots: [DepotJeuRequest] = pieChartType == .all
            ? allDepots
            : allDepots.filter { $0.statut == "vendu" }

        let grouped = Dictionary(grouping: relevantDepots, by: { $0.vendeur_id })

        return grouped.compactMap { (vendorId, depots) in
            guard let v = vendors.first(where: { $0.id == vendorId }) else {
                return PieSliceData(label: "Inconnu", value: 0)
            }

            let label = v.nom
            let value: Double

            if pieMetric == .count {
                value = Double(depots.count)
            } else {
                value = depots.compactMap { Double($0.prix_vente) }.reduce(0, +)
            }

            return PieSliceData(label: label, value: value)
        }
    }
}
