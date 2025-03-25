//
//  VenteJeu.swift
//  awi-app
//
//  Created by etud on 15/03/2025.
//

import Foundation

/// Détaille un jeu spécifique vendu dans le cadre d’une vente.
/// Permet de relier un dépôt à une vente avec les prix et commissions appliqués.
struct VenteJeu: Identifiable, Codable {
    /// Identifiant unique de la vente-jeu (correspond à `vente_jeu_id`)
    let id: Int

    /// Identifiant de la vente globale
    var venteId: Int

    /// Identifiant du dépôt du jeu vendu
    var depotJeuId: Int

    /// Prix de vente effectif du jeu
    var prixVente: Double

    /// Commission prélevée sur cette vente
    var commission: Double

    /// Correspondance pour l'API
    enum CodingKeys: String, CodingKey {
        case id = "vente_jeu_id"
        case venteId = "vente_id"
        case depotJeuId = "depot_jeu_id"
        case prixVente = "prix_vente"
        case commission
    }
}
