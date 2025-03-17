//
//  DepotJeuRequest.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//


import Foundation

/// Représente le payload pour createMany, etc. 
/// (vous pouvez le fusionner avec DepotJeu si c’est identique)
struct DepotJeuRequest: Codable {
    var jeu_id: Int
    var depot_jeu_id: Int?
    var vendeur_id: Int
    var session_id: Int
    var prix_vente: Double
    var frais_depot: Double
    var remise: Double?
    var date_depot: String  // "2023-07-18T13:45:00Z" par ex.
    var identifiant_unique: String?
    var statut: String      // "en vente" | "vendu" | "retiré"
    var etat: String        // "Neuf" | "Occasion"
    var detail_etat: String?
}

class DepotJeuService {
    static let shared = DepotJeuService()
    private init() {}

    /// POST /depots/bulk
    /// Crée plusieurs DepotJeu d'un coup
    func createMany(depots: [DepotJeuRequest]) async throws {
        let body = try JSONEncoder().encode(["depots": depots])
        let request = try Api.shared.makeRequest(endpoint: "depots/bulk", method: "POST", body: body)
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
        // Pas de retour particulier, on suppose un 200 ou 201
    }

    /// GET /depots/sessions/{id}
    /// Retourne un objet { depots: DepotJeuRequest[] }
    func getDepotsSessions(sessionId: Int) async throws -> [DepotJeuRequest] {
        let request = try Api.shared.makeRequest(endpoint: "depots/sessions/\(sessionId)", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Le backend renvoie { depots: [...] }
        struct DepotResponse: Codable {
            let depots: [DepotJeuRequest]
        }
        let res = try JSONDecoder().decode(DepotResponse.self, from: data)
        return res.depots
    }

    /// GET /depots/stock/{jeu_id}&{vendeur_id}&{session_id?}
    /// Retourne { stock: string }
    func getStockByVendeurAndJeuAndSession(jeuId: Int, vendeurId: Int, sessionId: Int?) async throws -> String {
        let endpoint = "depots/stock/\(jeuId)&\(vendeurId)&\(sessionId ?? 0)" 
        // ou gérez un optional autrement
        let request = try Api.shared.makeRequest(endpoint: endpoint, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct StockResponse: Codable {
            let stock: String
        }
        let res = try JSONDecoder().decode(StockResponse.self, from: data)
        return res.stock
    }

    /// GET /depots/retire/{vendeur_id}&{session_id}
    /// Renvoie { depots: DepotJeuRequest[] }
    func getRetiredDepotsByVendeurIdAndSessionId(vendeurId: Int, sessionId: Int) async throws -> [DepotJeuRequest] {
        let request = try Api.shared.makeRequest(endpoint: "depots/retire/\(vendeurId)&\(sessionId)")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        struct DepotResponse: Codable {
            let depots: [DepotJeuRequest]
        }
        return try JSONDecoder().decode(DepotResponse.self, from: data).depots
    }

    /// PUT /depots/retire/{id} => renvoie { depot: DepotJeuRequest }
    func genererIdentifiantUnique(depotId: Int) async throws -> DepotJeuRequest {
        let request = try Api.shared.makeRequest(endpoint: "depots/retire/\(depotId)", method: "PUT")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        struct DepotResponse: Codable {
            let depot: DepotJeuRequest
        }
        return try JSONDecoder().decode(DepotResponse.self, from: data).depot
    }

    /// GET /depots/vendeur/{vendeur_id}&{session_id}
    /// => { depots: DepotJeuRequest[] }
    func getDepotByVendeurAndSession(vendeurId: Int, sessionId: Int) async throws -> [DepotJeuRequest] {
        let endpoint = "depots/vendeur/\(vendeurId)&\(sessionId)"
        let request = try Api.shared.makeRequest(endpoint: endpoint)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        struct DepotResponse: Codable {
            let depots: [DepotJeuRequest]
        }
        return try JSONDecoder().decode(DepotResponse.self, from: data).depots
    }

    /// PUT /depots/{id} => on y passe { statut }
    func updateDepotStatut(depotId: Int, statut: String) async throws {
        let body = try JSONEncoder().encode(["statut": statut])
        let request = try Api.shared.makeRequest(endpoint: "depots/\(depotId)", method: "PUT", body: body)
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    /// GET /depots/{id} => { depot: DepotJeuRequest }
    func getDepotById(depotId: Int) async throws -> DepotJeuRequest {
        let request = try Api.shared.makeRequest(endpoint: "depots/\(depotId)", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        struct DepotResponse: Codable {
            let depot: DepotJeuRequest
        }
        return try JSONDecoder().decode(DepotResponse.self, from: data).depot
    }
}
