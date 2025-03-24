//
//  ManagerTabView.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//


import SwiftUI

struct ManagerTabView: View {
    @EnvironmentObject var vm:AuthViewModel
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
            NavigationStack{
                SettingsView(vm: vm)
            }
            .tabItem{
                Label("Paramètres", systemImage: "gearshape")
            }
        }
    }
}

struct SettingsView: View {
    @ObservedObject var vm: AuthViewModel
    var body: some View {
        VStack {
            Button("Se déconnecter") {
                vm.logoutAction()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .navigationTitle("Compte")
    }
}


