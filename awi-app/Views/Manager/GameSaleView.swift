import SwiftUI

struct GameSaleView: View {
    @StateObject var vm = GameSaleViewModel()
    @State private var showCartSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 🧾 Messages
                if let err = vm.errorMessage {
                    Text(err).foregroundColor(.red).padding()
                }
                if let succ = vm.successMessage {
                    Text(succ).foregroundColor(.green).padding()
                }

                // 🔍 Filtres
                HStack(spacing: 12) {
                    TextField("🎲 Jeu", text: $vm.filterGameName)
                        .textFieldStyle(.roundedBorder)
                    TextField("📦 Code-barres", text: $vm.filterBarcode)
                        .textFieldStyle(.roundedBorder)

                    Spacer()

                    Button {
                        showCartSheet = true
                    } label: {
                        Label("Voir Panier", systemImage: "cart")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)

                if vm.loading {
                    Spacer()
                    ProgressView("Chargement...")
                    Spacer()
                } else {
                    // 🎮 Liste des produits en vente
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            ForEach(vm.sortedDepots, id: \.depot_jeu_id) { depot in
                                let game = vm.allGames.first(where: { $0.id == depot.jeu_id })
                                let vendor = vm.allVendors.first(where: { $0.id == depot.vendeur_id })

                                ProductCardView(
                                    depot: depot,
                                    gameName: game?.nom ?? "Jeu inconnu",
                                    vendorName: vendor?.nom ?? "Vendeur inconnu",
                                    imageUrl: game?.image ?? "",
                                    onAddToCart: { vm.addToCart(depot) },
                                    onGenerateBarcode: {
                                        vm.generateBarcode(depot)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }

                // 🧾 Bouton bas de page
                if !vm.cart.isEmpty {
                    Button {
                        showCartSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "cart.fill")
                            Text("Finaliser la vente (\(vm.cart.count) articles - \(vm.totalSalePrice, format: .number)€)")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Gestion des Ventes")
            .onAppear {
                vm.loadData()
            }
            .sheet(isPresented: $showCartSheet) {
                CartSheet(vm: vm)
            }
        }
    }
}



// Sous-vue d’exemple pour sélectionner acheteur / finaliser
struct BuyerSelectionSheet: View {
    @ObservedObject var vm: GameSaleViewModel
    @State private var localBuyerId: Int?
    @State private var invoiceNeeded: Bool = false

    var body: some View {
        VStack {
            Text("Acheteur / Facturation").font(.headline)
            Toggle("Besoin facture ?", isOn: $invoiceNeeded)
            Picker("Acheteur", selection: $localBuyerId) {
                Text("-- Aucun --").tag(Optional<Int>.none)
                // imagine un AcheteurService ou un simple test
                // ...
            }
            Button("Confirmer vente") {
                vm.needInvoice = invoiceNeeded
                vm.selectedBuyerId = localBuyerId
                vm.confirmSale()
            }
            Button("Annuler") {
                vm.showBuyerDialog = false
            }
        }
        .padding()
    }
}

struct CartSheet: View {
    @ObservedObject var vm: GameSaleViewModel

    var body: some View {
        NavigationStack {
            VStack {
                Text("🛒 Panier")
                    .font(.title2.bold())
                    .padding(.top)

                if vm.cart.isEmpty {
                    Text("Aucun article")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(vm.cart, id: \.depot_jeu_id) { item in
                            let game = vm.allGames.first { $0.id == item.jeu_id }
                            HStack {
                                Text(game?.nom ?? "Jeu")
                                Spacer()
                                Text("\(item.prix_vente, format: .number)€")
                            }
                            .onTapGesture {
                                vm.removeFromCart(item)
                            }
                        }
                    }

                    Text("Total: \(vm.totalSalePrice, format: .number)€")
                        .bold()
                        .padding(.top)

                    Button("💰 Finaliser la vente") {
                        vm.finalizeSale()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }

                Spacer()
            }
            .padding()
        }
    }
}
