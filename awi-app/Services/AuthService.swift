import Foundation

class AuthService {
    static let shared = AuthService()

    private init() {}

    /// Exemple d'authentification
    func login(username: String, password: String) async throws {
        // Préparez le JSON à envoyer
        let credentials = ["login": username, "mot_de_passe": password]
        let bodyData = try JSONEncoder().encode(credentials)

        let request = try Api.shared.makeRequest(
            endpoint: "api/auth/login", 
            method: "POST", 
            body: bodyData
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Décoder la réponse : ex. { token: "...", user: {...} }
        struct AuthResponse: Codable {
            let token: String
            // let user: Utilisateur // si vous renvoyez un objet user
        }
        let auth = try JSONDecoder().decode(AuthResponse.self, from: data)

        // Stocker le token JWT
        Api.shared.authToken = auth.token
    }

    func logout() {
        // Pour un simple JWT, on peut juste effacer le token localement
        Api.shared.authToken = nil
    }

    /// Exemple de vérification (facultative)
    func isAuthenticated() -> Bool {
        return Api.shared.authToken != nil
    }
}
