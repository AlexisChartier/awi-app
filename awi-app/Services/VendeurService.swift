//
//  VendeurService.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//


import Foundation

class VendeurService {
    static let shared = VendeurService()
    private init() {}

    /// Récupérer la liste de tous les vendeurs
    func fetchAllVendeurs() async throws -> [Vendeur] {
        let request = try Api.shared.makeRequest(endpoint: "/api/vendeurs", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Définir une struct locale qui correspond au JSON renvoyé
        struct VendeursResponse: Codable {
            let vendeurs: [Vendeur]
        }

        let decoded = try JSONDecoder().decode(VendeursResponse.self, from: data)
        return decoded.vendeurs
    }


    /// Créer un nouveau vendeur
    func createVendeur(_ vendeur: Vendeur) async throws -> Vendeur {
        // Encodage JSON
        let body = try JSONEncoder().encode(vendeur)
        
        let request = try Api.shared.makeRequest(
            endpoint: "/api/vendeurs",
            method: "POST",
            body: body
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
        
        struct CreateVendeurResponse: Codable{
            let message: String
            let vendeur: Vendeur
        }
    
        
        // Le back-end renvoie le vendeur créé (avec son id)
        let decoded = try JSONDecoder().decode(CreateVendeurResponse.self, from: data)
        return decoded.vendeur
    }

    /// Récupérer un vendeur par son id
    func fetchVendeur(id: Int) async throws -> Vendeur {
        let request = try Api.shared.makeRequest(endpoint: "/api/vendeurs/\(id)", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(Vendeur.self, from: data)
    }

    /// Mettre à jour un vendeur existant
    func updateVendeur(_ vendeur: Vendeur) async throws -> Vendeur {
        guard let vendeurId = vendeur.id as Int? else {
            throw URLError(.badURL)
        }
        
        let body = try JSONEncoder().encode(vendeur)
        
        let request = try Api.shared.makeRequest(
            endpoint: "/api/vendeurs/\(vendeurId)",
            method: "PUT",
            body: body
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(Vendeur.self, from: data)
    }

    /// Supprimer un vendeur
    func deleteVendeur(id: Int) async throws {
        let request = try Api.shared.makeRequest(endpoint: "/api/vendeurs/\(id)", method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        // Pas de valeur de retour particulière
    }
}
