import SwiftUI

struct CatalogView: View {
    @StateObject var vm = CatalogViewModel()

    var body: some View {
        List(vm.jeux, id: \.jeu_id) { jeu in
            VStack(alignment: .leading) {
                Text(jeu.nom)
                    .fontWeight(.bold)
                if let auteur = jeu.auteur {
                    Text("Auteur: \(auteur)")
                }
                if let editeur = jeu.editeur {
                    Text("Éditeur: \(editeur)")
                }
            }
        }
        .navigationTitle("Catalogue")
        .onAppear {
            vm.loadJeux()
        }
    }
}
