//
//  Vendeur.swift
//  awi-app
//
//  Created by etud on 15/03/2025.
//

import Foundation

/// Représente un vendeur déposant un ou plusieurs jeux.
struct Vendeur: Identifiable, Codable {
    /// Identifiant unique du vendeur (correspond à `vendeur_id`)
    let id: Int?

    /// Nom du vendeur
    var nom: String

    /// Adresse email du vendeur
    var email: String

    /// Numéro de téléphone
    var telephone: String

    /// Correspondance des clés pour l’API
    enum CodingKeys: String, CodingKey {
        case id = "vendeur_id"
        case nom
        case email
        case telephone
    }
}
