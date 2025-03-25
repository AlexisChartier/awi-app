//
//  FinancialViewModel.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//
import SwiftUI
import QuickLook

///Struct pour gérer l'affichage du fichier pdf téléchargé
struct IdentifiableURL: Identifiable {
    var id: String { url.absoluteString }
    let url: URL
}

///ViewModel pour la page de génération des bilans financiers
@MainActor
class FinancialViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var vendeurs: [Vendeur] = []
    @Published var selectedSession: Session?
    @Published var selectedVendeurId: Int?
    @Published var loading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var previewURL: IdentifiableURL? // <- pour QuickLook


    ///Charger les sessions et les vendeurs
    func loadData() {
        loading = true
        Task {
            do {
                let allSessions = try await SessionService.shared.getAll()
                self.sessions = allSessions
                if let first = allSessions.first {
                    self.selectedSession = first
                }
                let vend = try await VendeurService.shared.fetchAllVendeurs()
                self.vendeurs = vend
            } catch {
                self.errorMessage = "Erreur chargement sessions ou vendeurs"
            }
            self.loading = false
        }
    }

    ///Sauvegarder le bilan et l'afficher
    private func saveAndPreview(data: Data, filename: String) {
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(filename)

            do {
                try data.write(to: fileURL, options: .atomic)
                self.previewURL = IdentifiableURL(url: fileURL)
            } catch {
                self.errorMessage = "Erreur lors de la sauvegarde du PDF."
            }
        }
        
        ///Générer le bilan pour une session
        func generateSessionReport() {
            guard let ss = selectedSession else {
                errorMessage = "Aucune session sélectionnée."
                return
            }
            Task {
                do {
                    let pdfData = try await BilanService.shared.downloadBilanSession(sessionId: ss.id)
                    saveAndPreview(data: pdfData, filename: "bilan_session_\(ss.id).pdf")
                    successMessage = "Bilan session #\(ss.id) prêt à être affiché"
                } catch {
                    errorMessage = "Erreur lors de la génération du bilan de session"
                }
            }
        }
        ///Générer le bilan pour une session et un vendeur spécifique
        func generateVendorReport() {
            guard let ss = selectedSession,
                  let vid = selectedVendeurId else {
                errorMessage = "Veuillez sélectionner un vendeur et une session."
                return
            }
            Task {
                do {
                    let pdfData = try await BilanService.shared.downloadBilanVendeur(vendeurId: vid, sessionId: ss.id)
                    saveAndPreview(data: pdfData, filename: "bilan_vendeur_\(vid)_session_\(ss.id).pdf")
                    successMessage = "Bilan vendeur prêt à être affiché"
                } catch {
                    errorMessage = "Erreur génération bilan vendeur"
                }
            }
        }
}
