import Foundation

class SessionService {
    static let shared = SessionService()
    private init() {}

    /// Récupérer toutes les sessions
    func fetchAllSessions() async throws -> [SessionAWI] {
        let request = try Api.shared.makeRequest(endpoint: "api/sessions", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([SessionAWI].self, from: data)
    }

    /// Récupérer une session par id
    func fetchSession(id: Int) async throws -> SessionAWI {
        let request = try Api.shared.makeRequest(endpoint: "api/sessions/\(id)", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(SessionAWI].self, from: data)
    }

    /// Créer une session
    func createSession(_ session: SessionAWI) async throws -> SessionAWI {
        let body = try JSONEncoder().encode(session)
        let request = try Api.shared.makeRequest(endpoint: "api/sessions", method: "POST", body: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(SessionAWI.self, from: data)
    }

    /// Mettre à jour une session
    func updateSession(_ session: SessionAWI) async throws -> SessionAWI {
        guard let sessionId = session.id as Int? else {
            throw URLError(.badURL)
        }
        let body = try JSONEncoder().encode(session)
        let request = try Api.shared.makeRequest(
            endpoint: "api/sessions/\(sessionId)",
            method: "PUT",
            body: body
        )
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(SessionAWI.self, from: data)
    }

    /// Supprimer une session
    func deleteSession(id: Int) async throws {
        let request = try Api.shared.makeRequest(endpoint: "api/sessions/\(id)", method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
