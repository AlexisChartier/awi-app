//
//  ChartBuilder.swift
//  awi-app
//
//  Created by etud on 23/03/2025.
//

import Foundation

/// Utilitaire de génération de données pour les graphiques à partir des ventes.
/// Fournit des courbes cumulatives ou des courbes de valeur maximale par intervalle horaire.
struct ChartBuilder {
    
    /// Construit une courbe cumulée des montants de vente par créneau horaire.
    /// - Parameter ventes: Liste des ventes (`VenteRequest`)
    /// - Returns: Liste de points de données pour affichage sur un graphique
    static func buildCumulativeChart(from ventes: [VenteRequest]) -> [ChartDataPoint] {
        // Grouper les ventes par heure arrondie (ex : 14h30 => 14h30:00)
        let grouped = Dictionary(grouping: ventes, by: { vente in
            let date = ISO8601DateFormatter().date(from: vente.date_vente ?? "") ?? Date()
            return Calendar.current.date(
                bySettingHour: Calendar.current.component(.hour, from: date),
                minute: Calendar.current.component(.minute, from: date),
                second: 0,
                of: date
            ) ?? date
        })

        let sortedKeys = grouped.keys.sorted() // Tri chronologique

        var cumulative: Double = 0

        // Calcul cumulatif pour chaque point de temps
        return sortedKeys.map { date in
            let total = grouped[date]?.compactMap { Double($0.montant_total) }.reduce(0, +) ?? 0
            cumulative += total

            let label = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)

            return ChartDataPoint(label: label, value: cumulative)
        }
    }

    /// Construit une courbe représentant le montant de vente maximal par créneau horaire.
    /// - Parameter ventes: Liste des ventes (`VenteRequest`)
    /// - Returns: Liste de points de données avec les valeurs maximales
    static func buildMaxChart(from ventes: [VenteRequest]) -> [ChartDataPoint] {
        // Grouper les ventes par heure arrondie (ex : 15h00:00)
        let grouped = Dictionary(grouping: ventes, by: { vente in
            let date = ISO8601DateFormatter().date(from: vente.date_vente ?? "") ?? Date()
            return Calendar.current.date(
                bySettingHour: Calendar.current.component(.hour, from: date),
                minute: Calendar.current.component(.minute, from: date),
                second: 0,
                of: date
            ) ?? date
        })

        let sortedKeys = grouped.keys.sorted() // Tri croissant

        // Calcul du maximum par groupe horaire
        return sortedKeys.map { date in
            let max = grouped[date]?.compactMap { Double($0.montant_total) }.max() ?? 0
            let label = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
            return ChartDataPoint(label: label, value: max)
        }
    }
}
