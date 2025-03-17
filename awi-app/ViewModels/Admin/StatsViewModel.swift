//
//  StatsData.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//


import SwiftUI

struct StatsData {
    let totalVentes: Int
    let totalCA: Double
    // etc.
}

class StatsViewModel: ObservableObject {
    @Published var stats: StatsData? = nil
    @Published var loading: Bool = false
    @Published var errorMessage: String?

    func loadStats() {
        loading = true
        Task {
            do {
                // Suppose un StatsService
                // let result = try await StatsService.shared.fetchStats()
                // self.stats = StatsData(totalVentes: result.totalVentes, totalCA: result.ca)
                await MainActor.run {
                    self.stats = StatsData(totalVentes: 100, totalCA: 1234.56)  // Stub
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur chargement stats"
                    self.loading = false
                }
            }
        }
    }
}
