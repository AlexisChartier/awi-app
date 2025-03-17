import Foundation

class AcheteurService {
    static let shared = AcheteurService()
    private init() {}

    /// Liste des acheteurs
    func fetchAllAcheteurs() async throws -> [Acheteur] {
        let request = try Api.shared.makeRequest(endpoint: "api/acheteurs", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([Acheteur].self, from: data)
    }

    /// Création d’un acheteur
    func createAcheteur(_ acheteur: Acheteur) async throws -> Acheteur {
        let body = try JSONEncoder().encode(acheteur)
        let request = try Api.shared.makeRequest(
            endpoint: "api/acheteurs",
            method: "POST",
            body: body
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(Acheteur.self, from: data)
    }

    /// Récupération par ID
    func fetchAcheteur(id: Int) async throws -> Acheteur {
        let request = try Api.shared.makeRequest(endpoint: "api/acheteurs/\(id)", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(Acheteur.self, from: data)
    }

    /// Mise à jour
    func updateAcheteur(_ acheteur: Acheteur) async throws -> Acheteur {
        guard let acheteurId = acheteur.id as Int? else {
            throw URLError(.badURL)
        }
        let body = try JSONEncoder().encode(acheteur)
        let request = try Api.shared.makeRequest(
            endpoint: "api/acheteurs/\(acheteurId)",
            method: "PUT",
            body: body
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(Acheteur.self, from: data)
    }

    /// Suppression
    func deleteAcheteur(id: Int) async throws {
        let request = try Api.shared.makeRequest(endpoint: "api/acheteurs/\(id)", method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        // Pas de réponse JSON particulière
    }
}
