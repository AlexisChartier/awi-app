import Foundation

class UserService {
    static let shared = UserService()
    private init() {}

    /// Récupérer tous les utilisateurs
    func fetchAllUsers() async throws -> [Utilisateur] {
        // GET /utilisateurs
        let request = try Api.shared.makeRequest(endpoint: "utilisateurs", method: "GET")
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
        // POST /utilisateurs
        // data est le corps JSON
        let body = try JSONEncoder().encode(data)
        let request = try Api.shared.makeRequest(endpoint: "utilisateurs", method: "POST", body: body)

        let (resData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Si le back renvoie { utilisateur: {...} }
        struct CreateUserResponse: Codable {
            let utilisateur: Utilisateur
        }
        let decoded = try JSONDecoder().decode(CreateUserResponse.self, from: resData)
        return decoded.utilisateur
        // Ou si renvoie directement l'utilisateur :
        // return try JSONDecoder().decode(Utilisateur.self, from: resData)
    }

    /// Mettre à jour un utilisateur
    func updateUser(id: Int, data: Utilisateur) async throws -> Utilisateur {
        // PUT /utilisateurs/:id
        let body = try JSONEncoder().encode(data)
        let request = try Api.shared.makeRequest(endpoint: "utilisateurs/\(id)", method: "PUT", body: body)

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
        let request = try Api.shared.makeRequest(endpoint: "utilisateurs/\(id)", method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        // Pas de retour particulier
    }
}
