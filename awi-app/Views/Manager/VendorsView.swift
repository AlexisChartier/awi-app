//
//  VendorsView.swift
//  awi-app
//
//  Created by etud on 18/03/2025.
//
import SwiftUI

struct VendorsView: View {
    @StateObject var vm = VendorsViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // 🔔 Zone d'erreur
                if let error = vm.errorMessage {
                    alertView(text: error, color: .red) {
                        vm.errorMessage = nil
                    }
                }

                // 🔍 Barre de recherche + ➕ Bouton création
                HStack(spacing: 12) {
                    TextField("Recherche par nom ou email", text: $vm.searchTerm)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity)

                    Button("➕ Ajouter") {
                        vm.openCreateForm()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)

                // 🔄 Chargement
                if vm.loading {
                    Spacer()
                    ProgressView("Chargement...")
                    Spacer()
                } else {
                    // 📋 Liste des vendeurs
                    List {
                        ForEach(vm.paginatedVendors, id: \.id) { v in
                            NavigationLink(destination: VendorDashboardView(vendor: v)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(v.nom).font(.headline)
                                    Text("Email: \(v.email)")
                                    Text("Téléphone: \(v.telephone)").foregroundColor(.secondary)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    vm.vendorToDelete = v
                                    vm.showDeleteConfirm = true
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }

                                Button {
                                    vm.openEditForm(vendor: v)
                                } label: {
                                    Label("Éditer", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            
                        }
                        
                        if vm.paginatedVendors.isEmpty {
                            Text("Aucun vendeur à afficher.")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    .listStyle(.insetGrouped)
                }

                // 📘 Pagination
                if vm.totalPages > 1 {
                    HStack(spacing: 16) {
                        Button("◀️ Précédent") {
                            vm.goToPage(vm.currentPage - 1)
                        }
                        .disabled(vm.currentPage == 1)

                        Text("Page \(vm.currentPage) / \(vm.totalPages)")
                            .font(.subheadline)

                        Button("Suivant ▶️") {
                            vm.goToPage(vm.currentPage + 1)
                        }
                        .disabled(vm.currentPage == vm.totalPages)
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(.top)
            .navigationTitle("Vendeurs")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink("Acheteurs", destination: BuyersView())
                }
            }
            .onAppear {
                vm.loadVendors()
            }
            // 🔥 Alerte suppression
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
            // 📄 Formulaire
            .sheet(isPresented: $vm.showFormSheet) {
                VendorFormSheet(vm: vm)
            }
        }
    }

    // Reusable alert view
    private func alertView(text: String, color: Color, onClose: @escaping () -> Void) -> some View {
        HStack {
            Text(text).foregroundColor(color)
            Spacer()
            Button("X", action: onClose)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}


// MARK: - Sous-vue: Formulaire (inchangé)
import SwiftUI

struct VendorFormSheet: View {
    @ObservedObject var vm: VendorsViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(vm.isEditMode ? "✏️ Modifier un Vendeur" : "➕ Nouveau Vendeur")) {
                    TextField("Nom", text: $vm.currentVendor.nom)
                        .textContentType(.name)
                        .autocapitalization(.words)

                    TextField("Email", text: $vm.currentVendor.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)

                    TextField("Téléphone", text: $vm.currentVendor.telephone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }
            }
            .navigationTitle(vm.isEditMode ? "Éditer Vendeur" : "Créer Vendeur")
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
                    .disabled(vm.currentVendor.nom.isEmpty || vm.currentVendor.email.isEmpty)
                }
            }
        }
    }
}
