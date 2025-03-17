import SwiftUI

struct SessionManagementView: View {
    @StateObject var vm = SessionManagementViewModel()

    var body: some View {
        List(vm.sessions) { session in
            VStack(alignment: .leading) {
                Text(session.nom ?? "Session sans nom").bold()
                Text("Date: \(session.dateDebut, formatter: dateFormatter) → \(session.dateFin, formatter: dateFormatter)")
                Text("Statut: \(session.statut)")
            }
        }
        .navigationTitle("Gestion Sessions")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Créer") {
                    // logiques d’ouverture de formulaire
                }
            }
        }
        .onAppear {
            vm.loadSessions()
        }
    }
}

private let dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateStyle = .short
    df.timeStyle = .none
    return df
}()
