import SwiftUI

struct VendorDashboardView: View {
    let vendor: Vendeur

    var body: some View {
        VStack(spacing: 20) {
            Text("Dashboard du Vendeur")
                .font(.largeTitle)
                .padding(.top, 40)

            Text("ID: \(vendor.id)")
            Text("Nom: \(vendor.nom)")
            Text("Email: \(vendor.email)")
            Text("Téléphone: \(vendor.telephone)")

            // On peut imaginer des stats, un graphique, etc.
            Spacer()
        }
        .navigationTitle("Dashboard \(vendor.nom)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
