//
//  AuthService.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//

import Foundation

/// Représente les identifiants d’un utilisateur pour se connecter.
struct LoginCredentials: Codable {
    let login: String
    let mot_de_passe: String
}

/// Réponse du backend après authentification.
struct AuthResponse: Codable {
    let token: String
    let utilisateur: Utilisateur
}

/// Gère l’authentification de l’utilisateur (login, logout, vérification token).
class AuthService {
    static let shared = AuthService()
    private init() {}

    /// Effectue une tentative de connexion.
    /// - Parameter credentials: Identifiants de connexion
    /// - Returns: Réponse contenant le token et les infos utilisateur
    func login(credentials: LoginCredentials) async throws -> AuthResponse {
        let body = try JSONEncoder().encode(credentials)
        let request = try Api.shared.makeRequest(endpoint: "/api/auth/login", method: "POST", body: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let authResp = try JSONDecoder().decode(AuthResponse.self, from: data)

        // Enregistre le token JWT
        Api.shared.authToken = authResp.token

        return authResp
    }

    /// Déconnecte l'utilisateur localement (efface le token)
    func logout() {
        Api.shared.authToken = nil
    }

    /// Vérifie que le token stocké est encore valide
    /// - Returns: Booléen indiquant si la session est encore active
    func checkToken() async -> Bool {
        guard Api.shared.authToken != nil else {
            return false
        }

        do {
            let request = try Api.shared.makeRequest(endpoint: "/api/auth/check", method: "GET")
            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }

            return true
        } catch {
            return false
        }
    }

    /// Vérifie simplement si un token JWT est enregistré localement
    func isAuthenticated() -> Bool {
        return Api.shared.authToken != nil
    }
}
