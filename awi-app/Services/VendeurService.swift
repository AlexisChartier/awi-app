//
//  VendeurService.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//

import Foundation

/// Service chargé de la gestion des vendeurs : liste, création, mise à jour, suppression.
class VendeurService {
    static let shared = VendeurService()
    private init() {}

    /// Récupère tous les vendeurs.
    func fetchAllVendeurs() async throws -> [Vendeur] {
        let request = try Api.shared.makeRequest(endpoint: "/api/vendeurs", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct VendeursResponse: Codable {
            let vendeurs: [Vendeur]
        }

        return try JSONDecoder().decode(VendeursResponse.self, from: data).vendeurs
    }

    /// Crée un nouveau vendeur.
    func createVendeur(_ vendeur: Vendeur) async throws -> Vendeur {
        let body = try JSONEncoder().encode(vendeur)
        let request = try Api.shared.makeRequest(endpoint: "/api/vendeurs", method: "POST", body: body)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }

        struct CreateVendeurResponse: Codable {
            let message: String
            let vendeur: Vendeur
        }

        return try JSONDecoder().decode(CreateVendeurResponse.self, from: data).vendeur
    }

    /// Récupère un vendeur par son identifiant.
    func fetchVendeur(id: Int) async throws -> Vendeur {
        let request = try Api.shared.makeRequest(endpoint: "/api/vendeurs/\(id)", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(Vendeur.self, from: data)
    }

    /// Met à jour les informations d’un vendeur existant.
    func updateVendeur(_ vendeur: Vendeur) async throws -> Vendeur {
        guard let vendeurId = vendeur.id else {
            throw URLError(.badURL)
        }

        let body = try JSONEncoder().encode(vendeur)
        let request = try Api.shared.makeRequest(endpoint: "/api/vendeurs/\(vendeurId)", method: "PUT", body: body)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct VendeurUpdateResponse: Codable {
            let message: String
            let vendeur: Vendeur
        }

        return try JSONDecoder().decode(VendeurUpdateResponse.self, from: data).vendeur
    }

    /// Supprime un vendeur.
    func deleteVendeur(id: Int) async throws {
        let request = try Api.shared.makeRequest(endpoint: "/api/vendeurs/\(id)", method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
