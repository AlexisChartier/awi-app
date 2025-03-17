import SwiftUI

struct UserManagementView: View {
    @StateObject var vm = UserManagementViewModel()

    var body: some View {
        List(vm.users) { user in
            Text("\(user.nom) – \(user.role)")
        }
        .navigationTitle("Gestion Utilisateurs")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Ajouter") {
                    // logiques d’ouverture de formulaire
                }
            }
        }
        .onAppear {
            vm.loadUsers()
        }
        // Affichage d’erreurs, d’un loading, etc.
    }
}
