import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userRole: String? = nil
    @Published var login: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String? = nil

    // Ex. si vous stockez un user complet :
    // @Published var currentUser: Utilisateur?

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Optionnel : restaurer un token depuis le Keychain / UserDefaults
        // si Api.shared.authToken existe, tenter un check
        if let token = Api.shared.authToken {
            // On considère qu'on est potentiellement connecté.
            // On peut faire un test sur le back-end, ex: verifyToken
            isAuthenticated = true
            // Récupérer le rôle depuis un endpoint si besoin
            // userRole = ...
        }
    }

    func loginAction() {
        Task {
            do {
                try await AuthService.shared.login(username: login, password: password)
                // Si le login est OK :
                self.isAuthenticated = true
                // Récupérer le rôle par un endpoint ou stocké dans la réponse du login
                // Par exemple:
                // let user = try await UserService.shared.getMe() 
                // self.userRole = user.role
                // self.currentUser = user
                // Pour l’exemple, on met un "manager" en dur 
                self.userRole = "manager" 
            } catch {
                await MainActor.run {
                    self.errorMessage = "Impossible de se connecter"
                }
            }
        }
    }

    func logout() {
        AuthService.shared.logout()
        self.isAuthenticated = false
        self.userRole = nil
        // self.currentUser = nil
    }
}
