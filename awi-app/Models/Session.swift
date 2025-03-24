import Foundation

/// statut ∈ {"active", "inactive"}
/// modeFraisDepot ∈ {"fixe", "pourcentage"}
struct Session: Identifiable, Codable, Hashable {
    let id: Int                      // session_id
    var nom: String?                 // nom
    var dateDebut: Date              // date_debut
    var dateFin: Date                // date_fin
    var statut: String               // "active" ou "inactive"
    var modeFraisDepot: String       // "fixe" ou "pourcentage"
    var fraisDepot: Double           // ex. "2.00" -> 2.00
    var commissionRate: Double       // ex. "10.00" -> 10.00
    var administrateurId: Int?       // administrateur_id

    enum CodingKeys: String, CodingKey {
        case id = "session_id"
        case nom
        case dateDebut = "date_debut"
        case dateFin = "date_fin"
        case statut
        case modeFraisDepot = "mode_frais_depot"
        case fraisDepot = "frais_depot"
        case commissionRate = "commission_rate"
        case administrateurId = "administrateur_id"
    }

    /// Initialisation manuelle pour décoder le JSON renvoyé par le back-end,
    /// qui donne "frais_depot": "2.00", "commission_rate": "10.00", etc.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // id
        self.id = try container.decode(Int.self, forKey: .id)

        // nom
        self.nom = try container.decodeIfPresent(String.self, forKey: .nom)

        // Les dates sont en ISO8601 ex. "2025-12-31T22:00:00.000Z"
        let dateDebutString = try container.decode(String.self, forKey: .dateDebut)
        let dateFinString   = try container.decode(String.self, forKey: .dateFin)

        let isoFormatter = ISO8601DateFormatter()
        // Permet de gérer "...000Z" (fractional seconds, timezone Z)
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let parsedDebut = isoFormatter.date(from: dateDebutString),
              let parsedFin   = isoFormatter.date(from: dateFinString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .dateDebut,
                in: container,
                debugDescription: "Format ISO8601 invalide pour date_debut/date_fin"
            )
        }
        self.dateDebut = parsedDebut
        self.dateFin   = parsedFin

        // statut
        self.statut = try container.decode(String.self, forKey: .statut)

        // mode_frais_depot
        self.modeFraisDepot = try container.decode(String.self, forKey: .modeFraisDepot)

        // frais_depot => on récupère un String et on le convertit en Double
        // frais_depot : accepté sous forme de string OU nombre
        if let fraisStr = try? container.decode(String.self, forKey: .fraisDepot) {
            self.fraisDepot = Double(fraisStr) ?? 0.0
        } else {
            self.fraisDepot = try container.decode(Double.self, forKey: .fraisDepot)
        }


        // commission_rate => pareil
        if let comStr = try? container.decode(String.self, forKey: .commissionRate) {
            self.commissionRate = Double(comStr) ?? 0.0
        } else {
            self.commissionRate = try container.decode(Double.self, forKey: .commissionRate)
        }


        // administrateur_id
        self.administrateurId = try container.decodeIfPresent(Int.self, forKey: .administrateurId)
    }

    /// Constructeur classique (si vous en avez besoin dans le code)
    init(
        id: Int,
        nom: String?,
        dateDebut: Date,
        dateFin: Date,
        statut: String,
        modeFraisDepot: String,
        fraisDepot: Double,
        commissionRate: Double,
        administrateurId: Int?
    ) {
        self.id = id
        self.nom = nom
        self.dateDebut = dateDebut
        self.dateFin = dateFin
        self.statut = statut
        self.modeFraisDepot = modeFraisDepot
        self.fraisDepot = fraisDepot
        self.commissionRate = commissionRate
        self.administrateurId = administrateurId
    }
}
