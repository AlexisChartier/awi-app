import SwiftUI
import QuickLook

struct FinancialView: View {
    @StateObject var vm = FinancialViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("📊 Bilan Financier")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top)

                // 🔔 Alertes
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

                // 🔄 Chargement
                if vm.loading {
                    Spacer()
                    ProgressView("Chargement des données...")
                        .progressViewStyle(CircularProgressViewStyle())
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            sectionCard(title: "📅 Bilan par Session") {
                                Picker("Sélectionner une session", selection: $vm.selectedSession) {
                                    ForEach(vm.sessions, id: \.id) { s in
                                        Text("Session #\(s.nom)").tag(s as Session?)
                                    }
                                }
                                .pickerStyle(.menu)

                                Button {
                                    vm.generateSessionReport()
                                } label: {
                                    Label("Télécharger le bilan", systemImage: "arrow.down.doc")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(vm.selectedSession == nil)
                            }

                            sectionCard(title: "👤 Bilan par Vendeur") {
                                Picker("Sélectionner un vendeur", selection: $vm.selectedVendeurId) {
                                    Text("-- Choisissez un vendeur --").tag(Optional<Int>.none)
                                    ForEach(vm.vendeurs, id: \.id) { v in
                                        Text("\(v.nom) (#\(v.id))").tag(v.id!)
                                    }
                                }
                                .pickerStyle(.menu)

                                Button {
                                    vm.generateVendorReport()
                                } label: {
                                    Label("Télécharger le bilan", systemImage: "arrow.down.doc")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                .disabled(vm.selectedSession == nil || vm.selectedVendeurId == nil)
                            }
                        }
                        .padding(.top)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Bilan Financier")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                vm.loadData()
            }
            .sheet(item: $vm.previewURL) { identifiable in
                QuickLookPreview(fileURL: identifiable.url)
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


struct QuickLookPreview: UIViewControllerRepresentable {
    let fileURL: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(fileURL: fileURL)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let fileURL: URL
        init(fileURL: URL) {
            self.fileURL = fileURL
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return fileURL as QLPreviewItem
        }
    }
}

