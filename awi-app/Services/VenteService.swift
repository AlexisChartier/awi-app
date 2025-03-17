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
}

struct VenteJeuRequest: Codable {
    var vente_id: Int?
    var depot_jeu_id: Int?
    var prix_vente: Double?
    var commission: Double?
    // autres champs si nécessaire
}

class VenteService {
    static let shared = VenteService()
    private init() {}

    /// POST /ventes => renvoie { vente_id: number, ... }
    func createVente(venteData: VenteRequest) async throws -> Int {
        let body = try JSONEncoder().encode(venteData)
        let request = try Api.shared.makeRequest(endpoint: "ventes", method: "POST", body: body)
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
        let request = try Api.shared.makeRequest(endpoint: "ventes-jeux", method: "POST", body: body)

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

        let request = try Api.shared.makeRequest(endpoint: "ventes/finalize", method: "POST", body: body)
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
        let request = try Api.shared.makeRequest(endpoint: "ventes/invoice/\(venteId)", method: "POST")
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    /// GET /ventes/sessions/{session_id} => { ventes: [...] }
    func getSalesBySession(sessionId: Int) async throws -> [VenteRequest] {
        let request = try Api.shared.makeRequest(endpoint: "ventes/sessions/\(sessionId)", method: "GET")
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

    /// GET /ventes/details/{vente_id} => { venteJeux: [...] }
    func getSalesDetails(venteId: Int) async throws -> [VenteJeuRequest] {
        let request = try Api.shared.makeRequest(endpoint: "ventes/details/\(venteId)", method: "GET")
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
        let request = try Api.shared.makeRequest(endpoint: "ventes/addBuyer/\(venteId)&\(acheteurId)", method: "PUT")
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
