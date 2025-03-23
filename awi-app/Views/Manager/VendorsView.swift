import SwiftUI

struct VendorsView: View {
    @StateObject var vm = VendorsViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                // Zone d'erreur
                if let error = vm.errorMessage {
                    HStack {
                        Text(error).foregroundColor(.red)
                        Spacer()
                        Button("X") {
                            vm.errorMessage = nil
                        }
                    }
                    .padding()
                }

                // Barre recherche + bouton créer
                HStack {
                    TextField("Recherche par nom ou email", text: $vm.searchTerm)
                        .textFieldStyle(.roundedBorder)
                        .padding(.leading)

                    Button("Ajouter un Vendeur") {
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
                        ForEach(vm.paginatedVendors, id: \.id) { v in
                            // NavigationLink vers le dashboard vendeur
                            NavigationLink(destination: VendorDashboardView(vendor: v)) {
                                // Row
                                VStack(alignment: .leading) {
                                    Text(v.nom).bold()
                                    Text("Email: \(v.email)")
                                    Text("Téléphone: \(v.telephone)")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    vm.vendorToDelete = v
                                    vm.showDeleteConfirm = true
                                } label: {
                                    Text("Supprimer")
                                }
                                Button {
                                    vm.openEditForm(vendor: v)
                                } label: {
                                    Text("Éditer")
                                }
                            }
                        }
                        if vm.paginatedVendors.isEmpty {
                            Text("Aucun vendeur à afficher.")
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
            .navigationTitle("Gestion des Vendeurs")
            // --- NOUVEAUTÉ : Bouton pour passer à la gestion des acheteurs ---
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink("Acheteurs", destination: BuyersView())
                }
            }
            // ---
            .onAppear {
                vm.loadVendors()
            }
            // Alerte suppression
            .alert("Supprimer ce vendeur ?", isPresented: $vm.showDeleteConfirm, actions: {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    vm.deleteVendor()
                }
            }, message: {
                if let vend = vm.vendorToDelete {
                    Text("Voulez-vous vraiment supprimer \(vend.nom) ?")
                }
            })
            // Sheet de création/édition
            .sheet(isPresented: $vm.showFormSheet) {
                VendorFormSheet(vm: vm)
            }
        }
    }
}

// MARK: - Sous-vue: Formulaire (inchangé)
struct VendorFormSheet: View {
    @ObservedObject var vm: VendorsViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(vm.isEditMode ? "Modifier un Vendeur" : "Nouveau Vendeur")) {
                    TextField("Nom", text: $vm.currentVendor.nom)
                    TextField("Email", text: $vm.currentVendor.email)
                    TextField("Téléphone", text: $vm.currentVendor.telephone)
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
                        vm.saveVendorForm()
                    }
                }
            }
        }
    }
}
