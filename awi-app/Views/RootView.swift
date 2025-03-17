import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel // qui expose isAuthenticated, userRole

    var body: some View {
        Group {
            if !authVM.isAuthenticated {
                // Vue de connexion
                LoginView()
            } else {
                // Utilisateur connecté
                switch authVM.userRole {
                case "administrateur":
                    AdminTabView()  // barre d’onglets admin
                case "manager":
                    ManagerTabView() // barre d’onglets manager
                default:
                    Text("Rôle inconnu")
                }
            }
        }
    }
}
