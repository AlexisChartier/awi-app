//
//  Api.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//

import Foundation

/// Service centralisé pour gérer les appels HTTP.
/// Inclut la configuration de l’URL de base, la gestion du token JWT, et la création des requêtes.
class Api {
    /// Singleton partagé
    static let shared = Api()

    /// URL de base de l’API (modifiable si besoin)
    private(set) var baseURL: URL = URL(string: "https://back-awi-backend-2.onrender.com")!

    /// Jeton JWT de l'utilisateur authentifié
    var authToken: String?

    /// Constructeur privé (singleton)
    private init() {}

    /// Crée une requête HTTP personnalisée avec ou sans body.
    /// - Parameters:
    ///   - endpoint: Chemin relatif de l’API
    ///   - method: Méthode HTTP (GET, POST, PUT...)
    ///   - queryParams: Paramètres en URL (optionnels)
    ///   - body: Corps JSON (optionnel)
    func makeRequest(
        endpoint: String,
        method: String,
        queryParams: [String: String]? = nil,
        body: Data? = nil
    ) throws -> URLRequest {
        // Construction de l’URL finale
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

        // Ajout de l'entête Authorization si un token est présent
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Ajout du corps pour les requêtes POST/PUT/PATCH
        if let body = body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }
}
