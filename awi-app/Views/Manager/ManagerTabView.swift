//
//  ManagerTabView.swift
//  awi-app
//
//  Created by etud on 19/03/2025.
//
import SwiftUI

struct ManagerTabView: View {
    @EnvironmentObject var vm: AuthViewModel

    init() {
        UITabBar.appearance().backgroundColor = UIColor.systemGroupedBackground
    }

    var body: some View {
        TabView {
            NavigationStack {
                DepositsView()
                    .navigationTitle("Dépôts")
            }
            .tabItem {
                Label("Dépôts", systemImage: "tray.and.arrow.down.fill")
            }

            NavigationStack {
                SaleView()
                    .navigationTitle("Ventes")
            }
            .tabItem {
                Label("Ventes", systemImage: "cart.fill")
            }

            NavigationStack {
                VendorsView()
                    .navigationTitle("Vendeurs")
            }
            .tabItem {
                Label("Comptes", systemImage: "person.3.fill")
            }

            NavigationStack {
                CatalogView()
                    .navigationTitle("Catalogue")
            }
            .tabItem {
                Label("Catalogue", systemImage: "book.fill")
            }

            NavigationStack {
                FinancialView()
                    .navigationTitle("Bilan Financier")
            }
            .tabItem {
                Label("Bilan", systemImage: "doc.text.fill")
            }

            NavigationStack {
                SettingsView(vm: vm)
            }
            .tabItem {
                Label("Déconnexion", systemImage: "door")
            }
        }
        .accentColor(.indigo)
    }
}

struct SettingsView: View {
    @ObservedObject var vm: AuthViewModel

    var body: some View {
        Form {
            Section(header: Text("Session")) {
                Button(role: .destructive) {
                    vm.logoutAction()
                } label: {
                    Label("Se déconnecter", systemImage: "rectangle.portrait.and.arrow.forward")
                }
            }
        }
        .navigationTitle("Paramètres")
    }
}



