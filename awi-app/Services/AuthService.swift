//
//  AuthService.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//


import Foundation

struct LoginCredentials: Codable {
    let login: String
    let mot_de_passe: String
}

struct AuthResponse: Codable {
    let token: String
    let utilisateur: Utilisateur
}

class AuthService {
    static let shared = AuthService()

    private init() {}

    /// Exemple d'authentification
    /// POST /auth/login
        /// Retourne { token, utilisateur }
        func login(credentials: LoginCredentials) async throws -> AuthResponse {
            // On encode les identifiants
            let body = try JSONEncoder().encode(credentials)
            
            // Construire la requête
            let request = try Api.shared.makeRequest(
                endpoint: "/api/auth/login",
                method: "POST",
                body: body
            )
            
            // Envoyer la requête
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Vérifier le code HTTP
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                // On peut lever une erreur plus précise si besoin
                throw URLError(.badServerResponse)
            }
            
            // Décoder la réponse JSON
            let authResp = try JSONDecoder().decode(AuthResponse.self, from: data)
            
            // Stocker le token dans Api.shared
            Api.shared.authToken = authResp.token
            
            return authResp
        }

    func logout() {
        // Pour un simple JWT, on peut juste effacer le token localement
        Api.shared.authToken = nil
    }

    /// Vérifie si le token est encore valide (GET /auth/check)
        /// Retourne true si OK, false si le back-end renvoie une erreur
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
    
    
    /// Exemple de vérification (facultative)
    func isAuthenticated() -> Bool {
        return Api.shared.authToken != nil
    }
}
