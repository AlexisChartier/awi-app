//
//  JeuService.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//

import Foundation

/// Service responsable des opérations réseau liées aux jeux : CRUD, import CSV, ajout d'image, etc.
class JeuService {
    static let shared = JeuService()
    private init() {}

    /// Récupère tous les jeux.
    func getAllJeux() async throws -> [Jeu] {
        let request = try Api.shared.makeRequest(endpoint: "/api/jeux", method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct JeuxResponse: Codable {
            let jeux: [Jeu]
        }
        return try JSONDecoder().decode(JeuxResponse.self, from: data).jeux
    }

    /// Crée un nouveau jeu (sans image).
    func create(data: Jeu) async throws -> Jeu {
        let body = try JSONEncoder().encode(data)
        let request = try Api.shared.makeRequest(endpoint: "/api/jeux", method: "POST", body: body)
        let (resData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        struct CreateResponse: Codable {
            let jeu: Jeu
        }
        return try JSONDecoder().decode(CreateResponse.self, from: resData).jeu
    }

    /// Met à jour un jeu existant par son ID.
    func update(id: Int, data: Jeu) async throws -> Jeu {
        let body = try JSONEncoder().encode(data)
        let request = try Api.shared.makeRequest(endpoint: "/api/jeux/\(id)", method: "PUT", body: body)
        let (resData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct UpdateResponse: Codable {
            let jeu: Jeu
        }
        return try JSONDecoder().decode(UpdateResponse.self, from: resData).jeu
    }

    /// Supprime un jeu à partir de son identifiant.
    func delete(id: Int) async throws {
        let request = try Api.shared.makeRequest(endpoint: "/api/jeux/\(id)", method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    /// Importe un fichier CSV contenant des jeux (multipart).
    func importCsv(csvData: Data, fileName: String) async throws {
        var request = try Api.shared.makeRequest(endpoint: "/api/jeux/import-csv", method: "POST")
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
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

    /// Récupère un jeu par son ID.
    func getById(id: Int) async throws -> Jeu {
        let request = try Api.shared.makeRequest(endpoint: "/api/jeux/\(id)", method: "GET")
        let (resData, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct OneJeuResponse: Codable {
            let jeu: Jeu
        }
        return try JSONDecoder().decode(OneJeuResponse.self, from: resData).jeu
    }

    /// Crée un jeu avec une image via multipart déjà construit.
    func createWithImage(formData: Data, boundary: String) async throws -> Jeu {
        var request = try Api.shared.makeRequest(endpoint: "/api/jeux/uploadwithimage", method: "POST")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = formData

        let (resData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        struct CreateImageResponse: Codable {
            let jeu: Jeu
        }
        return try JSONDecoder().decode(CreateImageResponse.self, from: resData).jeu
    }

    /// Variante avec génération du `multipart/form-data` dans Swift.
    func createWithImage2(jeu: Jeu, imageData: Data, imageName: String) async throws -> Jeu {
        var request = try Api.shared.makeRequest(endpoint: "/api/jeux/uploadwithimage", method: "POST")
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        if let encodedJeu = try? JSONEncoder().encode(jeu),
           let jeuDict = try? JSONSerialization.jsonObject(with: encodedJeu) as? [String: Any] {
            for (key, val) in jeuDict {
                guard let valStr = "\(val)" as String? else { continue }
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(valStr)\r\n".data(using: .utf8)!)
            }
        }

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(imageName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (resData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        struct CreateImageResponse: Codable {
            let jeu: Jeu
        }
        return try JSONDecoder().decode(CreateImageResponse.self, from: resData).jeu
    }
}
