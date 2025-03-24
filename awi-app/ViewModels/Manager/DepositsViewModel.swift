//
//  DepositsViewModel.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//


import SwiftUI

class DepositsViewModel: ObservableObject {
    @Published var depots: [DepotJeuRequest] = []
    @Published var loading: Bool = false
    @Published var errorMessage: String?

    func loadDepotsForSession(_ sessionId: Int) {
        loading = true
        Task {
            do {
                let fetched = try await DepotJeuService.shared.getDepotsSessions(sessionId: sessionId)
                await MainActor.run {
                    self.depots = fetched
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur chargement depots: \(error)"
                    self.loading = false
                }
            }
        }
    }

    func createManyDepots(_ depotsToCreate: [DepotJeuRequest]) {
        loading = true
        Task {
            do {
                try await DepotJeuService.shared.createMany(depots: depotsToCreate)
                // Recharger la liste si besoin
                await MainActor.run {
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur creation multiple depots: \(error)"
                    self.loading = false
                }
            }
        }
    }
}
