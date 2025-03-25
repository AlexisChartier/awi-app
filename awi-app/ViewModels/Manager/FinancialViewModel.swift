//
//  FinancialViewModel.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//
import SwiftUI
import QuickLook

struct IdentifiableURL: Identifiable {
    var id: String { url.absoluteString }
    let url: URL
}

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


    func loadData() {
        loading = true
        Task {
            do {
                let allSessions = try await SessionService.shared.getAll() // imagine
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
