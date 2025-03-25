//
//  VenteRequest.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//

import Foundation

/// Représente les données nécessaires pour créer ou manipuler une vente.
/// Utilisé côté client pour les appels POST/PUT vers `/ventes` ou `/ventes/finalize`.
struct VenteRequest: Codable {
    /// Identifiant de la vente (optionnel lors de la création)
    var vente_id: Int?

    /// Identifiant de l'acheteur (optionnel au moment de la création)
    var acheteur_id: Int?

    /// Date de la vente (au format ISO 8601, ex. "2025-03-19T10:00:00Z")
    var date_vente: String?

    /// Montant total de la vente (peut être reçu en String ou Double)
    var montant_total: Double

    /// Identifiant de la session liée à la vente
    var session_id: Int

    enum CodingKeys: String, CodingKey {
        case vente_id
        case acheteur_id
        case date_vente
        case montant_total
        case session_id
    }

    /// Initialisation personnalisée pour prendre en compte `montant_total` envoyé en String ou Double.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.vente_id     = try? container.decode(Int.self, forKey: .vente_id)
        self.acheteur_id  = try? container.decode(Int.self, forKey: .acheteur_id)
        self.date_vente   = try? container.decode(String.self, forKey: .date_vente)
        self.session_id   = try container.decode(Int.self, forKey: .session_id)

        // Essaye Double direct, sinon tente de convertir depuis une chaîne
        if let d = try? container.decode(Double.self, forKey: .montant_total) {
            self.montant_total = d
        } else {
            let str = try container.decode(String.self, forKey: .montant_total)
            guard let converted = Double(str) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .montant_total,
                    in: container,
                    debugDescription: "Impossible de convertir '\(str)' en Double pour montant_total"
                )
            }
            self.montant_total = converted
        }
    }

    /// Initialisation Swift classique (côté client).
    init(
        vente_id: Int?,
        acheteur_id: Int?,
        date_vente: String?,
        montant_total: Double,
        session_id: Int
    ) {
        self.vente_id = vente_id
        self.acheteur_id = acheteur_id
        self.date_vente = date_vente
        self.montant_total = montant_total
        self.session_id = session_id
    }
}

/// Représente une ligne de vente associée à un jeu.
/// Utilisé lors de la finalisation d’une vente (POST `/ventes-jeux`, `/ventes/finalize`...).
struct VenteJeuRequest: Codable {
    /// Identifiant de la vente à laquelle cette ligne appartient
    var vente_id: Int?

    /// Identifiant du dépôt de jeu vendu
    var depot_jeu_id: Int?

    /// Prix de vente effectif (peut être reçu en String ou Double)
    var prix_vente: Double?

    /// Commission appliquée sur cette vente (peut être String ou Double)
    var commission: Double?

    enum CodingKeys: String, CodingKey {
        case vente_id
        case depot_jeu_id
        case prix_vente
        case commission
    }

    /// Décodage personnalisé pour prendre en compte les champs numériques en String.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.vente_id = try? container.decodeIfPresent(Int.self, forKey: .vente_id)
        self.depot_jeu_id = try? container.decodeIfPresent(Int.self, forKey: .depot_jeu_id)

        // prix_vente : Double ou String
        if let prixDouble = try? container.decodeIfPresent(Double.self, forKey: .prix_vente) {
            self.prix_vente = prixDouble
        } else if let prixString = try? container.decodeIfPresent(String.self, forKey: .prix_vente),
                  let prix = Double(prixString) {
            self.prix_vente = prix
        }

        // commission : Double ou String
        if let comDouble = try? container.decodeIfPresent(Double.self, forKey: .commission) {
            self.commission = comDouble
        } else if let comString = try? container.decodeIfPresent(String.self, forKey: .commission),
                  let com = Double(comString) {
            self.commission = com
        }
    }

    /// Encodage standard (utilisé pour envoyer les données au backend).
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(vente_id, forKey: .vente_id)
        try container.encodeIfPresent(depot_jeu_id, forKey: .depot_jeu_id)
        try container.encodeIfPresent(prix_vente, forKey: .prix_vente)
        try container.encodeIfPresent(commission, forKey: .commission)
    }

    /// Initialisation classique côté Swift.
    init(
        vente_id: Int?,
        depot_jeu_id: Int?,
        prix_vente: Double?,
        commission: Double?
    ) {
        self.vente_id = vente_id
        self.depot_jeu_id = depot_jeu_id
        self.prix_vente = prix_vente
        self.commission = commission
    }
}


/// Service gérant la création, finalisation et récupération des ventes.
class VenteService {
    static let shared = VenteService()
    private init() {}

    /// Crée une nouvelle vente.
    /// - Returns: ID de la vente créée
    func createVente(venteData: VenteRequest) async throws -> Int {
        let body = try JSONEncoder().encode(venteData)
        let request = try Api.shared.makeRequest(endpoint: "/api/ventes", method: "POST", body: body)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        struct CreateVenteResponse: Codable {
            let vente_id: Int
        }

        return try JSONDecoder().decode(CreateVenteResponse.self, from: data).vente_id
    }

    /// Crée les lignes associées à une vente (VenteJeu).
    func createVenteJeux(_ venteJeuxData: [VenteJeuRequest]) async throws {
        let body = try JSONEncoder().encode(venteJeuxData)
        let request = try Api.shared.makeRequest(endpoint: "/api/ventes-jeux", method: "POST", body: body)
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    /// Finalise une vente avec ses lignes de vente.
    func finalizeSale(venteData: VenteRequest, venteJeuxData: [VenteJeuRequest]) async throws -> VenteRequest {
        struct FinalizeBody: Codable {
            let venteData: VenteRequest
            let venteJeuxData: [VenteJeuRequest]
        }

        let body = try JSONEncoder().encode(FinalizeBody(venteData: venteData, venteJeuxData: venteJeuxData))
        let request = try Api.shared.makeRequest(endpoint: "/api/ventes/finalize", method: "POST", body: body)
        let (resData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        struct FinalizeResponse: Codable {
            let vente: VenteRequest
        }

        return try JSONDecoder().decode(FinalizeResponse.self, from: resData).vente
    }

    /// Envoie une facture au client.
    func sendInvoice(venteId: Int) async throws {
        let request = try Api.shared.makeRequest(endpoint: "/api/ventes/invoice/\(venteId)", method: "POST")
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    /// Récupère toutes les ventes d’une session.
    func getSalesBySession(sessionId: Int) async throws -> [VenteRequest] {
        let request = try Api.shared.makeRequest(endpoint: "/api/ventes/sessions/\(sessionId)", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct SalesResponse: Codable {
            let ventes: [VenteRequest]
        }

        return try JSONDecoder().decode(SalesResponse.self, from: data).ventes
    }

    /// Récupère les détails (lignes de jeux) d’une vente.
    func getSalesDetails(venteId: Int) async throws -> [VenteJeuRequest] {
        let request = try Api.shared.makeRequest(endpoint: "/api/ventes/details/\(venteId)", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct DetailsResponse: Codable {
            let venteJeux: [VenteJeuRequest]
        }

        return try JSONDecoder().decode(DetailsResponse.self, from: data).venteJeux
    }

    /// Associe un acheteur à une vente existante.
    func setAcheteur(venteId: Int, acheteurId: Int) async throws -> VenteRequest {
        let request = try Api.shared.makeRequest(endpoint: "/api/ventes/addBuyer/\(venteId)&\(acheteurId)", method: "PUT")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct UpdateBuyerResponse: Codable {
            let vente: VenteRequest
        }

        return try JSONDecoder().decode(UpdateBuyerResponse.self, from: data).vente
    }
}
