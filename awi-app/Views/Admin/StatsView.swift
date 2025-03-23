import SwiftUI

struct StatsView: View {
    @StateObject var vm = StatsViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                if let e = vm.errorMessage {
                    Text(e).foregroundColor(.red)
                }
                Picker("Session", selection: $vm.selectedSessionId) {
                    Text("-- Choisir --").tag(Optional<Int>.none)
                    ForEach(vm.sessions, id:\.id) { s in
                        Text("Session #\(s.nom ?? "")").tag(Optional<Int>(s.id))
                    }
                }
                .onChange(of: vm.selectedSessionId) { newVal in
                    vm.loadStats()
                }
                .pickerStyle(.menu)

                if vm.loading {
                    ProgressView("Chargement...")
                } else {
                    // Grille d'indicateurs
                    ScrollView {
                        VStack(alignment:.leading, spacing: 20) {
                            Text("Vendeurs actifs: \(vm.activeVendorsCount)")
                            Text("Nb dépôts: \(vm.totalGamesDeposited)")
                            Text("Nb dépôts vendus: ??")
                            Text("Nb ventes: \(vm.numberOfSales)")
                            Text("Montant dû vendeurs: \(vm.amountDueToVendors, format:.number)€")
                            Text("Trésorerie: \(vm.treasuryTotal, format:.number)€")
                            Text("Frais dépôt: \(vm.totalDepositFees, format:.number)€")
                            Text("Commissions: \(vm.totalCommissions, format:.number)€")
                            // etc.
                        }
                        .padding()

                        // Graph line => “salesOverTime”
                        if vm.salesOverTime.isEmpty {
                            Text("Pas de data pour CA cumulatif").foregroundColor(.gray)
                        } else {
                            AdminLineChart(points: vm.salesOverTime)
                                .frame(height:300)
                        }
                        // Graph bar => “maxSaleOverTime”
                        if vm.maxSaleOverTime.isEmpty {
                            Text("Pas de data pour max sale").foregroundColor(.gray)
                        } else {
                            AdminBarChart(points: vm.maxSaleOverTime)
                                .frame(height:300)
                        }
                        // Camembert => “allDepots” / par “vendors” ...
                        // ...
                    }
                }
            }
            .navigationTitle("Stats Administrateur")
            .onAppear {
                vm.loadSessions()
            }
        }
    }
}

// placeholders
struct AdminLineChart: View {
    let points: [StatsViewModel.SomePoint]
    var body: some View {
        Text("LineChart - Not implemented")
    }
}
struct AdminBarChart: View {
    let points: [StatsViewModel.SomePoint]
    var body: some View {
        Text("BarChart - Not implemented")
    }
}
