//
//  Utilisateur.swift
//  awi-app
//
//  Created by etud on 15/03/2025.
//


import Foundation

enum UserRole: String, Codable, CaseIterable {
    case manager = "manager"
    case administrateur = "administrateur"
    // éventuellement d’autres roles
}
/// role ∈ {"manager", "administrateur"}
struct Utilisateur: Identifiable, Codable {
    let id: Int?               // correspond à utilisateur_id
    var nom: String
    var email: String
    var telephone: String?
    var login: String?
    var motDePasse: String?
    var role: UserRole          // ou éventuellement un enum

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
