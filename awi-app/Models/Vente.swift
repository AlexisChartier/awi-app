//
//  Vente.swift
//  awi-app
//
//  Created by etud on 15/03/2025.
//


import Foundation

struct Vente: Identifiable, Codable {
    let id: Int               // correspond à vente_id
    var acheteurId: Int?
    var dateVente: Date
    var montantTotal: Double
    var sessionId: Int

    enum CodingKeys: String, CodingKey {
        case id = "vente_id"
        case acheteurId = "acheteur_id"
        case dateVente = "date_vente"
        case montantTotal = "montant_total"
        case sessionId = "session_id"
    }
}
