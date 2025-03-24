//
//  VendorDashboardView.swift
//  awi-app
//
//  Created by etud on 19/03/2025.
//

import SwiftUI

import UIKit


struct VendorDashboardView: View {
    @StateObject var vm: VendorDashboardViewModel
    @Environment(\.dismiss) var dismiss

    /// Pour empêcher plusieurs appels successifs à loadData() si la vue
    /// est reconstruite ou ré-affichée rapidement.
    @State private var didAppear = false

    init(vendor: Vendeur) {
        _vm = StateObject(wrappedValue: VendorDashboardViewModel(vendor: vendor))
    }

    var body: some View {
        NavigationStack {
            if vm.loading {
                // Écran de chargement
                ProgressView("Chargement...")
            } else {
                VStack(spacing: 0) {
                    // zone d'erreur
                    if let error = vm.errorMessage {
                        HStack {
                            Text(error).foregroundColor(.red)
                            Spacer()
                            Button("X") { vm.errorMessage = nil }
                        }
                        .padding()
                    }

                    // Header
                    headerView

                    // Onglets
                    tabBarView

                    // Contenu de l’onglet sélectionné
                    switch vm.tabIndex {
                    case 0: EnVenteListView(vm: vm)
                    case 1: VenduListView(vm: vm)
                    case 2: RetiresListView(vm: vm)
                    default: StatsVendeurView(vm: vm)
                    }
                }
                .onAppear {
                    // Évite d’appeler loadData() plusieurs fois si on revient sur la vue
                    if !didAppear {
                        didAppear = true
                        vm.loadData()
                    }
                }
                .navigationBarBackButtonHidden(true) // ❗️Cacher bouton natif
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Gestion")
                            }
                            .foregroundColor(.white)
                            .font(.body.bold())
                        }
                    }
                }
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tableau de bord Vendeur")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))

            Text(vm.getVendorName(vendeurId: vm.vendor.id))
                .font(.title.bold())
                .foregroundColor(.white)

            Text("Solde : \(vm.stats.solde, format: .number) €")
                .font(.title2.bold())
                .foregroundColor(.yellow)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal)
        .padding(.top, 20) // espace pour encoche + confort
        .padding(.bottom, 20) // plus large pour mieux contenir le texte
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.blue, .purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }







    // MARK: - tabBar
    private var tabBarView: some View {
        HStack(spacing: 0) {
            ForEach(0..<4) { i in
                Button(action: {
                    vm.setTab(index: i)
                }) {
                    let label = ["En Vente","Vendus","Retirés","Stats"][i]
                    Text(label)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(vm.tabIndex == i ? Color(.systemGray6) : Color(.systemGray5))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Sous-vues

/// Onglet "En Vente"
struct EnVenteListView: View {
    @ObservedObject var vm: VendorDashboardViewModel
    // Variables d'état pour présenter la feuille de partage
    @State private var shareURL: URL?
    @State private var showShareSheet = false

    var body: some View {
        VStack {
            if let session = vm.sessionActive {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.blue)
                        Text("Session Active : \(session.nom ?? "Sans nom")")
                            .font(.headline)
                    }

                    Text("Frais de dépôt : \(session.fraisDepot, format: .number)\(session.modeFraisDepot == "fixe" ? "€" : "%")")
                        .font(.subheadline)
                    Text("Commission : \(session.commissionRate, format: .number)%")
                        .font(.subheadline)
                }
                .padding()
                .background(Color(.white))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 10)
            }

            
            List(vm.depotsEnVente, id: \.id) { dv in
                HStack {
                    // Image + nom du jeu
                    let url = vm.getGameImage(jeuId: dv.depot.jeu_id)
                    AsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image.resizable().scaledToFit().frame(width: 40, height: 40)
                        case .failure(_):
                            Image(systemName: "xmark.circle")
                        @unknown default:
                            EmptyView()
                        }
                    }
                    Text(vm.getGameName(jeuId: dv.depot.jeu_id))
                    Text("Prix de vente : \(dv.depot.prix_vente ?? 0, format: .number) €")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    // Bouton : si l'identifiant unique est présent, on propose de télécharger l'étiquette PDF
                    if let _ = dv.identifiantUnique {
                        Button("Télécharger étiquette") {
                            // Récupérer les infos nécessaires
                            let vendorName = vm.getVendorName(vendeurId: dv.depot.vendeur_id)
                            let gameName = vm.getGameName(jeuId: dv.depot.jeu_id)
                            let salePrice = dv.venteJeu?.prix_vente ?? dv.depot.prix_vente
                            
                            // Générer le PDF
                            let pdfData = generateEtiquettePDF(depot: dv, vendorName: vendorName, gameName: gameName, salePrice: salePrice)
                            
                            // Sauvegarder dans un fichier temporaire
                            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("etiquette_\(dv.identifiantUnique ?? "inconnue").pdf")
                            do {
                                try pdfData.write(to: tempURL)
                                shareURL = tempURL
                                showShareSheet = true
                            } catch {
                                print("Erreur écriture PDF: \(error)")
                            }
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button("Générer") {
                            vm.genererIdentifiant(dv.depot)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .listStyle(.plain)
            }
        }
        // Présentation de la feuille de partage si un PDF a été généré
        .sheet(isPresented: $showShareSheet, onDismiss: {
            shareURL = nil
        }) {
            if let shareURL = shareURL {
                ShareSheet(activityItems: [shareURL])
            }
        }
    }
}


/// Onglet "Vendus"
struct VenduListView: View {
    @ObservedObject var vm: VendorDashboardViewModel

    var body: some View {
        List(vm.depotsVendus, id: \.id) { dv in
            HStack {
                let url = vm.getGameImage(jeuId: dv.depot.jeu_id)
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFit().frame(width: 40, height: 40)
                    case .failure(_):
                        Image(systemName: "xmark.circle")
                    @unknown default:
                        EmptyView()
                    }
                }
                VStack(alignment: .leading) {
                    Text(vm.getGameName(jeuId: dv.depot.jeu_id))
                    let price = dv.venteJeu?.prix_vente ?? dv.depot.prix_vente
                    Text("Prix vente: \(price, format: .number) €")
                    if let comm = dv.venteJeu?.commission {
                        Text("Commission: \(comm, format: .number) €")
                            .font(.footnote)
                            .foregroundColor(.white)
                    }
                }
                Spacer()
                if let date = dv.vente?.date_vente {
                    Text(date) // Vous pouvez formater la date
                        .font(.footnote)
                }
            }
            .listStyle(.plain)
        }
    }
}

/// Onglet "Retirés"
struct RetiresListView: View {
    @ObservedObject var vm: VendorDashboardViewModel

    var body: some View {
        List(vm.depotsRetires, id: \.id) { dv in
            HStack {
                let url = vm.getGameImage(jeuId: dv.depot.jeu_id)
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFit().frame(width: 40, height: 40)
                    case .failure(_):
                        Image(systemName: "xmark.circle")
                    @unknown default:
                        EmptyView()
                    }
                }
                VStack(alignment: .leading) {
                    Text(vm.getGameName(jeuId: dv.depot.jeu_id))
                    Text("Prix de vente : \(dv.depot.prix_vente ?? 0, format: .number) €")
                        .font(.subheadline)
                    Text("Statut: Retiré")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Spacer()
                Button("Remettre en vente") {
                    vm.setDepotStatut(dv.depot, newStatut: "en vente")
                }
                .buttonStyle(.bordered)
            }
            .listStyle(.plain)
        }
    }
}

/// Onglet "Stats"
struct StatsVendeurView: View {
    @ObservedObject var vm: VendorDashboardViewModel

    var body: some View {
        VStack(spacing: 16) {
            Text("📊 Statistiques de la Session")
                .font(.title3.bold())
                .padding(.top)


            VStack(spacing: 8) {
                statRow(label: "Dépôts en Vente", value: vm.stats.totalDepotsEnVente)
                statRow(label: "Dépôts Vendus", value: vm.stats.totalDepotsVendus)
                statRow(label: "Dépôts Retirés", value: vm.stats.totalDepotsRetires)
                statRow(label: "Nombre de Ventes", value: vm.stats.totalVentes)
            }
            VStack(spacing: 8) {
                statRowDouble(label: "Total des Ventes", value: vm.stats.montantTotalVentes)
                statRowDouble(label: "Frais Dépôt Payés", value: vm.stats.fraisDepotPayes)
                statRowDouble(label: "Commissions Déduites", value: vm.stats.commissionsDeduites)
                statRowDouble(label: "Gains Nets", value: vm.stats.gainsNets)
                statRowDouble(label: "Solde", value: vm.stats.solde)
            }
            Spacer()
        }
        .padding()
    }

    private func statRow(label: String, value: Int) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(value)")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
    }


    private func statRowDouble(label: String, value: Double) -> some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
            Spacer()
            Text("\(value, format: .number) €")
                .font(.body)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)

    }

}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

private func generateEtiquettePDF(depot: DepotAvecVente, vendorName: String, gameName: String, salePrice: Double) -> Data {
    let pageRect = CGRect(x: 0, y: 0, width: 300, height: 150)
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
    let data = renderer.pdfData { context in
        context.beginPage()
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)]
        let texts = [
            "Identifiant: \(depot.identifiantUnique ?? "N/A")",
            "Vendeur: \(vendorName)",
            "Jeu: \(gameName)",
            "Prix de vente: \(salePrice) €"
        ]
        for (index, text) in texts.enumerated() {
            let point = CGPoint(x: 20, y: CGFloat(20 + index * 30))
            text.draw(at: point, withAttributes: attributes)
        }
    }
    return data
}
