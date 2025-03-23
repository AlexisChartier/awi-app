//
//  Acheteur.swift
//  awi-app
//
//  Created by etud on 15/03/2025.
//


import Foundation

struct Acheteur: Identifiable, Codable {
    let id: Int               // correspond à acheteur_id
    var nom: String
    var email: String?
    var telephone: String?
    var adresse: String?

    enum CodingKeys: String, CodingKey {
        case id = "acheteur_id"
        case nom
        case email
        case telephone
        case adresse
    }
}
