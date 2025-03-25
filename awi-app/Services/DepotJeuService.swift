//
//  DepotJeuService.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//
import Foundation

// MARK: - DepotJeuRequest
/// Représente le payload (createMany, etc.).
/// Possibilité de fusionner avec votre struct "DepotJeu" si c’est identique.
struct DepotJeuRequest: Codable {
    var jeu_id: Int
    var depot_jeu_id: Int?
    var vendeur_id: Int
    var session_id: Int

    var prix_vente: Double
    var frais_depot: Double
    var remise: Double?

    var date_depot: String // ex: "2025-03-15T10:00:00Z"
    var identifiant_unique: String?
    var statut: String      // "en vente", "vendu", "retiré"
    var etat: String        // "Neuf" ou "Occasion"
    var detail_etat: String?

    // On liste les clés attendues
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

    // MARK: - Custom init(from:) pour supporter "String ou Double"
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.jeu_id       = try container.decode(Int.self, forKey: .jeu_id)
        self.depot_jeu_id = try? container.decode(Int.self, forKey: .depot_jeu_id)
        self.vendeur_id   = try container.decode(Int.self, forKey: .vendeur_id)
        self.session_id   = try container.decode(Int.self, forKey: .session_id)

        self.prix_vente   = try Self.decodeDouble(container: container, key: .prix_vente)
        self.frais_depot  = try Self.decodeDouble(container: container, key: .frais_depot)

        // remise est optionnelle
        if container.contains(.remise) {
            self.remise = try? Self.decodeDouble(container: container, key: .remise)
        } else {
            self.remise = nil
        }

        self.date_depot = try container.decode(String.self, forKey: .date_depot)
        self.identifiant_unique = try? container.decode(String.self, forKey: .identifiant_unique)
        self.statut = try container.decode(String.self, forKey: .statut)
        self.etat   = try container.decode(String.self, forKey: .etat)
        self.detail_etat = try? container.decode(String.self, forKey: .detail_etat)
    }

    // init normal pour usage Swift
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

    // MARK: - Décode Double ou String->Double
    private static func decodeDouble(container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> Double {
        // Tenter Double direct
        if let val = try? container.decode(Double.self, forKey: key) {
            return val
        }
        // Sinon, essayer String
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
class DepotJeuService {
    static let shared = DepotJeuService()
    private init() {}

    /// POST /depots/bulk
    /// Crée plusieurs DepotJeu d'un coup
    func createMany(depots: [DepotJeuRequest]) async throws {
        // On met depots dans un dictionnaire { "depots": [...] }
        let body = try JSONEncoder().encode(["depots": depots])
        let request = try Api.shared.makeRequest(endpoint: "/api/depots/bulk", method: "POST", body: body)
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
    }

    /// GET /depots/sessions/{id} => { depots: [DepotJeuRequest] }
    func getDepotsSessions(sessionId: Int) async throws -> [DepotJeuRequest] {
        let request = try Api.shared.makeRequest(endpoint: "/api/depots/sessions/\(sessionId)", method: "GET")
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
        let res = try JSONDecoder().decode(StockResponse.self, from: data)
        return res.stock
    }

    /// GET /depots/retire/{vendeur_id}&{session_id}
    /// => { depots: [...] }
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

    /// PUT /depots/retire/{id} => renvoie { depot: DepotJeuRequest }
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

    /// GET /depots/vendeur/{vendeur_id}&{session_id} => { depots: [...] }
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

    /// PUT /depots/{id} => on y passe { statut }
    func updateDepotStatut(depotId: Int) async throws {
        let request = try Api.shared.makeRequest(endpoint: "/api/depots/retire/\(depotId)", method: "PUT")
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    /// GET /depots/{id} => { depot: DepotJeuRequest }
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
