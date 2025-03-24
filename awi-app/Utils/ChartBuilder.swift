//
//  ChartBuilder.swift
//  awi-app
//
//  Created by etud on 23/03/2025.
//


import Foundation

struct ChartBuilder {
    static func buildCumulativeChart(from ventes: [VenteRequest]) -> [ChartDataPoint] {
        let grouped = Dictionary(grouping: ventes, by: { vente in
            let date = ISO8601DateFormatter().date(from: vente.date_vente ?? "") ?? Date()
            return Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: date),
                                         minute: Calendar.current.component(.minute, from: date),
                                         second: 0,
                                         of: date) ?? date
        })

        let sortedKeys = grouped.keys.sorted()
        var cumulative: Double = 0
        return sortedKeys.map { date in
            let total = grouped[date]?.compactMap { Double($0.montant_total ?? -1) }.reduce(0, +) ?? 0
            cumulative += total
            let label = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
            return ChartDataPoint(label: label, value: cumulative)
        }
    }

    static func buildMaxChart(from ventes: [VenteRequest]) -> [ChartDataPoint] {
        let grouped = Dictionary(grouping: ventes, by: { vente in
            let date = ISO8601DateFormatter().date(from: vente.date_vente ?? "") ?? Date()
            return Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: date),
                                         minute: Calendar.current.component(.minute, from: date),
                                         second: 0,
                                         of: date) ?? date
        })

        let sortedKeys = grouped.keys.sorted()
        return sortedKeys.map { date in
            let max = grouped[date]?.compactMap { Double($0.montant_total ?? -1) }.max() ?? 0
            let label = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short)
            return ChartDataPoint(label: label, value: max)
        }
    }
}
