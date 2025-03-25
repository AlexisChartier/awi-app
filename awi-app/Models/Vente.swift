//
//  Vente.swift
//  awi-app
//
//  Created by etud on 15/03/2025.
//

import Foundation

/// Représente une vente réalisée durant une session.
/// Peut contenir plusieurs jeux (via `VenteJeu`)
struct Vente: Identifiable, Codable {
    /// Identifiant unique de la vente (correspond à `vente_id`)
    let id: Int

    /// Identifiant de l’acheteur (optionnel si vente non attribuée)
    var acheteurId: Int?

    /// Date et heure de la vente
    var dateVente: Date

    /// Montant total encaissé pour cette vente
    var montantTotal: Double

    /// Session dans laquelle la vente a été réalisée
    var sessionId: Int

    /// Clés pour encodage/décodage JSON
    enum CodingKeys: String, CodingKey {
        case id = "vente_id"
        case acheteurId = "acheteur_id"
        case dateVente = "date_vente"
        case montantTotal = "montant_total"
        case sessionId = "session_id"
    }
}
