//
//  Utilisateur.swift
//  awi-app
//
//  Created by etud on 15/03/2025.
//

import Foundation

/// Rôles possibles d’un utilisateur de l’application.
enum UserRole: String, Codable, CaseIterable {
    case manager = "manager"
    case administrateur = "administrateur"
}

/// Représente un utilisateur de l’application (manager ou administrateur).
struct Utilisateur: Identifiable, Codable {
    /// Identifiant unique de l’utilisateur (correspond à `utilisateur_id`)
    let id: Int?

    /// Nom complet de l’utilisateur
    var nom: String

    /// Adresse email de l’utilisateur
    var email: String

    /// Numéro de téléphone (optionnel)
    var telephone: String?

    /// Identifiant de connexion (optionnel)
    var login: String?

    /// Mot de passe associé (optionnel)
    var motDePasse: String?

    /// Rôle de l’utilisateur dans le système
    var role: UserRole

    /// Mapping des noms de champs pour le backend
    enum CodingKeys: String, CodingKey {
        case id = "utilisateur_id"
        case nom
        case email
        case telephone
        case login
        case motDePasse = "mot_de_passe"
        case role
    }
}
