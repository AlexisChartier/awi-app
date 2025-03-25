//
//  Acheteur.swift
//  awi-app
//
//  Created by etud on 15/03/2025.
//

import Foundation

/// Représente un acheteur dans le système.
/// Conforme aux protocoles `Identifiable` (pour SwiftUI) et `Codable` (pour encodage/décodage JSON).
struct Acheteur: Identifiable, Codable {
    /// Identifiant unique de l'acheteur (correspond à `acheteur_id` côté back-end)
    let id: Int
    
    /// Nom complet de l'acheteur
    var nom: String
    
    /// Adresse email de l'acheteur (optionnelle)
    var email: String?
    
    /// Numéro de téléphone (optionnel)
    var telephone: String?
    
    /// Adresse postale (optionnelle)
    var adresse: String?

    /// Clés de correspondance pour le décodage JSON (liens entre les noms Swift et les champs API/back-end)
    enum CodingKeys: String, CodingKey {
        case id = "acheteur_id"
        case nom
        case email
        case telephone
        case adresse
    }
}
