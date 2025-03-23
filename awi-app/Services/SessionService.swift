import Foundation

class SessionService {
    static let shared = SessionService()
    private init() {}

    /// Liste toutes les sessions
    func getAll() async throws -> [Session] {
        // GET /sessions => { sessions: [ { session_id, ... }, ... ] }
        let request = try Api.shared.makeRequest(endpoint: "/api/sessions", method: "GET")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct SessionsResponse: Codable {
            let sessions: [Session]
        }

        let decoded = try JSONDecoder().decode(SessionsResponse.self, from: data)
        return decoded.sessions
    }

    /// Créer une nouvelle session
    func create(data: Session) async throws -> Session {
        // POST /sessions => { session: {...} }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(data)
        //let body = try JSONEncoder().encode(data)
        let request = try Api.shared.makeRequest(endpoint: "/api/sessions", method: "POST", body: body)

        let (resData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct CreateSessionResponse: Codable {
            let session: Session
        }

        let decoded = try JSONDecoder().decode(CreateSessionResponse.self, from: resData)
        return decoded.session
    }

    /// Mettre à jour une session existante
    func update(sessionId: Int, data: Session) async throws -> Session {
        // PUT /sessions/:id => { session: {...} }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(data)
        //let body = try JSONEncoder().encode(data)
        let request = try Api.shared.makeRequest(endpoint: "/api/sessions/\(sessionId)", method: "PUT", body: body)

        let (resData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct UpdateSessionResponse: Codable {
            let session: Session
        }
        let decoded = try JSONDecoder().decode(UpdateSessionResponse.self, from: resData)
        return decoded.session
    }

    /// Supprimer une session
    func remove(sessionId: Int) async throws {
        // DELETE /sessions/:id
        let request = try Api.shared.makeRequest(endpoint: "/api/sessions/\(sessionId)", method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        // Pas de JSON renvoyé
    }

    /// Liste des sessions actives
    func getActiveSessions() async throws -> [Session] {
        // GET /sessions/actives => { sessions: [...] }
        let request = try Api.shared.makeRequest(endpoint: "/api/sessions/actives", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct ActiveSessionsResponse: Codable {
            let sessions: [Session]
        }
        let decoded = try JSONDecoder().decode(ActiveSessionsResponse.self, from: data)
        return decoded.sessions
    }

    /// Obtenir la session active unique
    func getSessionActive() async throws -> Session {
        // GET /sessions/active => { session: {...} }
        let request = try Api.shared.makeRequest(endpoint: "/api/sessions/active", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        print(httpResponse)
        print(String(data: data, encoding: .utf8)!)
        struct OneSessionResponse: Codable {
            let session: Session
        }
        let decoded = try JSONDecoder().decode(OneSessionResponse.self, from: data)
        return decoded.session
    }
}
