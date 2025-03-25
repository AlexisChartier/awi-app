//
//  SaleView.swift
//  awi-app
//
//  Created by etud on 19/03/2025.
//
import SwiftUI

struct SaleView: View {
    @StateObject var vm = SaleViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                
                if let err = vm.errorMessage {
                    Text(err)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // Bouton "Nouvelle vente" uniquement si la session est active
                if let selectedSession = vm.sessions.first(where: { $0.id == vm.selectedSessionId }),
                   selectedSession.statut == "active" {
                    NavigationLink(destination: GameSaleView()) {
                        Label("Effectuer une Vente", systemImage: "plus")
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }

                // Filtres & tri
                HStack(spacing: 12) {
                    Picker("Session", selection: $vm.selectedSessionId) {
                        Text("-- Choisir --").tag(Optional<Int>.none)
                        ForEach(vm.sessions, id: \.id) { s in
                            Text(s.nom ?? "Session #\(s.id)").tag(Optional<Int>(s.id))
                        }
                    }
                    .onChange(of: vm.selectedSessionId) {vm.loadSales() }
                    .pickerStyle(.menu)

                    Spacer()

                    Menu("Trier") {
                        Button("Par Date") { vm.sortBy(.date) }
                        Button("Par Montant") { vm.sortBy(.montant) }
                    }
                }
                .padding(.horizontal)

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

                        // Pagination
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
            .navigationTitle("Ventes")
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

//  Carte d’une vente
struct SaleCardView: View {
    let sale: VenteRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LinearGradient(
                colors: [Color.cyan, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
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

// Détail d'une vente
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
                    ForEach(vm.saleDetails, id: \.depot_jeu_id) { detail in
                        HStack(alignment: .top, spacing: 12) {
                            if let game = vm.gameForDepotId(detail.depot_jeu_id) {
                                AsyncImage(url: URL(string: game.image ?? "")) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFill()
                                    } else {
                                        Color.gray
                                    }
                                }
                                .frame(width: 40, height: 40)
                                .cornerRadius(5)
                            }

                            VStack(alignment: .leading) {
                                Text(vm.gameForDepotId(detail.depot_jeu_id)?.nom ?? "Jeu inconnu")
                                    .bold()
                                Text("Prix : \(detail.prix_vente ?? 0.0, format: .currency(code: "EUR"))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
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
