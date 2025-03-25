//
//  AuthViewModel.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userRole: UserRole?
    @Published var login: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false   // ✅ Suivi de chargement

    func loginAction() {
        isLoading = true  // ✅ Démarrage du chargement
        Task {
            let creds = LoginCredentials(login: login, mot_de_passe: password)
            do {
                let authResp = try await AuthService.shared.login(credentials: creds)
                await MainActor.run {
                    self.isAuthenticated = true
                    self.userRole = authResp.utilisateur.role
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur de connexion"
                }
            }
            await MainActor.run {
                self.isLoading = false // ✅ Fin du chargement
            }
        }
    }

    func logoutAction() {
        AuthService.shared.logout()
        isAuthenticated = false
        userRole = nil
    }

    func checkTokenIfNeeded() {
        Task {
            let valid = await AuthService.shared.checkToken()
            await MainActor.run {
                self.isAuthenticated = valid
                // Possibilité de charger le user si valide
            }
        }
    }
}
