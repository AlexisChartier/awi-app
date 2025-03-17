import SwiftUI

struct ManagerTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DepositsView()
            }
            .tabItem {
                Label("Dépôts", systemImage: "tray.and.arrow.down.fill")
            }

            NavigationStack {
                SaleView()
            }
            .tabItem {
                Label("Ventes", systemImage: "cart.fill")
            }

            NavigationStack {
                VendorsView()
            }
            .tabItem {
                Label("Vendeurs", systemImage: "person.crop.rectangle.stack")
            }

            NavigationStack {
                CatalogView()
            }
            .tabItem {
                Label("Catalogue", systemImage: "book.fill")
            }

            NavigationStack {
                FinancialView()
            }
            .tabItem {
                Label("Bilan", systemImage: "doc.text.fill")
            }
        }
    }
}
