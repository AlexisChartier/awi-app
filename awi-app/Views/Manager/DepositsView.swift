import SwiftUI

struct DepositsView: View {
    @StateObject var vm = GameDepositViewModel()
    @State private var showConfirmDialog = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Zone d'alertes
                if let error = vm.errorMessage {
                    alertView(text: error, color: .red) {
                        vm.errorMessage = nil
                    }
                }
                if let success = vm.successMessage {
                    alertView(text: success, color: .green) {
                        vm.successMessage = nil
                    }
                }

                if vm.isLoading {
                    Spacer()
                    ProgressView("Chargement...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {

                            // 1. Vendeur
                            sectionCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Sélection du Vendeur")
                                        .font(.headline)
                                    Picker("Vendeur", selection: $vm.selectedVendeurId) {
                                        Text("-- Sélectionnez un vendeur --").tag(Int?.none)
                                        ForEach(vm.vendeurs, id: \.id) { v in
                                            Text("\(v.nom) (ID: \(v.id))").tag(v.id as Int?)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                            }

                            // 2. Session active
                            if let session = vm.sessionActive {
                                sectionCard(color: .green.opacity(0.1)) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Session Active : \(session.nom ?? "Sans nom")")
                                            .font(.headline)
                                        Text("Frais de dépôt : \(session.fraisDepot, format: .number) \(session.modeFraisDepot == "pourcentage" ? "%" : "€")")
                                        Text("Commission : \(session.commissionRate, format: .number)%")
                                    }
                                }
                            } else {
                                sectionCard {
                                    Text("Aucune session active")
                                        .foregroundColor(.red)
                                }
                            }

                            // 3. Recherche & filtre
                            sectionCard {
                                VStack(alignment: .leading, spacing: 8) {
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
                            }

                            // 4. Grille de jeux + pagination
                            sectionCard {
                                let pagedGames = vm.paginatedCatalog()
                                if pagedGames.isEmpty {
                                    Text("Aucun jeu trouvé.")
                                        .foregroundColor(.gray)
                                        .padding()
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
                                    .padding(.bottom, 10)

                                    HStack {
                                        Button {
                                            if vm.currentPage > 0 { vm.currentPage -= 1 }
                                        } label: {
                                            Label("Préc", systemImage: "chevron.left")
                                        }
                                        .disabled(vm.currentPage == 0)

                                        Spacer()
                                        Text("Page \(vm.currentPage + 1) / \(max(vm.totalPages, 1))")
                                        Spacer()

                                        Button {
                                            if vm.currentPage < vm.totalPages - 1 { vm.currentPage += 1 }
                                        } label: {
                                            Label("Suiv", systemImage: "chevron.right")
                                        }
                                        .disabled(vm.currentPage >= vm.totalPages - 1)
                                    }
                                    .font(.footnote)
                                    .padding(.top, 4)
                                }
                            }

                            // 5. Formulaire d'ajout
                            if let selected = vm.selectedGame {
                                addGameForm(selectedGame: selected)
                            }

                            // 6. Jeux à déposer
                            if !vm.depositItems.isEmpty {
                                sectionCard(color: .yellow.opacity(0.1)) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Jeux à déposer").font(.headline)
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
                                    }
                                }
                            }

                            // 7. Résumé
                            if vm.sessionActive != nil {
                                sectionCard {
                                    VStack(alignment: .leading) {
                                        Text("Résumé").font(.headline)
                                        Text("Frais totaux : \(vm.calculateTotalDepositFees(), format: .number)€")
                                        Text("Remise totale : \(vm.calculateTotalRemise(), format: .number)€")
                                        Text("Nb d'items : \(vm.depositItems.count)")
                                    }
                                }
                            }

                            // 8. Bouton valider
                            Button("✅ Valider le dépôt") {
                                if vm.validateDeposit() {
                                    showConfirmDialog = true
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(vm.depositItems.isEmpty || vm.selectedVendeurId == nil ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .disabled(vm.depositItems.isEmpty || vm.selectedVendeurId == nil)
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationTitle("Dépôt de Jeux")
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
        }
    }

    // MARK: - Alert
    private func alertView(text: String, color: Color, onClose: @escaping () -> Void) -> some View {
        HStack {
            Text(text).foregroundColor(color)
            Spacer()
            Button("X", action: onClose)
        }
        .padding()
        .background(color.opacity(0.1))
    }

    // MARK: - Card wrapper
    private func sectionCard<Content: View>(color: Color = Color(.systemGray6), @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8, content: content)
            .padding()
            .background(color)
            .cornerRadius(10)
            .padding(.horizontal)
    }

    // MARK: - Formulaire d'ajout
    @ViewBuilder
    private func addGameForm(selectedGame: Jeu) -> some View {
        sectionCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ajouter \"\(selectedGame.nom)\" au dépôt")
                    .font(.headline)

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

                VStack(alignment: .leading) {
                    Text("Remise : \(vm.tempRemise, format: .number)€")
                    Slider(value: $vm.tempRemise, in: 0...50, step: 1)
                }

                Button("Ajouter au dépôt") {
                    vm.addGameToDeposit()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
        }
    }
}
