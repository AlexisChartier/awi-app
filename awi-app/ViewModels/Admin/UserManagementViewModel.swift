//
//  UserManagementViewModel.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//

import SwiftUI

/// ViewModel pour la gestion des utilisateurs administratifs (création, modification, suppression).
@MainActor
class UserManagementViewModel: ObservableObject {
    @Published var utilisateurs: [Utilisateur] = []
    @Published var loading = false
    @Published var errorMessage: String?

    // Création / édition
    @Published var showFormSheet = false
    @Published var isEditMode = false
    @Published var currentUser: Utilisateur?

    // Champs du formulaire utilisateur
    @Published var formNom: String = ""
    @Published var formEmail: String = ""
    @Published var formTelephone: String = ""
    @Published var formLogin: String = ""
    @Published var formPassword: String = ""
    @Published var formRole: UserRole = .manager

    // Suppression
    @Published var showDeleteDialog = false
    @Published var userToDelete: Utilisateur?

    var selectedUser: Utilisateur?

    /// Récupère tous les utilisateurs depuis le backend.
    func loadUsers() {
        loading = true
        Task {
            do {
                let list = try await UserService.shared.fetchAllUsers()
                self.utilisateurs = list
            } catch {
                errorMessage = "Erreur chargement utilisateurs"
            }
            loading = false
        }
    }

    /// Ouvre le formulaire pour créer un nouvel utilisateur.
    func openCreateSheet() {
        isEditMode = false
        currentUser = nil
        formNom = ""
        formEmail = ""
        formTelephone = ""
        formLogin = ""
        formPassword = ""
        formRole = .manager
        showFormSheet = true
    }

    /// Ouvre le formulaire pour éditer un utilisateur existant.
    func openEditSheet(_ user: Utilisateur) {
        isEditMode = true
        currentUser = user
        formNom = user.nom
        formEmail = user.email
        formTelephone = user.telephone ?? ""
        formLogin = user.login ?? ""
        formPassword = ""
        formRole = user.role
        showFormSheet = true
    }

    /// Ferme la fiche utilisateur.
    func closeFormSheet() {
        showFormSheet = false
        errorMessage = nil
    }

    /// Enregistre ou met à jour un utilisateur.
    func saveUser() {
        if isEditMode, let u = currentUser {
            // Mise à jour
            Task {
                do {
                    let updated = Utilisateur(
                        id: u.id,
                        nom: formNom,
                        email: formEmail,
                        telephone: formTelephone,
                        login: formLogin,
                        motDePasse: formPassword,
                        role: formRole
                    )
                    _ = try await UserService.shared.updateUser(id: u.id!, data: updated)
                    loadUsers()
                    showFormSheet = false
                } catch {
                    errorMessage = "Erreur enregistrement user"
                }
            }
        } else {
            // Création
            Task {
                do {
                    let newU = Utilisateur(
                        id: nil,
                        nom: formNom,
                        email: formEmail,
                        telephone: formTelephone,
                        login: formLogin,
                        motDePasse: formPassword,
                        role: formRole
                    )
                    _ = try await UserService.shared.createUser(newU)
                    loadUsers()
                    showFormSheet = false
                } catch {
                    errorMessage = "Erreur création user"
                }
            }
        }
    }

    /// Ouvre la boîte de dialogue de suppression.
    func openDeleteDialog(_ user: Utilisateur) {
        userToDelete = user
        showDeleteDialog = true
    }

    /// Ferme la boîte de dialogue de suppression.
    func closeDeleteDialog() {
        userToDelete = nil
        showDeleteDialog = false
    }

    /// Confirme la suppression de l'utilisateur sélectionné.
    func confirmDelete() {
        guard let ud = userToDelete else { return }
        Task {
            do {
                try await UserService.shared.deleteUser(id: ud.id!)
                loadUsers()
            } catch {
                errorMessage = "Erreur suppression user"
            }
            userToDelete = nil
            showDeleteDialog = false
        }
    }

    /// Supprime l’utilisateur actif dans le formulaire.
    func confirmDeleteUser() {
        guard let user = selectedUser else { return }
        Task {
            do {
                try await UserService.shared.deleteUser(id: user.id!)
                closeFormSheet()
                loadUsers()
            } catch {
                errorMessage = "Erreur lors de la suppression"
            }
        }
    }
}
