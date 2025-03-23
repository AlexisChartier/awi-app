//
//  VenteRequest.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//

import Foundation

struct VenteRequest: Codable {
    var vente_id: Int?
    var acheteur_id: Int?
    var date_vente: String?
    var montant_total: Double
    var session_id: Int

    enum CodingKeys: String, CodingKey {
        case vente_id
        case acheteur_id
        case date_vente
        case montant_total
        case session_id
    }

    // init custom pour décoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.vente_id     = try? container.decode(Int.self, forKey: .vente_id)
        self.acheteur_id  = try? container.decode(Int.self, forKey: .acheteur_id)
        self.date_vente   = try? container.decode(String.self, forKey: .date_vente)
        self.session_id   = try container.decode(Int.self, forKey: .session_id)

        // Tenter Double direct
        if let d = try? container.decode(Double.self, forKey: .montant_total) {
            self.montant_total = d
        } else {
            // Sinon, tenter String puis convertir
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

    // init pour usage Swift
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


struct VenteJeuRequest: Codable {
    var vente_id: Int?
    var depot_jeu_id: Int?
    var prix_vente: Double?
    var commission: Double?
    
    enum CodingKeys: String, CodingKey {
        case vente_id
        case depot_jeu_id
        case prix_vente
        case commission
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        vente_id = try? container.decodeIfPresent(Int.self, forKey: .vente_id)
        depot_jeu_id = try? container.decodeIfPresent(Int.self, forKey: .depot_jeu_id)

        // 🔄 Decode `Double` from String OR Number
        if let prixDouble = try? container.decodeIfPresent(Double.self, forKey: .prix_vente) {
            prix_vente = prixDouble
        } else if let prixString = try? container.decodeIfPresent(String.self, forKey: .prix_vente),
                  let prix = Double(prixString) {
            prix_vente = prix
        }

        if let comDouble = try? container.decodeIfPresent(Double.self, forKey: .commission) {
            commission = comDouble
        } else if let comString = try? container.decodeIfPresent(String.self, forKey: .commission),
                  let com = Double(comString) {
            commission = com
        }
    }

    // 🔁 Encode normalement
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(vente_id, forKey: .vente_id)
        try container.encodeIfPresent(depot_jeu_id, forKey: .depot_jeu_id)
        try container.encodeIfPresent(prix_vente, forKey: .prix_vente)
        try container.encodeIfPresent(commission, forKey: .commission)
    }
    
    init(
        vente_id: Int?,
        depot_jeu_id: Int?,
        prix_vente: Double?,
        commission: Double?) {
        self.vente_id = vente_id
            self.depot_jeu_id = depot_jeu_id
            self.prix_vente = prix_vente
            self.commission = commission
    }
    }



class VenteService {
    static let shared = VenteService()
    private init() {}

    /// POST /ventes => renvoie { vente_id: number, ... }
    func createVente(venteData: VenteRequest) async throws -> Int {
        let body = try JSONEncoder().encode(venteData)
        let request = try Api.shared.makeRequest(endpoint: "/api/ventes", method: "POST", body: body)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }

        // Suppose que le back renvoie { vente_id: x }
        struct CreateVenteResponse: Codable {
            let vente_id: Int
            // potentiellement d’autres champs
        }
        let res = try JSONDecoder().decode(CreateVenteResponse.self, from: data)
        return res.vente_id
    }

    /// POST /ventes-jeux => création multiple
    func createVenteJeux(_ venteJeuxData: [VenteJeuRequest]) async throws {
        let body = try JSONEncoder().encode(venteJeuxData)
        let request = try Api.shared.makeRequest(endpoint: "/api/ventes-jeux", method: "POST", body: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    /// POST /ventes/finalize => renvoie { vente: {...} }
    func finalizeSale(venteData: VenteRequest, venteJeuxData: [VenteJeuRequest]) async throws -> VenteRequest {
        struct FinalizeBody: Codable {
            let venteData: VenteRequest
            let venteJeuxData: [VenteJeuRequest]
        }
        let body = try JSONEncoder().encode(FinalizeBody(venteData: venteData, venteJeuxData: venteJeuxData))

        let request = try Api.shared.makeRequest(endpoint: "/api/ventes/finalize", method: "POST", body: body)
        let (resData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }

        // Suppose { vente: VenteRequest }
        struct FinalizeResponse: Codable {
            let vente: VenteRequest
        }
        let res = try JSONDecoder().decode(FinalizeResponse.self, from: resData)
        return res.vente
    }

    /// POST /ventes/invoice/{venteId}
    func sendInvoice(venteId: Int) async throws {
        let request = try Api.shared.makeRequest(endpoint: "/api/ventes/invoice/\(venteId)", method: "POST")
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    /// GET /ventes/sessions/{session_id} => { ventes: [...] }
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
        print(httpResponse)
        let decoded = try JSONDecoder().decode(SalesResponse.self, from: data)
        print(decoded.ventes)
        return decoded.ventes
    }

    /// GET /ventes/details/{vente_id} => { venteJeux: [...] }
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

    /// PUT /ventes/addBuyer/{vente_id}&{acheteur_id} => { vente: {...} }
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
