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
                                    GameCardCatalogView(game: game)
                                    HStack {
                                        Button("Détail") {
                                            vm.openDetailDialog(game)
                                        }
                                        .font(.caption)
                                        .foregroundColor(.green)

                                        Spacer()
                                        Button("Modifier" ) {
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
            .sheet(isPresented: $vm.showDetailSheet){
                if let detailGame = vm.detailGame{
                    GameDetailSheet(game:detailGame){
                        vm.closeDetailDialog()
                    }
                }
            }
        }
    }
}




// Vue auxiliaire pour un champ avec label
struct LabeledTextField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct GameFormSheet: View {
    @ObservedObject var vm: CatalogViewModel

    // Stockage local des champs pour le formulaire
    @State private var nom: String = ""
    @State private var auteur: String = ""
    @State private var editeur: String = ""
    @State private var nbJoueurs: String = ""
    @State private var ageMin: String = ""
    @State private var duree: String = ""
    @State private var typeJeu: String = ""
    @State private var notice: String = ""
    @State private var themes: String = ""
    @State private var descriptionText: String = ""
    @State private var imageURL: String = ""
    // Pour un upload d’image, vous pouvez ajouter un @State pour UIImage

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Informations principales")) {
                    LabeledTextField(label: "Nom", text: $nom)
                    LabeledTextField(label: "Auteur", text: $auteur)
                    LabeledTextField(label: "Éditeur", text: $editeur)
                }
                Section(header: Text("Caractéristiques")) {
                    LabeledTextField(label: "Nombre de joueurs", text: $nbJoueurs)
                    LabeledTextField(label: "Âge min", text: $ageMin)
                    LabeledTextField(label: "Durée", text: $duree)
                    LabeledTextField(label: "Type de jeu", text: $typeJeu)
                    LabeledTextField(label: "Thèmes", text: $themes)
                }
                Section(header: Text("Ressources")) {
                    LabeledTextField(label: "Notice (URL)", text: $notice)
                    LabeledTextField(label: "Image (URL)", text: $imageURL)
                }
                Section(header: Text("Description")) {
                    Text("Description:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    TextEditor(text: $descriptionText)
                        .frame(height: 120)
                }
            }
            .navigationTitle(vm.isEditMode ? "Modifier le Jeu" : "Nouveau Jeu")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        vm.closeFormDialog()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        guard var current = vm.currentGame else {
                            vm.closeFormDialog()
                            return
                        }
                        // Mise à jour des champs
                        current.nom = nom
                        current.auteur = auteur.isEmpty ? nil : auteur
                        current.editeur = editeur.isEmpty ? nil : editeur
                        current.nbJoueurs = nbJoueurs.isEmpty ? nil : nbJoueurs
                        current.ageMin = ageMin.isEmpty ? nil : ageMin
                        current.duree = duree.isEmpty ? nil : duree
                        current.typeJeu = typeJeu.isEmpty ? nil : typeJeu
                        current.notice = notice.isEmpty ? nil : notice
                        current.themes = themes.isEmpty ? nil : themes
                        current.description = descriptionText.isEmpty ? nil : descriptionText
                        current.image = imageURL.isEmpty ? nil : imageURL

                        // Appel à la fonction du VM pour sauvegarder
                        vm.saveGame(current, imageFile: nil)
                    }
                }
            }
        }
        .onAppear {
            if let g = vm.currentGame {
                self.nom = g.nom
                self.auteur = g.auteur ?? ""
                self.editeur = g.editeur ?? ""
                self.nbJoueurs = g.nbJoueurs ?? ""
                self.ageMin = g.ageMin ?? ""
                self.duree = g.duree ?? ""
                self.typeJeu = g.typeJeu ?? ""
                self.notice = g.notice ?? ""
                self.themes = g.themes ?? ""
                self.descriptionText = g.description ?? ""
                self.imageURL = g.image ?? ""
            }
        }
    }
}



struct GameDetailSheet: View {
    let game: Jeu
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Affichage de l'image du jeu
                    if let imgStr = game.image, let url = URL(string: imgStr) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 200)
                            case .success(let img):
                                img.resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .clipped()
                            case .failure(_):
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 200)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .foregroundColor(.gray)
                    }
                    
                    // Titre du jeu
                    Text(game.nom)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    // Détails avec labels
                    Group {
                        if let auteur = game.auteur, !auteur.isEmpty {
                            DetailRow(label: "Auteur", value: auteur)
                        }
                        if let editeur = game.editeur, !editeur.isEmpty {
                            DetailRow(label: "Éditeur", value: editeur)
                        }
                        if let nbJoueurs = game.nbJoueurs, !nbJoueurs.isEmpty {
                            DetailRow(label: "Nb joueurs", value: nbJoueurs)
                        }
                        if let ageMin = game.ageMin, !ageMin.isEmpty {
                            DetailRow(label: "Âge min", value: ageMin)
                        }
                        if let duree = game.duree, !duree.isEmpty {
                            DetailRow(label: "Durée", value: duree)
                        }
                        if let typeJeu = game.typeJeu, !typeJeu.isEmpty {
                            DetailRow(label: "Type", value: typeJeu)
                        }
                        if let themes = game.themes, !themes.isEmpty {
                            DetailRow(label: "Thèmes", value: themes)
                        }
                        if let notice = game.notice, !notice.isEmpty {
                            DetailRow(label: "Notice", value: notice)
                        }
                        
                        if let description = game.description, !description.isEmpty {
                            Text(description)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Détails du jeu")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        onClose()
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text("\(label):")
                .fontWeight(.semibold)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
