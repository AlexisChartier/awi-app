import Foundation

class BilanService {
    static let shared = BilanService()
    private init() {}

    /// Télécharge le PDF bilan pour une session donnée
    /// Retourne les données brutes du PDF (Data).
    func downloadBilanSession(sessionId: Int) async throws -> Data {
        // GET /bilan/session/{session_id}, qui renvoie un PDF
        let request = try Api.shared.makeRequest(endpoint: "bilan/session/\(sessionId)", method: "GET")

        let (data, response) = try await URLSession.shared.data(for: request)

        // Vérifier le status code
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // data est le binaire PDF
        return data
    }

    /// Télécharge le PDF bilan pour un vendeur et une session
    func downloadBilanVendeur(vendeurId: Int, sessionId: Int) async throws -> Data {
        // GET /bilan/vendeur/{vendeur_id}&{session_id}, renvoie un PDF
        let request = try Api.shared.makeRequest(endpoint: "bilan/vendeur/\(vendeurId)&\(sessionId)", method: "GET")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return data
    }
}
