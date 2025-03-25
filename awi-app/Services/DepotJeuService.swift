//
//  DepotJeuService.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//

import Foundation

// MARK: - DepotJeuRequest

/// Représente le payload envoyé ou reçu par l'API pour un dépôt de jeu.
/// Sert notamment pour les opérations de création multiple, mise à jour ou retrait.
/// Peut être fusionné avec le modèle `DepotJeu` si leur structure devient identique.
struct DepotJeuRequest: Codable {
    var jeu_id: Int
    var depot_jeu_id: Int?
    var vendeur_id: Int
    var session_id: Int
    var prix_vente: Double
    var frais_depot: Double
    var remise: Double?
    var date_depot: String                // Format ISO 8601, ex. "2025-03-15T10:00:00Z"
    var identifiant_unique: String?      // Code d’identification apposé sur le jeu
    var statut: String                   // "en vente", "vendu", "retiré"
    var etat: String                     // "Neuf" ou "Occasion"
    var detail_etat: String?             // Description complémentaire

    enum CodingKeys: String, CodingKey {
        case jeu_id
        case depot_jeu_id
        case vendeur_id
        case session_id
        case prix_vente
        case frais_depot
        case remise
        case date_depot
        case identifiant_unique
        case statut
        case etat
        case detail_etat
    }

    /// Initialisation personnalisée pour supporter les valeurs `Double` reçues sous forme de `String` dans le JSON.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.jeu_id       = try container.decode(Int.self, forKey: .jeu_id)
        self.depot_jeu_id = try? container.decode(Int.self, forKey: .depot_jeu_id)
        self.vendeur_id   = try container.decode(Int.self, forKey: .vendeur_id)
        self.session_id   = try container.decode(Int.self, forKey: .session_id)

        self.prix_vente   = try Self.decodeDouble(container: container, key: .prix_vente)
        self.frais_depot  = try Self.decodeDouble(container: container, key: .frais_depot)
        self.remise       = try? Self.decodeDouble(container: container, key: .remise)

        self.date_depot          = try container.decode(String.self, forKey: .date_depot)
        self.identifiant_unique  = try? container.decode(String.self, forKey: .identifiant_unique)
        self.statut              = try container.decode(String.self, forKey: .statut)
        self.etat                = try container.decode(String.self, forKey: .etat)
        self.detail_etat         = try? container.decode(String.self, forKey: .detail_etat)
    }

    /// Initialisation standard Swift (utilisée côté client)
    init(
        jeu_id: Int,
        depot_jeu_id: Int?,
        vendeur_id: Int,
        session_id: Int,
        prix_vente: Double,
        frais_depot: Double,
        remise: Double?,
        date_depot: String,
        identifiant_unique: String?,
        statut: String,
        etat: String,
        detail_etat: String?
    ) {
        self.jeu_id = jeu_id
        self.depot_jeu_id = depot_jeu_id
        self.vendeur_id = vendeur_id
        self.session_id = session_id
        self.prix_vente = prix_vente
        self.frais_depot = frais_depot
        self.remise = remise
        self.date_depot = date_depot
        self.identifiant_unique = identifiant_unique
        self.statut = statut
        self.etat = etat
        self.detail_etat = detail_etat
    }

    /// Permet de décoder un `Double` venant soit d’un nombre, soit d’une chaîne.
    private static func decodeDouble(container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> Double {
        if let val = try? container.decode(Double.self, forKey: key) {
            return val
        }
        let str = try container.decode(String.self, forKey: key)
        guard let converted = Double(str) else {
            throw DecodingError.dataCorruptedError(
                forKey: key,
                in: container,
                debugDescription: "Impossible de convertir '\(str)' en Double pour \(key)."
            )
        }
        return converted
    }
}

// MARK: - DepotJeuService

/// Service dédié aux opérations sur les dépôts de jeux (create, read, update).
class DepotJeuService {
    static let shared = DepotJeuService()
    private init() {}

    /// Crée plusieurs dépôts de jeux en une requête.
    func createMany(depots: [DepotJeuRequest]) async throws {
        let body = try JSONEncoder().encode(["depots": depots])
        let request = try Api.shared.makeRequest(endpoint: "/api/depots/bulk", method: "POST", body: body)
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    /// Récupère tous les dépôts associés à une session.
    func getDepotsSessions(sessionId: Int) async throws -> [DepotJeuRequest] {
        let request = try Api.shared.makeRequest(endpoint: "/api/depots/sessions/\(sessionId)", method: "GET")
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

    /// Calcule le stock pour un jeu, un vendeur et une session (optionnelle).
    func getStockByVendeurAndJeuAndSession(jeuId: Int, vendeurId: Int, sessionId: Int?) async throws -> String {
        let endpoint = "/api/depots/stock/\(jeuId)&\(vendeurId)&\(sessionId ?? 0)"
        let request = try Api.shared.makeRequest(endpoint: endpoint, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct StockResponse: Codable {
            let stock: String
        }
        return try JSONDecoder().decode(StockResponse.self, from: data).stock
    }

    /// Récupère les dépôts retirés d’un vendeur pour une session.
    func getRetiredDepotsByVendeurIdAndSessionId(vendeurId: Int, sessionId: Int) async throws -> [DepotJeuRequest] {
        let request = try Api.shared.makeRequest(endpoint: "/api/depots/retire/\(vendeurId)&\(sessionId)", method: "GET")
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

    /// Génère un identifiant unique pour un dépôt (étiquette).
    func genererIdentifiantUnique(depotId: Int) async throws -> DepotJeuRequest {
        let request = try Api.shared.makeRequest(endpoint: "/api/depots/retire/\(depotId)", method: "PUT")
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

    /// Récupère tous les dépôts d’un vendeur pour une session donnée.
    func getDepotByVendeurAndSession(vendeurId: Int, sessionId: Int) async throws -> [DepotJeuRequest] {
        let endpoint = "/api/depots/vendeur/\(vendeurId)&\(sessionId)"
        let request = try Api.shared.makeRequest(endpoint: endpoint, method: "GET")
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

    /// Met à jour le statut d’un dépôt (ex. passage à "retiré").
    func updateDepotStatut(depotId: Int) async throws {
        let request = try Api.shared.makeRequest(endpoint: "/api/depots/retire/\(depotId)", method: "PUT")
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    /// Récupère un dépôt par son identifiant unique.
    func getDepotById(depotId: Int) async throws -> DepotJeuRequest {
        let request = try Api.shared.makeRequest(endpoint: "/api/depots/\(depotId)", method: "GET")
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
