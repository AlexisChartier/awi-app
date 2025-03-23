//
//  RootView.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//


import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        Group {
            if !authVM.isAuthenticated {
                // Vue de connexion
                LoginView()
            } else {
                // L'utilisateur est authentifié
                // userRole est maintenant un enum UserRole? (optionnel)
                if let role = authVM.userRole {
                    switch role {
                    case .administrateur:
                        AdminTabView() // onglets admin
                    case .manager:
                        ManagerTabView() // onglets manager
                    }
                } else {
                    Text("Rôle inconnu")
                }
            }
        }
    }
}

