//
//  AcheteurService.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//

import Foundation

/// Service pour gérer les acheteurs (CRUD + recherche).
class AcheteurService {
    static let shared = AcheteurService()
    private init() {}

    /// Recherche un ou plusieurs acheteurs par mot-clé.
    func searchBuyer(search: String) async throws -> [Acheteur] {
        let request = try Api.shared.makeRequest(endpoint: "/api/acheteurs/search/\(search)", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct AcheteurSearchResponse: Codable {
            let acheteurs: [Acheteur]
        }

        let decoded = try JSONDecoder().decode(AcheteurSearchResponse.self, from: data)
        return decoded.acheteurs
    }

    /// Récupère tous les acheteurs
    func fetchAllAcheteurs() async throws -> [Acheteur] {
        let request = try Api.shared.makeRequest(endpoint: "/api/acheteurs", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct BuyersResponse: Codable {
            let acheteurs: [Acheteur]
        }

        let decoded = try JSONDecoder().decode(BuyersResponse.self, from: data)
        return decoded.acheteurs
    }

    /// Crée un nouvel acheteur
    func createAcheteur(_ acheteur: Acheteur) async throws -> Acheteur {
        let body = try JSONEncoder().encode(acheteur)
        let request = try Api.shared.makeRequest(endpoint: "/api/acheteurs", method: "POST", body: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }

        struct BuyerCreateResponse: Codable {
            let acheteur: Acheteur
            let message: String
        }

        let decoded = try JSONDecoder().decode(BuyerCreateResponse.self, from: data)
        return decoded.acheteur
    }

    /// Récupère un acheteur à partir de son ID
    func fetchAcheteur(id: Int) async throws -> Acheteur {
        let request = try Api.shared.makeRequest(endpoint: "/api/acheteurs/\(id)", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct AcheteurResponse: Codable {
            let acheteur: Acheteur
        }

        return try JSONDecoder().decode(AcheteurResponse.self, from: data).acheteur
    }

    /// Met à jour un acheteur existant
    func updateAcheteur(_ acheteur: Acheteur) async throws -> Acheteur {
        guard let acheteurId = acheteur.id as Int? else {
            throw URLError(.badURL)
        }

        let body = try JSONEncoder().encode(acheteur)
        let request = try Api.shared.makeRequest(endpoint: "/api/acheteurs/\(acheteurId)", method: "PUT", body: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct AcheteurUpdateResponse: Codable {
            let message: String
            let acheteur: Acheteur
        }

        return try JSONDecoder().decode(AcheteurUpdateResponse.self, from: data).acheteur
    }

    /// Supprime un acheteur
    func deleteAcheteur(id: Int) async throws {
        let request = try Api.shared.makeRequest(endpoint: "/api/acheteurs/\(id)", method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
