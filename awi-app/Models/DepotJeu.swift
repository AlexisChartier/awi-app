import Foundation

/// statut ∈ {"en vente", "vendu", "retiré"}
/// etat ∈ {"Neuf", "Occasion"}
struct DepotJeu: Identifiable, Codable {
    let id: Int               // correspond à depot_jeu_id
    var jeuId: Int
    var vendeurId: Int
    var sessionId: Int
    var prixVente: Double
    var fraisDepot: Double
    var remise: Double?
    var dateDepot: Date
    var identifiantUnique: String?
    var statut: String
    var etat: String
    var detailEtat: String?

    enum CodingKeys: String, CodingKey {
        case id = "depot_jeu_id"
        case jeuId = "jeu_id"
        case vendeurId = "vendeur_id"
        case sessionId = "session_id"
        case prixVente = "prix_vente"
        case fraisDepot = "frais_depot"
        case remise
        case dateDepot = "date_depot"
        case identifiantUnique = "identifiant_unique"
        case statut
        case etat
        case detailEtat = "detail_etat"
    }
}
