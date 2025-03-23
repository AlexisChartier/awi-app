import SwiftUI

struct FinancialView: View {
    @StateObject var vm = FinancialViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                Text("📊 Bilan Financier")
                    .font(.largeTitle.bold())
                    .padding(.top, 20)

                if let err = vm.errorMessage {
                    alertView(text: err, color: .red) {
                        vm.errorMessage = nil
                    }
                }

                if let succ = vm.successMessage {
                    alertView(text: succ, color: .green) {
                        vm.successMessage = nil
                    }
                }

                if vm.loading {
                    Spacer()
                    ProgressView("Chargement des données...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Session Section
                            sectionCard(title: "Générer le bilan d'une session") {
                                Picker("Sélectionner une session", selection: $vm.selectedSession) {
                                    ForEach(vm.sessions, id: \.id) { s in
                                        Text("Session #\(s.nom)").tag(s as Session?)
                                    }
                                }
                                .pickerStyle(.menu)

                                Button("📄 Télécharger le bilan de session") {
                                    vm.generateSessionReport()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                                .disabled(vm.selectedSession == nil)
                            }

                            // Vendeur Section
                            sectionCard(title: "Générer le bilan d'un vendeur") {
                                Picker("Sélectionner un vendeur", selection: $vm.selectedVendeurId) {
                                    Text("-- Choisissez un vendeur --").tag(Optional<Int>.none)
                                    ForEach(vm.vendeurs, id: \.id) { v in
                                        Text("\(v.nom) (#\(v.id))").tag(Optional<Int>(v.id!))
                                    }
                                }
                                .pickerStyle(.menu)

                                Button("📄 Télécharger le bilan vendeur") {
                                    vm.generateVendorReport()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                .disabled(vm.selectedSession == nil || vm.selectedVendeurId == nil)
                            }
                        }
                        .padding(.top, 20)
                    }
                }

                Spacer()
            }
            .padding()
            .onAppear {
                vm.loadData()
            }
        }
    }

    // MARK: - Alert View
    private func alertView(text: String, color: Color, onClose: @escaping () -> Void) -> some View {
        HStack {
            Text(text).foregroundColor(color)
            Spacer()
            Button("X", action: onClose)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    // MARK: - Section Card
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
