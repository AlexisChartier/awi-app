import SwiftUI

@MainActor
class FinancialViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var vendeurs: [Vendeur] = []
    @Published var selectedSession: Session?
    @Published var selectedVendeurId: Int?
    @Published var loading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

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

    func generateSessionReport() {
        guard let ss = selectedSession else {
            errorMessage = "Aucune session sélectionnée."
            return
        }
        Task {
            do {
                let pdfData = try await BilanService.shared.downloadBilanSession(sessionId: ss.id)
                // En SwiftUI, pour “sauvegarder” un PDF, c’est plus compliqué
                // On peut le stocker dans le FileManager, ou l’ouvrir via QuickLook
                // On simule un “succès”
                successMessage = "Bilan session #\(ss.id) téléchargé!"
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
                successMessage = "Bilan financier vendeur #\(vid) OK!"
            } catch {
                errorMessage = "Erreur génération bilan vendeur"
            }
        }
    }
}
