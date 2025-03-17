import SwiftUI

class UserManagementViewModel: ObservableObject {
    @Published var users: [Utilisateur] = []
    @Published var loading: Bool = false
    @Published var errorMessage: String?

    // éventuellement des champs pour création
    // @Published var newUserName: String = ""
    // @Published var newUserEmail: String = ""

    func loadUsers() {
        loading = true
        Task {
            do {
                // Suppose que vous avez un service ex: UserService.shared
                let fetched = try await UserService.shared.fetchAllUsers()
                await MainActor.run {
                    self.users = fetched
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur chargement utilisateurs: \(error)"
                    self.loading = false
                }
            }
        }
    }

    func createUser(_ user: Utilisateur) {
        loading = true
        Task {
            do {
                let newUsr = try await UserService.shared.createUser(user)
                await MainActor.run {
                    self.users.append(newUsr)
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur création utilisateur: \(error)"
                    self.loading = false
                }
            }
        }
    }

    func deleteUser(_ userId: Int) {
        loading = true
        Task {
            do {
                try await UserService.shared.deleteUser(id: userId)
                await MainActor.run {
                    self.users.removeAll { $0.id == userId }
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur suppression utilisateur: \(error)"
                    self.loading = false
                }
            }
        }
    }
}
