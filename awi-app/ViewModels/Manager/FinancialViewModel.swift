import SwiftUI

class FinancialViewModel: ObservableObject {
    @Published var loading = false
    @Published var errorMessage: String?

    func downloadBilanSession(sessionId: Int) async -> Data? {
        loading = true
        do {
            let pdfData = try await BilanService.shared.downloadBilanSession(sessionId: sessionId)
            await MainActor.run {
                self.loading = false
            }
            return pdfData
        } catch {
            await MainActor.run {
                self.errorMessage = "Erreur téléchargement bilan session: \(error)"
                self.loading = false
            }
            return nil
        }
    }

    func downloadBilanVendeur(vendeurId: Int, sessionId: Int) async -> Data? {
        loading = true
        do {
            let pdfData = try await BilanService.shared.downloadBilanVendeur(vendeurId: vendeurId, sessionId: sessionId)
            await MainActor.run {
                self.loading = false
            }
            return pdfData
        } catch {
            await MainActor.run {
                self.errorMessage = "Erreur téléchargement bilan vendeur: \(error)"
                self.loading = false
            }
            return nil
        }
    }
}
