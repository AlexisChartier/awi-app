//
//  Session.swift
//  awi-app
//
//  Created by etud on 15/03/2025.
//

import Foundation

/// Représente une session de vente (événement ponctuel ou récurrent).
/// - `statut` ∈ {"active", "inactive"}
/// - `modeFraisDepot` ∈ {"fixe", "pourcentage"}
struct Session: Identifiable, Codable, Hashable {
    /// Identifiant unique de la session (correspond à `session_id`)
    let id: Int

    /// Nom de la session (optionnel)
    var nom: String?

    /// Date de début de la session
    var dateDebut: Date

    /// Date de fin de la session
    var dateFin: Date

    /// Statut actuel de la session
    var statut: String

    /// Mode de calcul des frais de dépôt ("fixe" ou "pourcentage")
    var modeFraisDepot: String

    /// Valeur fixe ou pourcentage selon le mode de frais
    var fraisDepot: Double

    /// Taux de commission applicable sur les ventes
    var commissionRate: Double

    /// Identifiant de l’administrateur gérant cette session (optionnel)
    var administrateurId: Int?

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

    /// Initialisation personnalisée pour gérer les dates ISO8601 et les valeurs numériques encodées en chaînes
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.nom = try container.decodeIfPresent(String.self, forKey: .nom)

        let dateDebutString = try container.decode(String.self, forKey: .dateDebut)
        let dateFinString   = try container.decode(String.self, forKey: .dateFin)

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let parsedDebut = isoFormatter.date(from: dateDebutString),
              let parsedFin = isoFormatter.date(from: dateFinString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .dateDebut,
                in: container,
                debugDescription: "Format ISO8601 invalide pour date_debut/date_fin"
            )
        }

        self.dateDebut = parsedDebut
        self.dateFin = parsedFin

        self.statut = try container.decode(String.self, forKey: .statut)
        self.modeFraisDepot = try container.decode(String.self, forKey: .modeFraisDepot)

        if let fraisStr = try? container.decode(String.self, forKey: .fraisDepot) {
            self.fraisDepot = Double(fraisStr) ?? 0.0
        } else {
            self.fraisDepot = try container.decode(Double.self, forKey: .fraisDepot)
        }

        if let comStr = try? container.decode(String.self, forKey: .commissionRate) {
            self.commissionRate = Double(comStr) ?? 0.0
        } else {
            self.commissionRate = try container.decode(Double.self, forKey: .commissionRate)
        }

        self.administrateurId = try container.decodeIfPresent(Int.self, forKey: .administrateurId)
    }

    /// Initialisation standard
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
