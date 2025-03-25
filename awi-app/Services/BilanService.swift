//
//  BilanService.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//

import Foundation

/// Service pour télécharger les bilans PDF d’une session ou d’un vendeur.
class BilanService {
    static let shared = BilanService()
    private init() {}

    /// Télécharge le PDF du bilan pour une session donnée.
    /// - Parameter sessionId: ID de la session
    /// - Returns: Données binaires du fichier PDF
    func downloadBilanSession(sessionId: Int) async throws -> Data {
        let request = try Api.shared.makeRequest(endpoint: "/api/bilan/session/\(sessionId)", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return data
    }

    /// Télécharge le bilan PDF d’un vendeur pour une session donnée.
    /// - Parameters:
    ///   - vendeurId: ID du vendeur
    ///   - sessionId: ID de la session
    func downloadBilanVendeur(vendeurId: Int, sessionId: Int) async throws -> Data {
        let request = try Api.shared.makeRequest(endpoint: "/api/bilan/vendeur/\(vendeurId)&\(sessionId)", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return data
    }
}
