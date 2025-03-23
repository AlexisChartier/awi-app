//
//  VenteJeu.swift
//  awi-app
//
//  Created by etud on 15/03/2025.
//


import Foundation

struct VenteJeu: Identifiable, Codable {
    let id: Int               // correspond à vente_jeu_id
    var venteId: Int
    var depotJeuId: Int
    var prixVente: Double
    var commission: Double

    enum CodingKeys: String, CodingKey {
        case id = "vente_jeu_id"
        case venteId = "vente_id"
        case depotJeuId = "depot_jeu_id"
        case prixVente = "prix_vente"
        case commission
    }
}
