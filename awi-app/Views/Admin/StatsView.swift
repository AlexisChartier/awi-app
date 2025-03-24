import SwiftUI
import Charts

struct StatsView: View {
    @StateObject private var vm = StatsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 🧠 Titre principal
                    Text("Tableau de bord Administrateur")
                        .font(.largeTitle.bold())
                        .padding(.top, 10)

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
                        .padding(.bottom)
                    }

                    // 📈 Graphique Line Chart
                    if let lineData = vm.salesOverTimeData {
                        AdminLineChart(data: lineData, maxValue: vm.stats?.totalSalesAmount)
                            .frame(height: 300)
                            .padding()
                    }

                    // 📊 Graphique Bar Chart
                    if let maxData = vm.maxSaleOverTimeData {
                        AdminBarChart(data: maxData)
                            .frame(height: 300)
                            .padding()
                    }

                    // 🥧 Camembert : Répartition par vendeur
                    VStack(alignment: .leading) {
                        Text("Répartition des dépôts par vendeur")
                            .font(.headline)
                        Picker("Type", selection: $vm.pieChartType) {
                            Text("Tous").tag(StatsViewModel.PieChartType.all)
                            Text("Vendus").tag(StatsViewModel.PieChartType.sold)
                        }.pickerStyle(.segmented)

                        Picker("Critère", selection: $vm.pieMetric) {
                            Text("Nombre").tag(StatsViewModel.PieMetric.count)
                            Text("Valeur").tag(StatsViewModel.PieMetric.value)
                        }.pickerStyle(.segmented)

                        PieChartView(data: vm.generatePieChartData())
                            .frame(height: 300)
                    }
                    .padding()
                }

                // 💬 Message d’erreur
                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Statistiques")
        }
        .onAppear {
            vm.loadSessions()
        }
        .onChange(of: vm.selectedSessionId) { newId in
            if let id = newId {
                vm.loadStats(for: id)
            }
        }
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


struct StatCardView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}


struct AdminLineChart: View {
    var data: [ChartDataPoint]
    var maxValue: Double?

    var body: some View {
        Chart {
            ForEach(data) { point in
                LineMark(
                    x: .value("Date", point.label),
                    y: .value("Montant", point.value)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(.blue)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXScale(range: .plotDimension(padding: 20))
        .chartYScale(domain: .automatic(includesZero: true))
        .padding()
    }
}


struct AdminBarChart: View {
    var data: [ChartDataPoint]

    var body: some View {
        Chart {
            ForEach(data) { point in
                BarMark(
                    x: .value("Date", point.label),
                    y: .value("Max Vente", point.value)
                )
                .foregroundStyle(.green)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXScale(range: .plotDimension(padding: 20))
        .chartYScale(domain: .automatic(includesZero: true))
        .padding()
    }
}


struct PieChartView: View {
    var data: [PieSliceData]

    var body: some View {
        Chart {
            ForEach(data) { slice in
                SectorMark(
                    angle: .value("Value", slice.value),
                    innerRadius: .ratio(0.5),
                    angularInset: 1
                )
                .foregroundStyle(by: .value("Label", slice.label))
                .annotation(position: .overlay, alignment: .center) {
                    Text(slice.label)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(-90))
                }
            }
        }
        .chartLegend(.visible)
        .padding()
    }
}

