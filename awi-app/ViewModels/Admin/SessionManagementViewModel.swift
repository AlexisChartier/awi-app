//
//  SessionManagementViewModel.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//

import SwiftUI

@MainActor
class SessionManagementViewModel: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var errorMessage: String?
    @Published var loading = false

    // Dialogs
    @Published var showFormSheet = false
    @Published var isEditMode = false
    @Published var currentSession: Session?
    
    @Published var showDeleteDialog = false
    @Published var sessionToDelete: Session?

    // Champs qu’on va binder dans le formulaire
    @Published var formNom: String = ""
    @Published var formDateDebut: Date = Date()
    @Published var formDateFin: Date = Date()
    @Published var formStatut: String = "inactive"
    @Published var formModeFrais: String = "fixe"
    @Published var formFrais: Double = 0
    @Published var formCommission: Double = 0
    
    var selectedSession: Session?

    func loadSessions() {
        loading = true
        Task {
            do {
                let list = try await SessionService.shared.getAll()
                self.sessions = list
            } catch {
                errorMessage = "Erreur chargement sessions"
            }
            loading = false
        }
    }

    func openCreateSheet() {
        isEditMode = false
        currentSession = nil
        
        // On ré-initialise les champs du formulaire
        formNom = ""
        formDateDebut = Date()
        formDateFin = Date()
        formStatut = "inactive"
        formModeFrais = "fixe"
        formFrais = 0
        formCommission = 0
        
        showFormSheet = true
    }

    func openEditSheet(_ sess: Session) {
        isEditMode = true
        currentSession = sess
        
        formNom = sess.nom ?? ""
        formDateDebut = sess.dateDebut
        formDateFin   = sess.dateFin
        formStatut    = sess.statut
        formModeFrais = sess.modeFraisDepot
        formFrais     = sess.fraisDepot
        formCommission = sess.commissionRate
        
        showFormSheet = true
    }

    func closeFormSheet() {
        showFormSheet = false
        errorMessage = nil
    }

    func saveSession() {
        if isEditMode, let s = currentSession {
            // Mise à jour
            Task {
                do {
                    _ = try await SessionService.shared.update(
                        sessionId: s.id,
                        data: Session(
                            id: s.id,
                            nom: formNom,
                            dateDebut: formDateDebut,
                            dateFin: formDateFin,
                            statut: formStatut,
                            modeFraisDepot: formModeFrais,
                            fraisDepot: formFrais,
                            commissionRate: formCommission,
                            administrateurId: s.administrateurId
                        )
                    )
                    loadSessions()
                    showFormSheet = false
                } catch {
                    self.errorMessage = "Erreur enregistrement session"
                    print(error)
                }
            }
        } else {
            // Création
            Task {
                do {
                    let _ = try await SessionService.shared.create(
                        data: Session(
                            id: 0,
                            nom: formNom,
                            dateDebut: formDateDebut,
                            dateFin: formDateFin,
                            statut: formStatut,
                            modeFraisDepot: formModeFrais,
                            fraisDepot: formFrais,
                            commissionRate: formCommission,
                            administrateurId: nil
                        )
                    )
                    loadSessions()
                    showFormSheet = false
                } catch {
                    self.errorMessage = "Erreur création session"
                }
            }
        }
    }

    func openDeleteDialog(_ sess: Session) {
        sessionToDelete = sess
        showDeleteDialog = true
    }
    func closeDeleteDialog() {
        sessionToDelete = nil
        showDeleteDialog = false
    }
    func confirmDelete() {
        guard let sdel = sessionToDelete else { return }
        Task {
            do {
                try await SessionService.shared.remove(sessionId: sdel.id)
                loadSessions()
            } catch {
                errorMessage = "Erreur suppression session"
            }
            sessionToDelete = nil
            showDeleteDialog = false
        }
    }
}
