import SwiftUI

class SessionManagementViewModel: ObservableObject {
    @Published var sessions: [SessionAWI] = []
    @Published var loading: Bool = false
    @Published var errorMessage: String?

    func loadSessions() {
        loading = true
        Task {
            do {
                let fetched = try await SessionService.shared.fetchAllSessions()
                await MainActor.run {
                    self.sessions = fetched
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur chargement sessions: \(error)"
                    self.loading = false
                }
            }
        }
    }

    func createSession(_ session: SessionAWI) {
        loading = true
        Task {
            do {
                let newSess = try await SessionService.shared.createSession(session)
                await MainActor.run {
                    self.sessions.append(newSess)
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur création session: \(error)"
                    self.loading = false
                }
            }
        }
    }

    func deleteSession(_ sessionId: Int) {
        loading = true
        Task {
            do {
                try await SessionService.shared.deleteSession(id: sessionId)
                await MainActor.run {
                    self.sessions.removeAll { $0.id == sessionId }
                    self.loading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Erreur suppression session: \(error)"
                    self.loading = false
                }
            }
        }
    }
}
