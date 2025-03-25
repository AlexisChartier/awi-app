//
//  SessionService.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//

import Foundation

/// Gère toutes les opérations liées aux sessions (création, mise à jour, suppression...).
class SessionService {
    static let shared = SessionService()
    private init() {}

    /// Récupère toutes les sessions (actives et inactives).
    func getAll() async throws -> [Session] {
        let request = try Api.shared.makeRequest(endpoint: "/api/sessions", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct SessionsResponse: Codable {
            let sessions: [Session]
        }

        return try JSONDecoder().decode(SessionsResponse.self, from: data).sessions
    }

    /// Crée une nouvelle session.
    func create(data: Session) async throws -> Session {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(data)

        let request = try Api.shared.makeRequest(endpoint: "/api/sessions", method: "POST", body: body)
        let (resData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        struct CreateSessionResponse: Codable {
            let session: Session
        }

        return try JSONDecoder().decode(CreateSessionResponse.self, from: resData).session
    }

    /// Met à jour une session existante.
    func update(sessionId: Int, data: Session) async throws -> Session {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let body = try encoder.encode(data)

        let request = try Api.shared.makeRequest(endpoint: "/api/sessions/\(sessionId)", method: "PUT", body: body)
        let (resData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct UpdateSessionResponse: Codable {
            let session: Session
        }

        return try JSONDecoder().decode(UpdateSessionResponse.self, from: resData).session
    }

    /// Supprime une session.
    func remove(sessionId: Int) async throws {
        let request = try Api.shared.makeRequest(endpoint: "/api/sessions/\(sessionId)", method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    /// Récupère toutes les sessions actives.
    func getActiveSessions() async throws -> [Session] {
        let request = try Api.shared.makeRequest(endpoint: "/api/sessions/actives", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct ActiveSessionsResponse: Codable {
            let sessions: [Session]
        }

        return try JSONDecoder().decode(ActiveSessionsResponse.self, from: data).sessions
    }

    /// Récupère la session active unique.
    func getSessionActive() async throws -> Session {
        let request = try Api.shared.makeRequest(endpoint: "/api/sessions/active", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct OneSessionResponse: Codable {
            let session: Session
        }

        return try JSONDecoder().decode(OneSessionResponse.self, from: data).session
    }
}
