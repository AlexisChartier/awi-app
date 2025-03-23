import SwiftUI

struct CatalogView: View {
    @StateObject var vm = CatalogViewModel()
    @State private var csvData: Data?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // 🔍 Filtres
                    HStack(spacing: 12) {
                        TextField("Recherche...", text: $vm.searchTerm)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 100, maxWidth: 200)

                        TextField("Filtrer éditeur", text: $vm.filterEditeur)
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 100, maxWidth: 180)

                        Spacer()

                        Button {
                            vm.openCreateDialog()
                        } label: {
                            Label("Ajouter un Jeu", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.horizontal)

                    if let err = vm.errorMessage {
                        Text(err)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }

                    if vm.isLoading {
                        ProgressView("Chargement du catalogue...")
                            .frame(maxWidth: .infinity)
                    } else {
                        // 🧩 Grille des jeux
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(vm.pageJeux, id: \.id) { game in
                                VStack(spacing: 4) {
                                    GameCardView(
                                        game: game,
                                        isSelected: vm.selectedGames.contains(game.id ?? -1)
                                    ) {
                                        vm.toggleSelectGame(game.id ?? -1)
                                    }

                                    HStack {
                                        Button("Détail") {
                                            vm.openEditDialog(game)
                                        }
                                        .font(.caption)
                                        .foregroundColor(.blue)

                                        Spacer()

                                        Button("Supprimer") {
                                            vm.openDeleteDialog(game)
                                        }
                                        .font(.caption)
                                        .foregroundColor(.red)
                                    }
                                    .padding(.horizontal, 8)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)

                        // Pagination
                        HStack {
                            Text("Page \(vm.currentPage + 1)/\(vm.totalPages)")
                                .font(.caption)
                            Spacer()
                            Button("◀️ Précédent") {
                                vm.prevPage()
                            }
                            .disabled(vm.currentPage == 0)

                            Button("Suivant ▶️") {
                                vm.nextPage()
                            }
                            .disabled(vm.currentPage >= vm.totalPages - 1)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Catalogue de Jeux")
            .onAppear {
                vm.loadGames()
            }
            .alert("Supprimer ce jeu ?", isPresented: $vm.showDeleteDialog) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    vm.confirmDeleteGame()
                }
            } message: {
                if let gtd = vm.gameToDelete {
                    Text("Voulez-vous vraiment supprimer « \(gtd.nom) » ?")
                }
            }
            .sheet(isPresented: $vm.showFormDialog) {
                GameFormSheet(vm: vm)
            }
        }
    }
}


// Sous-vue pour créer/éditer un jeu
struct GameFormSheet: View {
    @ObservedObject var vm: CatalogViewModel
    @State private var localNom: String = ""
    // etc. on recopie dans un State local pour l’UI
    @State private var localImageData: Data?

    var body: some View {
        VStack {
            Text(vm.isEditMode ? "Modifier le Jeu" : "Nouveau Jeu")
                .font(.headline)

            TextField("Nom", text: $localNom).padding()

            // ... autres champs

            // un bouton pour choisir une image => localImageData
            // ex. iOS UIImagePicker
            // On simplifie

            HStack {
                Button("Annuler") {
                    vm.closeFormDialog()
                }
                Button("Enregistrer") {
                    // on reconstruit un Jeu depuis local states
                    if var cg = vm.currentGame {
                        cg.nom = localNom
                        // ...
                        vm.saveGame(cg, imageFile: localImageData)
                    } else {
                        vm.closeFormDialog()
                    }
                }
            }
        }
        .onAppear {
            if let cg = vm.currentGame {
                localNom = cg.nom
                // ...
            }
        }
    }
}
