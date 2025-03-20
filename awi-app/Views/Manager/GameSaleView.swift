import SwiftUI

struct GameSaleView: View {
    @StateObject var vm = GameSaleViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                if let err = vm.errorMessage {
                    Text(err).foregroundColor(.red)
                }
                if let succ = vm.successMessage {
                    Text(succ).foregroundColor(.green)
                }

                if vm.loading {
                    ProgressView("Chargement...")
                } else {
                    // Filtre
                    HStack {
                        TextField("Filtrer jeu", text: $vm.filterGameName)
                            .textFieldStyle(.roundedBorder)
                        TextField("Filtrer code-barres", text: $vm.filterBarcode)
                            .textFieldStyle(.roundedBorder)
                        Spacer()
                        Button("Effectuer la vente") {
                            vm.finalizeSale()
                        }
                    }
                    .padding()

                    HStack {
                        // liste “en vente”
                        ScrollView {
                            let depots = vm.sortedDepots
                            ForEach(depots, id: \.id) { depot in
                                // un composant row
                                SaleProductRow(vm: vm, depot: depot)
                            }
                        }
                        .frame(width: 300)

                        // Panier
                        VStack {
                            Text("Panier").font(.headline)
                            if vm.cart.isEmpty {
                                Text("Panier vide")
                            } else {
                                List {
                                    ForEach(vm.cart, id: \.id) { c in
                                        HStack {
                                            Text("Jeu #\(c.jeu_id)")
                                            Spacer()
                                            Text("\(c.prix_vente, format:.number)€")
                                        }
                                        .onTapGesture {
                                            vm.removeFromCart(c)
                                        }
                                    }
                                }
                                Text("Total: \(vm.totalSalePrice, format:.number)€")
                            }
                        }
                        .frame(maxWidth:.infinity)
                    }
                }
            }
            .navigationTitle("Gestion des Ventes")
            .onAppear {
                vm.loadData()
            }
            .sheet(isPresented: $vm.showBuyerDialog) {
                BuyerSelectionSheet(vm: vm)
            }
        }
    }
}

struct SaleProductRow: View {
    @ObservedObject var vm: GameSaleViewModel
    let depot: DepotJeu

    var body: some View {
        HStack {
            Text("D#\(depot.id ?? -1) / J#\(depot.jeu_id)")
            Spacer()
            Text("\(depot.prix_vente, format:.number) €")
        }
        .contentShape(Rectangle()) // so we can tap
        .onTapGesture {
            vm.addToCart(depot)
        }
        .contextMenu {
            Button("Générer code-barres") {
                vm.generateBarcode(depot)
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
