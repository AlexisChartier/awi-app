# Dev Mobile App

Application iOS développée en Swift dans le cadre du **Projet dev mobile**.  
Cette application s'appuie sur le back end du projet awi et reprends les mêmes fonctionnalités

---

## Fonctionnalités

- Authentification manager / admin
- Role Manager : Gestion des dépôts et ventes pour la session active, consultation des données vendeurs, gestion des vendeurs et acheteurs, consultation des bilans financiers
- Role Administrateur : Gestion des utilisateurs, gestion des sessions, consultation statistiques pour les sessions 
- Expérience utilisateur fluide sur iPhone et iPad

---

## Technologies

- Swift 6.0.3
- SwiftUI
- Combine
- URLSession / async-await pour les appels API
- Architecture MVVM
- iOS 18.2

---

## Prérequis

- Xcode 16.2 ou supérieur
- iOS 18.2 ou supérieur
- Connexion à l’API du backend déployé (voir [projet backend](https://github.com/AlexisChartier/awi-back))

---

## Structure du projet
awi-app/
-Models/      Structures de données (simulations, utilisateurs, etc.)
-Views/       Écrans de l'application SwiftUI
-ViewModels/  Logique de présentation (MVVM)
-Services/    Appels API, gestion des erreurs, etc.
-Utils/       Ressources diverses

## Sécurité & Données

- Authentification via token JWT
- Back-end déployé en HTTPS

## Auteur

Alexis Chartier
