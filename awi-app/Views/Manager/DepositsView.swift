//
//  DepositsView.swift
//  awi-app
//
//  Created by etud on 19/03/2025.
//
import SwiftUI

struct DepositsView: View {
    @StateObject var vm = GameDepositViewModel()
    @State private var showConfirmDialog = false
    
    @StateObject private var catalogVM = CatalogViewModel()
    @State private var showGameCreationSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.cyan, Color.purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    if let error = vm.errorMessage {
                        alertView(text: error, color: AppTheme.errorColor) { vm.errorMessage = nil }
                    }
                    if let success = vm.successMessage {
                        alertView(text: success, color: AppTheme.successColor) { vm.successMessage = nil }
                    }

                    if vm.isLoading {
                        Spacer()
                        ProgressView("Chargement...")
                            .progressViewStyle(CircularProgressViewStyle())
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: AppTheme.sectionSpacing) {

                                // Section Vendeur
                                sectionCard(icon: "person.crop.circle.badge.checkmark", title: "Sélection du Vendeur") {
                                    Picker("Vendeur", selection: $vm.selectedVendeurId) {
                                        Text("-- Sélectionnez un vendeur --").tag(Int?.none)
                                        ForEach(vm.vendeurs, id: \.id) { v in
                                            Text("\(v.nom)").tag(v.id as Int?)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .pickerStyle(.menu)
                                }

                                // Session Active
                                if let session = vm.sessionActive {
                                    sectionCard(icon: "calendar.badge.clock", title: "Session Active", color: AppTheme.successColor) {
                                        Text("Nom : \(session.nom ?? "Sans nom")")
                                        Text("Frais de dépôt : \(session.fraisDepot, format: .number) \(session.modeFraisDepot == "pourcentage" ? "%" : "€")")
                                        Text("Commission : \(session.commissionRate, format: .number)%")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                } else {
                                    sectionCard(icon: "calendar.badge.exclamationmark", title: "Session") {
                                        Text("Aucune session active").foregroundColor(.red)
                                    }
                                }

                                // Filtres
                                sectionCard(icon: "line.3.horizontal.decrease.circle", title: "Filtres") {
                                    TextField("🔍 Rechercher un jeu", text: $vm.searchTerm)
                                        .textFieldStyle(.roundedBorder)
                                    Picker("Filtrer par éditeur", selection: $vm.filterEditeur) {
                                        Text("-- Tous éditeurs --").tag("")
                                        ForEach(vm.uniqueEditeurs(), id: \.self) { ed in
                                            Text(ed).tag(ed)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }

                                // Ajouter un jeu
                                sectionCard(icon: "plus.circle", title: "Catalogue") {
                                    Button {
                                        showGameCreationSheet = true
                                    } label: {
                                        Label("Ajouter un jeu au catalogue", systemImage: "plus.square.on.square")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                }

                                // Grille des jeux
                                sectionCard(icon: "rectangle.grid.2x2", title: "Catalogue") {
                                    let pagedGames = vm.paginatedCatalog()
                                    if pagedGames.isEmpty {
                                        Text("Aucun jeu trouvé.").foregroundColor(.gray)
                                    } else {
                                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                            ForEach(pagedGames, id: \.id) { game in
                                                GameCardView(
                                                    game: game,
                                                    isSelected: vm.selectedGame?.id == game.id
                                                ) {
                                                    vm.selectedGame = game
                                                }
                                            }
                                        }
                                        HStack {
                                            Button {
                                                if vm.currentPage > 0 { vm.currentPage -= 1 }
                                            } label: {
                                                Label("Préc", systemImage: "chevron.left")
                                            }.disabled(vm.currentPage == 0)

                                            Spacer()
                                            Text("Page \(vm.currentPage + 1) / \(max(vm.totalPages, 1))")
                                            Spacer()

                                            Button {
                                                if vm.currentPage < vm.totalPages - 1 { vm.currentPage += 1 }
                                            } label: {
                                                Label("Suiv", systemImage: "chevron.right")
                                            }.disabled(vm.currentPage >= vm.totalPages - 1)
                                        }
                                        .font(.footnote)
                                        .padding(.top, 4)
                                    }
                                }

                                // Formulaire ajout
                                if let selected = vm.selectedGame {
                                    addGameForm(selectedGame: selected)
                                }

                                // Liste jeux à déposer
                                if !vm.depositItems.isEmpty {
                                    sectionCard(icon: "shippingbox.fill", title: "Jeux à déposer", color: AppTheme.highlightBackground) {
                                        ForEach(vm.depositItems) { item in
                                            HStack {
                                                Text("\(item.nom) - \(item.prixVente, format: .number)€ (\(item.etat.rawValue))")
                                                Spacer()
                                                Button("Retirer") {
                                                    vm.removeItem(item)
                                                }
                                                .foregroundColor(.red)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }

                                // Résumé
                                if vm.sessionActive != nil {
                                    sectionCard(icon: "doc.plaintext", title: "Résumé") {
                                        Text("Frais totaux : \(vm.calculateDepositFeesAvantRemise(), format: .number)€")
                                        Text("Remise totale : \(vm.calculateTotalRemise(), format: .number)€")
                                        Text("Nb d'items : \(vm.depositItems.count)")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }

                                // Bouton final
                                Button("✅ Valider le dépôt") {
                                    if vm.validateDeposit() {
                                        showConfirmDialog = true
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(vm.depositItems.isEmpty || vm.selectedVendeurId == nil ? Color.gray : AppTheme.successColor)
                                .foregroundColor(.white)
                                .cornerRadius(AppTheme.cornerRadius)
                                .disabled(vm.depositItems.isEmpty || vm.selectedVendeurId == nil)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Dépôt")
            .confirmationDialog("Confirmation",
                                isPresented: $showConfirmDialog,
                                titleVisibility: .visible) {
                Button("Payer et Valider", role: .destructive) {
                    Task { await vm.finalizeDeposit() }
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Vous allez payer \(vm.calculateTotalDepositFees(), format: .number)€ pour \(vm.depositItems.count) jeux.")
            }
            .sheet(isPresented: $showGameCreationSheet) {
                GameFormSheet(vm: catalogVM)
            }
        }
    }

    // MARK: - Alert View
    private func alertView(text: String, color: Color, onClose: @escaping () -> Void) -> some View {
        HStack {
            Label(text, systemImage: "exclamationmark.triangle.fill")
                .foregroundColor(color)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
            }
            .foregroundColor(color)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(AppTheme.cornerRadius)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    // MARK: - Section Wrapper
    private func sectionCard<Content: View>(
        icon: String,
        title: String,
        color: Color = AppTheme.secondaryBackground,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
            content()
        }
        .padding()
        .background(
            color
                .opacity(0.9)
                .blur(radius: 0.2)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        )
        .cornerRadius(AppTheme.cornerRadius)
        .frame(maxWidth: .infinity, alignment: .leading) 
    }

    // MARK: - Formulaire d’ajout de jeu
    @ViewBuilder
    private func addGameForm(selectedGame: Jeu) -> some View {
        sectionCard(icon: "plus.rectangle", title: "Ajouter \"\(selectedGame.nom)\"") {
            HStack {
                Text("Prix (€) :")
                TextField("Prix", value: $vm.tempPrice, format: .number)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("Quantité :")
                TextField("Qté", value: $vm.tempQuantity, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
            }

            Picker("État", selection: $vm.tempEtat) {
                Text("Neuf").tag(GameDepositViewModel.EtatJeu.Neuf)
                Text("Occasion").tag(GameDepositViewModel.EtatJeu.Occasion)
            }
            .pickerStyle(.segmented)

            if vm.tempEtat == .Occasion {
                TextField("Détail de l'état", text: $vm.tempDetailEtat)
                    .textFieldStyle(.roundedBorder)
            }

            let maxRemise: Double = {
                if let session = vm.sessionActive {
                    if session.modeFraisDepot == "fixe" {
                        return max(session.fraisDepot, 0)
                    } else {
                        return max(vm.tempPrice * session.fraisDepot / 100 , 0)
                    }
                }
                return 50
            }()

            VStack(alignment: .leading) {
                Text("Remise : \(vm.tempRemise, format: .number)€ (Max: \(maxRemise, format: .number)€)")
                Slider(value: $vm.tempRemise, in: 0...maxRemise, step: 1)
            }

            Button("Ajouter au dépôt") {
                vm.addGameToDeposit()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
