//
//  AdminTabView.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//


import SwiftUI

struct AdminTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                UserManagementView()
            }
            .tabItem {
                Label("Utilisateurs", systemImage: "person.2.fill")
            }

            NavigationStack {
                SessionManagementView()
            }
            .tabItem {
                Label("Sessions", systemImage: "calendar.badge.clock")
            }

            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar.xaxis")
            }
        }
    }
}
