//
//  UserService.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//

import Foundation

/// Gère les utilisateurs : création, mise à jour, suppression, listing.
class UserService {
    static let shared = UserService()
    private init() {}

    /// Récupère tous les utilisateurs.
    func fetchAllUsers() async throws -> [Utilisateur] {
        let request = try Api.shared.makeRequest(endpoint: "/api/utilisateurs", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct UsersResponse: Codable {
            let utilisateurs: [Utilisateur]
        }

        return try JSONDecoder().decode(UsersResponse.self, from: data).utilisateurs
    }

    /// Crée un nouvel utilisateur.
    func createUser(_ data: Utilisateur) async throws -> Utilisateur {
        let body = try JSONEncoder().encode(data)
        let request = try Api.shared.makeRequest(endpoint: "/api/utilisateurs", method: "POST", body: body)

        let (resData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        struct CreateUserResponse: Codable {
            let message: String
            let utilisateur: CreatedUser
        }

        struct CreatedUser: Codable {
            let utilisateur_id: Int
            let nom: String
            let email: String
            let role: String
        }

        let decoded = try JSONDecoder().decode(CreateUserResponse.self, from: resData)
        let u = Utilisateur(
            id: decoded.utilisateur.utilisateur_id,
            nom: decoded.utilisateur.nom,
            email: decoded.utilisateur.email,
            role: UserRole(rawValue: decoded.utilisateur.role) ?? .manager
        )
        return u
    }

    /// Met à jour les infos d’un utilisateur.
    func updateUser(id: Int, data: Utilisateur) async throws -> Utilisateur {
        var bodyDict: [String: Any] = [
            "nom": data.nom,
            "email": data.email,
            "telephone": data.telephone ?? "",
            "login": data.login ?? "",
            "role": data.role.rawValue
        ]

        if let mdp = data.motDePasse, !mdp.isEmpty {
            bodyDict["mot_de_passe"] = mdp
        }

        let body = try JSONSerialization.data(withJSONObject: bodyDict, options: [])

        let request = try Api.shared.makeRequest(endpoint: "/api/utilisateurs/\(id)", method: "PUT", body: body)
        let (resData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct UpdateUserResponse: Codable {
            let message: String
            let utilisateur: UpdatedUser
        }

        struct UpdatedUser: Codable {
            let utilisateur_id: Int
            let nom: String
            let email: String
            let role: String
        }

        let decoded = try JSONDecoder().decode(UpdateUserResponse.self, from: resData)
        return Utilisateur(
            id: decoded.utilisateur.utilisateur_id,
            nom: decoded.utilisateur.nom,
            email: decoded.utilisateur.email,
            role: UserRole(rawValue: decoded.utilisateur.role) ?? .manager
        )
    }

    /// Supprime un utilisateur.
    func deleteUser(id: Int) async throws {
        let request = try Api.shared.makeRequest(endpoint: "/api/utilisateurs/\(id)", method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
