//
//  LoginView.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//


import SwiftUI

struct LoginView: View {
    @StateObject private var authVM = AuthViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Gestion dépôt-vente")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)

                // Champ Login
                TextField("Identifiant", text: $authVM.login)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                // Champ Password
                SecureField("Mot de passe", text: $authVM.password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                // Bouton connexion
                Button(action: {
                    authVM.loginAction()
                }) {
                    Text("Se connecter")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(8)
                }

                // Message d’erreur
                if let error = authVM.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Connexion")
        }
        .onChange(of: authVM.isAuthenticated) { isAuth in
            // Si la connexion réussit, vous pouvez naviguer 
            // ou laisser RootView gérer la redirection
        }
    }
}
