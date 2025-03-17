//
//  JeuRequest.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//


import Foundation

struct JeuRequest: Codable {
    var jeu_id: Int?
    var nom: String
    var auteur: String?
    var editeur: String?
    var nb_joueurs: String?
    var age_min: String?
    var duree: String?
    var type_jeu: String?
    var notice: String?
    var themes: String?
    var description: String?
    var image: String?
    var logo: String?
}

class JeuService {
    static let shared = JeuService()
    private init() {}

    /// GET /jeux => { jeux: [...] }
    func getAll() async throws -> [JeuRequest] {
        let request = try Api.shared.makeRequest(endpoint: "jeux", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        // { jeux: JeuRequest[] }
        struct JeuxResponse: Codable {
            let jeux: [JeuRequest]
        }
        let res = try JSONDecoder().decode(JeuxResponse.self, from: data)
        return res.jeux
    }

    /// POST /jeux => { jeu: {...} }
    func create(data: JeuRequest) async throws -> JeuRequest {
        let body = try JSONEncoder().encode(data)
        let request = try Api.shared.makeRequest(endpoint: "jeux", method: "POST", body: body)
        let (resData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
        struct CreateResponse: Codable {
            let jeu: JeuRequest
        }
        return try JSONDecoder().decode(CreateResponse.self, from: resData).jeu
    }

    /// PUT /jeux/:id => { jeu: {...} }
    func update(id: Int, data: JeuRequest) async throws -> JeuRequest {
        let body = try JSONEncoder().encode(data)
        let request = try Api.shared.makeRequest(endpoint: "jeux/\(id)", method: "PUT", body: body)
        let (resData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        struct UpdateResponse: Codable {
            let jeu: JeuRequest
        }
        return try JSONDecoder().decode(UpdateResponse.self, from: resData).jeu
    }

    /// DELETE /jeux/:id
    func delete(id: Int) async throws {
        let request = try Api.shared.makeRequest(endpoint: "jeux/\(id)", method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    /// POST /jeux/import-csv (multipart/form-data)
    /// En Swift, on doit créer un URLRequest personnalisé pour envoyer un fichier
    func importCsv(csvData: Data, fileName: String) async throws {
        // Option 1 : Confection manuelle du multipart/form-data (plus complexe)
        // Option 2 : Utiliser un lib tiers, ou le faire soi-même
        // Squelette minimaliste :

        var request = try Api.shared.makeRequest(endpoint: "jeux/import-csv", method: "POST")
        
        // boundary random
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Construire le body
        var body = Data()
        let disposition = "Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\""
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("\(disposition)\r\n".data(using: .utf8)!)
        body.append("Content-Type: text/csv\r\n\r\n".data(using: .utf8)!)
        body.append(csvData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    /// GET /jeux/:id => { jeu: {...} }
    func getById(id: Int) async throws -> JeuRequest {
        let request = try Api.shared.makeRequest(endpoint: "jeux/\(id)", method: "GET")
        let (resData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        struct OneJeuResponse: Codable {
            let jeu: JeuRequest
        }
        return try JSONDecoder().decode(OneJeuResponse.self, from: resData).jeu
    }

    /// POST /jeux/uploadwithimage (multipart/form-data)
    func createWithImage(formData: Data, boundary: String) async throws -> JeuRequest {
        // Ici, c’est similaire à importCsv, on envoie un multipart/form-data
        // On suppose qu'on a déjà formData + boundary préparés

        var request = try Api.shared.makeRequest(endpoint: "jeux/uploadwithimage", method: "POST")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = formData

        let (resData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw URLError(.badServerResponse)
        }
        struct CreateImageResponse: Codable {
            let jeu: JeuRequest
        }
        return try JSONDecoder().decode(CreateImageResponse.self, from: resData).jeu
    }
}
