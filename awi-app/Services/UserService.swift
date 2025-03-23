//
//  UserService.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//


import Foundation

class UserService {
    static let shared = UserService()
    private init() {}

    /// Récupérer tous les utilisateurs
    func fetchAllUsers() async throws -> [Utilisateur] {
        // GET /utilisateurs
        let request = try Api.shared.makeRequest(endpoint: "/api/utilisateurs", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Si le back renvoie { utilisateurs: [...] }
        struct UsersResponse: Codable {
            let utilisateurs: [Utilisateur]
        }

        let decoded = try JSONDecoder().decode(UsersResponse.self, from: data)
        // Si au contraire le back renvoie directement un tableau,
        // remplacez par:
        // let decoded = try JSONDecoder().decode([Utilisateur].self, from: data)
        // return decoded
        return decoded.utilisateurs
    }

    /// Créer un nouvel utilisateur
    func createUser(_ data: Utilisateur) async throws -> Utilisateur {
        let body = try JSONEncoder().encode(data)
        let request = try Api.shared.makeRequest(
            endpoint: "/api/utilisateurs",
            method: "POST",
            body: body
        )

        let (resData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if !(200...299).contains(httpResponse.statusCode) {
            // Essayons de décoder un JSON d’erreur
            if let errorJSON = try? JSONSerialization.jsonObject(with: resData) as? [String: Any],
               let errorMessage = errorJSON["message"] as? String {
                // Par exemple on lance une erreur Swift plus explicite
                print(errorMessage)
                print(httpResponse)
            } else {
                // Sinon on lève juste l’erreur standard
                throw URLError(.badServerResponse)
            }
        }
        print("test")
        print(httpResponse)
        // Le back renvoie:
        // {
        //   "message": "Utilisateur créé avec succès.",
        //   "utilisateur": { ... }
        // }
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
        let newUser = decoded.utilisateur
        let u = Utilisateur(id: newUser.utilisateur_id, nom: newUser.nom, email: newUser.email, role: UserRole(rawValue: newUser.role) ?? UserRole.manager)
        return u
    }


    /// Mettre à jour un utilisateur
    func updateUser(id: Int, data: Utilisateur) async throws -> Utilisateur {
        // PUT /utilisateurs/:id
        let body = try JSONEncoder().encode(data)
        let request = try Api.shared.makeRequest(endpoint: "/api/utilisateurs/\(id)", method: "PUT", body: body)

        let (resData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Si le back renvoie { utilisateur: {...} }
        struct UpdateUserResponse: Codable {
            let utilisateur: Utilisateur
        }
        let decoded = try JSONDecoder().decode(UpdateUserResponse.self, from: resData)
        return decoded.utilisateur
    }

    /// Supprimer un utilisateur
    func deleteUser(id: Int) async throws {
        // DELETE /utilisateurs/:id
        let request = try Api.shared.makeRequest(endpoint: "/api/utilisateurs/\(id)", method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        // Pas de retour particulier
    }
}
