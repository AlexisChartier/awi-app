//
//  Jeu.swift
//  awi-app
//
//  Created by etud on 15/03/2025.
//


import Foundation

struct Jeu: Identifiable, Codable {
    let id: Int?               // correspond à jeu_id
    var nom: String
    var auteur: String?
    var editeur: String?
    var nbJoueurs: String?    // peut être un Int ? selon vos besoins
    var ageMin: String?
    var duree: String?
    var typeJeu: String?
    var notice: String?
    var themes: String?
    var description: String?
    var image: String?
    var logo: String?

    enum CodingKeys: String, CodingKey {
        case id = "jeu_id"
        case nom
        case auteur
        case editeur
        case nbJoueurs = "nb_joueurs"
        case ageMin = "age_min"
        case duree
        case typeJeu = "type_jeu"
        case notice
        case themes
        case description
        case image
        case logo
    }
}
