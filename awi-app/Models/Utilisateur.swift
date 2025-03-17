import Foundation

/// role ∈ {"manager", "administrateur"}
struct Utilisateur: Identifiable, Codable {
    let id: Int               // correspond à utilisateur_id
    var nom: String
    var email: String
    var telephone: String?
    var login: String
    var motDePasse: String
    var role: String          // ou éventuellement un enum

    enum CodingKeys: String, CodingKey {
        case id = "utilisateur_id"
        case nom
        case email
        case telephone
        case login
        case motDePasse = "mot_de_passe"
        case role
    }
}
