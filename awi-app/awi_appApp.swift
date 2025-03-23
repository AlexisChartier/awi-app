//
//  awi_appApp.swift
//  awi-app
//
//  Created by etud on 15/03/2025.
//

import SwiftUI

@main
struct awi_appApp: App {
    @StateObject var authVM = AuthViewModel()

        var body: some Scene {
            WindowGroup {
                /// On affiche une vue racine RootView
                /// qui décide où aller selon isAuthenticated, userRole, etc.
                RootView()
                    .environmentObject(authVM)
            }
        }
    }
