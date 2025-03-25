//
//  DepotJeu.swift
//  awi-app
//
//  Created by etud on 15/03/2025.
//

import Foundation

/// Représente un dépôt de jeu réalisé par un vendeur dans une session donnée.
/// Conforme aux protocoles `Identifiable` et `Codable`.
///
/// - `statut` peut être "en vente", "vendu" ou "retiré"
/// - `etat` peut être "Neuf" ou "Occasion"
struct DepotJeu: Identifiable, Codable {
    /// Identifiant unique du dépôt (correspond à `depot_jeu_id`)
    let id: Int
    
    /// Identifiant du jeu déposé
    var jeuId: Int
    
    /// Identifiant du vendeur ayant effectué le dépôt
    var vendeurId: Int
    
    /// Identifiant de la session dans laquelle le jeu a été déposé
    var sessionId: Int
    
    /// Prix de vente fixé pour le jeu
    var prixVente: Double
    
    /// Frais de dépôt appliqués
    var fraisDepot: Double
    
    /// Remise éventuelle appliquée sur le prix (optionnelle)
    var remise: Double?
    
    /// Date du dépôt du jeu
    var dateDepot: Date
    
    /// Code d’identification unique du jeu, s’il existe (ex. code barre)
    var identifiantUnique: String?
    
    /// Statut actuel du dépôt : "en vente", "vendu" ou "retiré"
    var statut: String
    
    /// État général du jeu : "Neuf" ou "Occasion"
    var etat: String
    
    /// Détail supplémentaire sur l’état (optionnel)
    var detailEtat: String?

    /// Clés de correspondance pour le décodage JSON
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
