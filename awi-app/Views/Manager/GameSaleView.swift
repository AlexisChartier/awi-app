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


struct BuyerSelectionSheet: View {
    @ObservedObject var vm: GameSaleViewModel

    // Indique si on doit émettre une facture
    @State private var invoiceNeeded: Bool = false

    // Recherche par email
    @State private var emailSearch = ""
    @State private var searchResults: [Acheteur] = []

    // Champs de création d’un nouvel acheteur
    @State private var nom = ""
    @State private var email = ""
    @State private var tel = ""
    @State private var adresse = ""

    var body: some View {
        NavigationStack {
            Form {
                // FACTURATION
                Section(header: Text("Facturation")) {
                    Toggle("L’acheteur souhaite une facture", isOn: $invoiceNeeded)
                }

                if invoiceNeeded {
                    // 🔍 RECHERCHE
                    Section(header: Text("Recherche acheteur")) {
                        HStack {
                            TextField("Email", text: $emailSearch)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)

                            Button("🔍 Rechercher") {
                                Task {
                                    let results = await vm.searchBuyer(email: emailSearch)
                                    searchResults = results
                                }
                            }
                        }

                        // Picker lié à selectedBuyerId
                        Picker("Sélectionner acheteur", selection: buyerPickerBinding) {
                            Text("-- Aucun --").tag(-1)
                            // <-- ForEach sur [Acheteur], maintenant Identifiable
                            ForEach(searchResults) { buyer in
                                Text("\(buyer.nom) (\(buyer.email ?? "N/A"))").tag(buyer.id) // l'id calculé dans Acheteur
                            }
                        }
                    }

                    // ➕ CRÉATION
                    Section(header: Text("Créer un acheteur")) {
                        TextField("Nom", text: $nom)
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        TextField("Téléphone", text: $tel)
                            .keyboardType(.phonePad)
                        TextField("Adresse", text: $adresse)

                        Button("Créer Acheteur") {
                            Task {
                                if let newBuyerId = await vm.createBuyer(nom: nom,
                                                                        email: email,
                                                                        tel: tel,
                                                                        adresse: adresse) {
                                    vm.selectedBuyerId = newBuyerId
                                    // On réinitialise les champs
                                    emailSearch = ""
                                    searchResults = []
                                    nom = ""
                                    email = ""
                                    tel = ""
                                    adresse = ""
                                }
                            }
                        }
                    }
                }

                // ✅ CONFIRM / ❌ ANNULER
                Section {
                    Button("✅ Confirmer vente") {
                        vm.needInvoice = invoiceNeeded
                        vm.confirmSale()
                    }
                    .disabled(invoiceNeeded && vm.selectedBuyerId == nil)

                    Button("❌ Annuler") {
                        vm.showBuyerDialog = false
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Facture & Acheteur")
        }
    }

    /// Binding intermédiaire pour le Picker des acheteurs
    private var buyerPickerBinding: Binding<Int> {
        Binding(
            get: { vm.selectedBuyerId ?? -1 },
            set: { newValue in
                vm.selectedBuyerId = (newValue == -1) ? nil : newValue
            }
        )
    }
}





struct CartSheet: View {
    @ObservedObject var vm: GameSaleViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Text("🛒 Panier")
                    .font(.largeTitle.bold())
                    .padding(.top)

                if vm.cart.isEmpty {
                    Spacer()
                    Text("Aucun article dans le panier")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                } else {
                    List {
                        ForEach(vm.cart, id: \.depot_jeu_id) { item in
                            let game = vm.allGames.first { $0.id == item.jeu_id }

                            HStack(spacing: 12) {
                                AsyncImage(url: URL(string: game?.image ?? "")) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFill()
                                    } else {
                                        Color.gray
                                    }
                                }
                                .frame(width: 60, height: 60)
                                .cornerRadius(8)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(game?.nom ?? "Jeu inconnu")
                                        .font(.headline)
                                    Text("Prix : \(item.prix_vente, format: .number)€")
                                        .font(.subheadline)
                                    if let barcode = item.identifiant_unique {
                                        Text("Code : \(barcode)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                Button {
                                    vm.removeFromCart(item)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .listStyle(.plain)

                    Text("Total: \(vm.totalSalePrice, specifier: "%.2f")€")
                        .font(.title2.bold())
                        .padding(.top)

                    Button("💰 Finaliser la vente") {
                        vm.finalizeSale()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
            }
            .padding()
            .sheet(isPresented: $vm.showBuyerDialog) {
                BuyerSelectionSheet(vm: vm)
            }
        }
    }
}
