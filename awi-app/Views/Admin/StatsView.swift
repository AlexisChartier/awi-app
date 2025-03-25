//
//  StatsView.swift
//  awi-app
//
//  Created by etud on 19/03/2025.
//
import SwiftUI
import Charts

struct StatsView: View {
    @StateObject private var vm = StatsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 🗂 Sélecteur de session
                    Picker("Session", selection: $vm.selectedSessionId) {
                        Text("Sélectionner une session").tag(Int?.none)
                        ForEach(vm.sessions, id: \.id) { session in
                            Text(session.nom!).tag(session.id as Int?)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.horizontal)

                    // 📊 Statistiques principales
                    if let stats = vm.stats {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                            StatCardView(title: "🎮 Dépôts", value: "\(stats.totalGamesDeposited)")
                            StatCardView(title: "✅ Dépôts vendus", value: "\(stats.depotsVendus.count)")
                            StatCardView(title: "🧍‍♂️ Vendeurs actifs", value: "\(vm.additionalStats.activeVendorsCount)")
                            StatCardView(title: "🛒 Ventes", value: "\(vm.additionalStats.numberOfSales)")
                            StatCardView(title: "💶 Total ventes", value: "\(String(format: "%.2f", stats.totalSalesAmount)) €")
                            StatCardView(title: "💰 Trésorerie", value: "\(String(format:"%.2f", vm.additionalStats.treasuryTotal)) €")
                            StatCardView(title: "📉 Commissions", value: "\(String(format:"%.2f",stats.totalCommissions)) €")
                            StatCardView(title: "📥 Frais dépôt", value: "\(String(format:"%.2f",stats.totalDepositFees)) €")
                            StatCardView(title: "📈 Taux de vente", value: "\(String(format:"%.2f",vm.additionalStats.salesRate))%")
                            StatCardView(title: "🧾 Valeur moyenne vente", value: "\(String(format:"%.2f",vm.additionalStats.averageSaleValue)) €")
                            StatCardView(title: "📦 Moyenne dépôt vendu", value: "\(String(format:"%.2f",vm.additionalStats.averageDepotValue)) €")
                        }
                        .padding(.horizontal)
                    }

                    // 🥧 Camembert : Répartition par vendeur
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📌 Répartition des dépôts par vendeur")
                            .font(.headline)
                            .padding(.bottom, 4)

                        HStack {
                            Picker("Type", selection: $vm.pieChartType) {
                                Text("Tous").tag(StatsViewModel.PieChartType.all)
                                Text("Vendus").tag(StatsViewModel.PieChartType.sold)
                            }
                            .pickerStyle(.segmented)

                            Picker("Critère", selection: $vm.pieMetric) {
                                Text("Nombre").tag(StatsViewModel.PieMetric.count)
                                Text("Valeur").tag(StatsViewModel.PieMetric.value)
                            }
                            .pickerStyle(.segmented)
                        }

                        PieChartView(data: vm.generatePieChartData())
                            .frame(height: 300)
                    }
                    .padding(.horizontal)
                }

                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
        .navigationTitle("Statistiques")
        .onAppear {
            vm.loadSessions()
        }
        .onChange(of: vm.selectedSessionId) {
            if let id = vm.selectedSessionId {
                vm.loadStats(for: id)
            }
        }
    }
}

struct StatCardView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3.bold())
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}


struct PieChartView: View {
    var data: [PieSliceData]

    var body: some View {
        Chart {
            ForEach(data) { slice in
                SectorMark(
                    angle: .value("Valeur", slice.value),
                    innerRadius: .ratio(0.5),
                    angularInset: 1
                )
                .foregroundStyle(by: .value("Vendeur", slice.label))
            }
        }
        .chartLegend(position: .trailing, spacing: 8)
        .padding()
    }
}



struct ChartDataPoint: Identifiable {
    var id = UUID()
    var label: String
    var value: Double
}

struct PieSliceData: Identifiable {
    var id = UUID()
    var label: String
    var value: Double
}


