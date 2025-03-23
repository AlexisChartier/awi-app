import SwiftUI

struct BuyersView: View {
    @StateObject var vm = BuyersViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                if let error = vm.errorMessage {
                    HStack {
                        Text(error).foregroundColor(.red)
                        Spacer()
                        Button("X") { vm.errorMessage = nil }
                    }
                    .padding()
                }

                // Barre recherche + bouton créer
                HStack {
                    TextField("Recherche par nom ou email", text: $vm.searchTerm)
                        .textFieldStyle(.roundedBorder)
                        .padding(.leading)

                    Button("Ajouter un Acheteur") {
                        vm.openCreateForm()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.trailing)
                }

                if vm.loading {
                    ProgressView("Chargement...")
                } else {
                    // Liste paginée
                    List {
                        ForEach(vm.paginatedBuyers, id: \.acheteur_id) { b in
                            // Affichage de chaque acheteur
                            VStack(alignment: .leading) {
                                Text(b.nom).bold()
                                if let email = b.email {
                                    Text("Email: \(email)")
                                }
                                if let tel = b.telephone, !tel.isEmpty {
                                    Text("Téléphone: \(tel)").foregroundColor(.secondary)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    vm.buyerToDelete = b
                                    vm.showDeleteConfirm = true
                                } label: {
                                    Text("Supprimer")
                                }
                                Button {
                                    vm.openEditForm(buyer: b)
                                } label: {
                                    Text("Éditer")
                                }
                            }
                        }
                        if vm.paginatedBuyers.isEmpty {
                            Text("Aucun acheteur à afficher.")
                                .foregroundColor(.gray)
                        }
                    }
                }

                // Pagination
                if vm.totalPages > 1 {
                    HStack {
                        Button("Précédent") {
                            vm.goToPage(vm.currentPage - 1)
                        }
                        .disabled(vm.currentPage == 1)

                        Text("Page \(vm.currentPage) / \(vm.totalPages)")

                        Button("Suivant") {
                            vm.goToPage(vm.currentPage + 1)
                        }
                        .disabled(vm.currentPage == vm.totalPages)
                    }
                    .padding(.vertical, 5)
                }
            }
            .navigationTitle("Gestion des Acheteurs")
            .onAppear {
                vm.loadBuyers()
            }
            // Alerte suppression
            .alert("Supprimer cet acheteur ?", isPresented: $vm.showDeleteConfirm, actions: {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    vm.deleteBuyer()
                }
            }, message: {
                if let b = vm.buyerToDelete {
                    Text("Voulez-vous vraiment supprimer \(b.nom) ?")
                }
            })
            // Sheet création/édition
            .sheet(isPresented: $vm.showFormSheet) {
                BuyerFormSheet(vm: vm)
            }
        }
    }
}

// MARK: - Sous-vue: Formulaire
struct BuyerFormSheet: View {
    @ObservedObject var vm: BuyersViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(vm.isEditMode ? "Modifier un Acheteur" : "Nouvel Acheteur")) {
                    TextField("Nom", text: $vm.currentBuyer.nom)
                    TextField("Email", text: Binding(
                        get: { vm.currentBuyer.email ?? "" },
                        set: { vm.currentBuyer.email = $0 }
                    ))
                    TextField("Téléphone", text: Binding(
                        get: { vm.currentBuyer.telephone ?? "" },
                        set: { vm.currentBuyer.telephone = $0 }
                    ))
                    TextField("Adresse", text: Binding(
                        get: { vm.currentBuyer.adresse ?? "" },
                        set: { vm.currentBuyer.adresse = $0 }
                    ))
                }
            }
            .navigationTitle(vm.isEditMode ? "Éditer" : "Créer")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        vm.closeForm()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(vm.isEditMode ? "Enregistrer" : "Créer") {
                        vm.saveBuyerForm()
                    }
                }
            }
        }
    }
}
