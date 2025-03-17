//
//  SessionAWI.swift
//  awi-app
//
//  Created by etud on 15/03/2025.
//


import Foundation

/// statut ∈ {"active", "inactive"}
/// modeFraisDepot ∈ {"fixe", "pourcentage"}
struct SessionAWI: Identifiable, Codable {
    let id: Int               // correspond à session_id
    var nom: String?
    var dateDebut: Date
    var dateFin: Date
    var statut: String
    var modeFraisDepot: String
    var fraisDepot: Double
    var commissionRate: Double
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
}
