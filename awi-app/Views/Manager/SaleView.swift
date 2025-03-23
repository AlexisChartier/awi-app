import SwiftUI

struct SaleView: View {
    @StateObject var vm = SaleViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // ⚠️ Message d’erreur
                if let err = vm.errorMessage {
                    Text(err)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // 🔁 Bouton vers nouvelle vente
                NavigationLink(destination: GameSaleView()) {
                    Label("Effectuer une Vente", systemImage: "plus")
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                // 🎛️ Filtres & tri
                HStack(spacing: 12) {
                    Picker("Session", selection: $vm.selectedSessionId) {
                        Text("-- Choisir --").tag(Optional<Int>.none)
                        ForEach(vm.sessions, id: \.id) { s in
                            Text(s.nom!).tag(Optional<Int>(s.id))
                        }
                    }
                    .onChange(of: vm.selectedSessionId) { _ in vm.loadSales() }
                    .pickerStyle(.menu)

                    Spacer()

                    Menu("Trier") {
                        Button("Par Date") { vm.sortBy(.date) }
                        Button("Par Montant") { vm.sortBy(.montant) }
                    }
                }
                .padding(.horizontal)

                // ⏳ Chargement
                if vm.loading {
                    Spacer()
                    ProgressView("Chargement ventes...")
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(vm.currentSales, id: \.vente_id) { sale in
                                SaleCardView(sale: sale)
                                    .onTapGesture {
                                        vm.openSaleDetail(sale)
                                    }
                                    .padding(.horizontal)
                            }
                        }

                        // 📄 Pagination
                        HStack {
                            Button("◀︎") {
                                vm.goToPage(vm.currentPage - 1)
                            }.disabled(vm.currentPage <= 1)

                            Spacer()

                            Text("Page \(vm.currentPage)/\(vm.totalPages)")
                                .font(.footnote)

                            Spacer()

                            Button("▶︎") {
                                vm.goToPage(vm.currentPage + 1)
                            }.disabled(vm.currentPage >= vm.totalPages)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Consultation des Ventes")
            .onAppear {
                vm.loadInitial()
            }
            .sheet(isPresented: $vm.showDetailModal) {
                if let sale = vm.selectedSale {
                    SaleDetailSheet(vm: vm, sale: sale)
                }
            }
        }
    }
}

struct SaleCardView: View {
    let sale: VenteRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("🧾 Vente #\(sale.vente_id ?? -1)")
                .font(.headline)

            HStack {
                Text("Montant : \(sale.montant_total, format: .currency(code: "EUR"))")
                Spacer()
                if let dv = sale.date_vente {
                    Text("📅 \(dv)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.2), radius: 2)
    }
}

// Sous-vue : rangée d'une vente
struct SaleRowView: View {
    let sale: VenteRequest  // Ajustez selon votre type

    var body: some View {
        HStack {
            // On décompose l'expression
            let sid = sale.vente_id ?? -1
            Text("Vente #\(sid)")

            Spacer()

            Text("\(sale.montant_total, format: .number)€")

            if let dv = sale.date_vente {
                Text(dv)
            }
        }
    }
}


struct SaleDetailSheet: View {
    @ObservedObject var vm: SaleViewModel
    let sale: VenteRequest

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("🧾 Vente #\(sale.vente_id ?? -1)")
                    .font(.title2.bold())

                if let buyer = vm.buyer {
                    Text("👤 Acheteur : \(buyer.nom) (#\(buyer.id))")
                        .padding(.bottom, 6)
                } else if sale.acheteur_id != nil {
                    ProgressView("Chargement acheteur...")
                } else {
                    Text("Aucun acheteur associé.")
                        .italic()
                }

                Text("📦 Articles vendus :")
                    .font(.headline)

                List {
                    ForEach(vm.saleDetails, id: \.vente_id) { detail in
                        let depotId = detail.depot_jeu_id ?? -1
                        let price = detail.prix_vente ?? 0.0

                        HStack {
                            Text("Depot #\(depotId)")
                            Spacer()
                            Text("\(price, format: .currency(code: "EUR"))")
                        }
                    }
                }

                Spacer()

                Button("Fermer") {
                    vm.closeDetailModal()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Détail Vente")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
