//
//  Vendeur.swift
//  awi-app
//
//  Created by etud on 15/03/2025.
//


import Foundation

struct Vendeur: Identifiable, Codable {
    let id: Int?               // correspond à vendeur_id
    var nom: String
    var email: String
    var telephone: String

    enum CodingKeys: String, CodingKey {
        case id = "vendeur_id"
        case nom
        case email
        case telephone
    }
}
