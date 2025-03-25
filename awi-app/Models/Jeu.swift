//
//  Jeu.swift
//  awi-app
//
//  Created by etud on 15/03/2025.
//

import Foundation

/// Représente un jeu référencé dans le système.
/// Peut être utilisé dans plusieurs dépôts.
struct Jeu: Identifiable, Codable {
    /// Identifiant unique du jeu (correspond à `jeu_id`)
    let id: Int?

    /// Nom du jeu
    var nom: String

    /// Auteur du jeu (optionnel)
    var auteur: String?

    /// Éditeur du jeu (optionnel)
    var editeur: String?

    /// Nombre de joueurs (ex : "2-4") (optionnel)
    var nbJoueurs: String?

    /// Âge minimum recommandé (optionnel)
    var ageMin: String?

    /// Durée moyenne d’une partie (ex : "30 min") (optionnel)
    var duree: String?

    /// Type de jeu (ex : "stratégie", "familial") (optionnel)
    var typeJeu: String?

    /// Notice du jeu (URL ou contenu) (optionnel)
    var notice: String?

    /// Thèmes du jeu (ex : "fantastique, science-fiction") (optionnel)
    var themes: String?

    /// Description libre du jeu (optionnel)
    var description: String?

    /// Lien vers l’image du jeu (optionnel)
    var image: String?

    /// Lien vers un logo (éditeur, collection...) (optionnel)
    var logo: String?

    /// Correspondance avec les champs JSON
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
