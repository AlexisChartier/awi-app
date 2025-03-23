import SwiftUI

@MainActor
class UserManagementViewModel: ObservableObject {
    @Published var utilisateurs: [Utilisateur] = []
    @Published var loading = false
    @Published var errorMessage: String?

    // Création / Édition
    @Published var showFormSheet = false
    @Published var isEditMode = false
    @Published var currentUser: Utilisateur?

    // Champs form
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
    func openEditSheet(_ user: Utilisateur) {
        isEditMode = true
        currentUser = user
        formNom = user.nom
        formEmail = user.email
        formTelephone = user.telephone ?? ""
        formLogin = user.login!
        formPassword = ""
        formRole = user.role
        showFormSheet = true
    }
    func closeFormSheet() {
        showFormSheet = false
        errorMessage = nil
    }
    func saveUser() {
        if isEditMode, let u = currentUser {
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
                    let r = try await UserService.shared.updateUser(id: u.id!, data: updated)
                    await loadUsers()
                    showFormSheet = false
                } catch {
                    errorMessage = "Erreur enregistrement user"
                }
            }
        } else {
            // create
            Task {
                do {
                    let newU = Utilisateur(
                        id: nil, nom: formNom,
                        email: formEmail,
                        telephone: formTelephone,
                        login: formLogin,
                        motDePasse: formPassword,
                        role: formRole
                    )
                    let c = try await UserService.shared.createUser(newU)
                    await loadUsers()
                    showFormSheet = false
                } catch {
                    errorMessage = "Erreur creation user"
                    print(error)
                }
            }
        }
    }

    func openDeleteDialog(_ user: Utilisateur) {
        userToDelete = user
        showDeleteDialog = true
    }
    func closeDeleteDialog() {
        userToDelete = nil
        showDeleteDialog = false
    }
    func confirmDelete() {
        guard let ud = userToDelete else { return }
        Task {
            do {
                try await UserService.shared.deleteUser(id: ud.id!)
                await loadUsers()
            } catch {
                errorMessage = "Erreur suppression user"
            }
            userToDelete = nil
            showDeleteDialog = false
        }
    }
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
