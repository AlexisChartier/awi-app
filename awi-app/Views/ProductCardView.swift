import SwiftUI

struct ProductCardView: View {
    let depot: DepotJeuRequest
    let gameName: String
    let vendorName: String
    let imageUrl: String
    let onAddToCart: () -> Void
    let onGenerateBarcode: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(gameName)
                .font(.headline)
                .lineLimit(1)

            Text("Vendeur: \(vendorName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)

            AsyncImage(url: URL(string: imageUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 120)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 140)
                        .clipped()
                        .cornerRadius(10)
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }

            if let barcode = depot.identifiant_unique {
                Text("Code-barres: \(barcode)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Text("État: \(depot.etat)")
                .font(.caption)

            if let detail = depot.detail_etat {
                Text(detail)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            HStack {
                Button(action: onAddToCart) {
                    Label("Ajouter", systemImage: "cart.badge.plus")
                }
                .buttonStyle(.borderedProminent)

                Spacer()

                Text("\(depot.prix_vente, format: .number)€")
                    .font(.subheadline)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .frame(maxWidth: 200) // ✅ Contraint la largeur
        .fixedSize(horizontal: false, vertical: true)
    }
}
