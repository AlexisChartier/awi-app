import Foundation

/// Gère la config réseau globale, l'URL de base, le token, etc.
class Api {
    static let shared = Api()

    /// Votre URL de base (par ex. sur Render)
    private(set) var baseURL: URL = URL(string: "https://back-awi-backend.onrender.com")!

    /// Stocker le token JWT si l'utilisateur est logué
    var authToken: String?

    private init() {}

    /// Méthode utilitaire pour créer une URLRequest et gérer l'entête Authorization.
    func makeRequest(
        endpoint: String,
        method: String = "GET",
        queryParams: [String: String]? = nil,
        body: Data? = nil
    ) throws -> URLRequest {
        // Construire l’URL finale
        guard var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        if let queryParams = queryParams {
            urlComponents.queryItems = queryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let finalURL = urlComponents.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = method
        // Ajouter le token si disponible
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        // Pour POST/PUT/PATCH
        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }
}
