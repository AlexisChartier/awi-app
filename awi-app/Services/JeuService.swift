//
//  JeuService.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//
import Foundation

class JeuService {
    static let shared = JeuService()
    private init() {}

    // MARK: - 1) Récupérer tous les jeux
    func getAllJeux() async throws -> [Jeu] {
        // GET /jeux => { jeux: [...] } ou juste [...]
        let request = try Api.shared.makeRequest(endpoint: "/api/jeux", method: "GET")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Si le back renvoie { "jeux": [...] }
        struct JeuxResponse: Codable {
            let jeux: [Jeu]
        }
        let decoded = try JSONDecoder().decode(JeuxResponse.self, from: data)
        // ou si c'est directement un tableau, decode([Jeu].self, from: data)
        return decoded.jeux
    }

    // MARK: - 2) Créer un nouveau jeu
    func create(data: Jeu) async throws -> Jeu {
        // POST /jeux => { jeu: {...} }
        let body = try JSONEncoder().encode(data)
        let request = try Api.shared.makeRequest(endpoint: "/api/jeux", method: "POST", body: body)

        let (resData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct CreateResponse: Codable {
            let jeu: Jeu
        }
        let decoded = try JSONDecoder().decode(CreateResponse.self, from: resData)
        return decoded.jeu
    }

    // MARK: - 3) Mettre à jour un jeu
    func update(id: Int, data: Jeu) async throws -> Jeu {
        // PUT /jeux/:id => { jeu: {...} }
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
        let decoded = try JSONDecoder().decode(UpdateResponse.self, from: resData)
        return decoded.jeu
    }

    // MARK: - 4) Supprimer un jeu
    func delete(id: Int) async throws {
        // DELETE /jeux/:id
        let request = try Api.shared.makeRequest(endpoint: "/api/jeux/\(id)", method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        // Pas de retour particulier
    }

    // MARK: - 5) Importer un CSV (multipart/form-data)
    func importCsv(csvData: Data, fileName: String) async throws {
        // POST /jeux/import-csv
        // On construit manuellement le multipart
        var request = try Api.shared.makeRequest(endpoint: "/api/jeux/import-csv", method: "POST")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        // Début
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: text/csv\r\n\r\n".data(using: .utf8)!)
        // contenu CSV
        body.append(csvData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - 6) Récupérer un jeu par ID
    func getById(id: Int) async throws -> Jeu {
        // GET /jeux/:id => { jeu: {...} }
        let request = try Api.shared.makeRequest(endpoint: "/api/jeux/\(id)", method: "GET")

        let (resData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct OneJeuResponse: Codable {
            let jeu: Jeu
        }
        let decoded = try JSONDecoder().decode(OneJeuResponse.self, from: resData)
        return decoded.jeu
    }

    // MARK: - 7) Créer avec image (POST /jeux/uploadwithimage)
    func createWithImage(formData: Data, boundary: String) async throws -> Jeu {
        // On suppose que vous avez déjà "formData" correct (multipart)
        // + le boundary
        var request = try Api.shared.makeRequest(endpoint: "/api/jeux/uploadwithimage", method: "POST")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = formData

        let (resData, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct CreateImageResponse: Codable {
            let jeu: Jeu
        }
        let decoded = try JSONDecoder().decode(CreateImageResponse.self, from: resData)
        return decoded.jeu
    }

    /// (Variante) build un multipart si vous voulez le faire ici:
    func createWithImage2(jeu: Jeu, imageData: Data, imageName: String) async throws -> Jeu {
        // Exemple d’assemblage manuel du multipart
        var request = try Api.shared.makeRequest(endpoint: "/api/jeux/uploadwithimage", method: "POST")
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        // Champs texte (ex. nom, editeur, etc.)
        // 1) Convertir jeu en [String: String] ou parse manuellement
        if let encodedJeu = try? JSONEncoder().encode(jeu),
           let jeuDict = try? JSONSerialization.jsonObject(with: encodedJeu) as? [String: Any] {
            for (key, val) in jeuDict {
                guard let valStr = "\(val)" as String? else { continue }
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(valStr)\r\n".data(using: .utf8)!)
            }
        }

        // 2) Champ image
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

        // On suppose { jeu: {...} }
        struct CreateImageResponse: Codable {
            let jeu: Jeu
        }
        let decoded = try JSONDecoder().decode(CreateImageResponse.self, from: resData)
        return decoded.jeu
    }
}
