//
//  SessionManagementViewModel.swift
//  awi-app
//
//  Created by etud on 17/03/2025.
//

import SwiftUI

/// ViewModel dédié à la gestion des sessions dans l'interface d'administration.
/// Permet de charger, créer, modifier et supprimer des sessions.
@MainActor
class SessionManagementViewModel: ObservableObject {
    // Liste des sessions
    @Published var sessions: [Session] = []
    @Published var errorMessage: String?
    @Published var loading = false

    // États de dialogues/formulaires
    @Published var showFormSheet = false
    @Published var isEditMode = false
    @Published var currentSession: Session?

    @Published var showDeleteDialog = false
    @Published var sessionToDelete: Session?

    // Champs liés au formulaire d'édition/création
    @Published var formNom: String = ""
    @Published var formDateDebut: Date = Date()
    @Published var formDateFin: Date = Date()
    @Published var formStatut: String = "inactive"
    @Published var formModeFrais: String = "fixe"
    @Published var formFrais: Double = 0
    @Published var formCommission: Double = 0

    var selectedSession: Session?

    /// Charge toutes les sessions depuis le backend
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

    /// Prépare le formulaire pour une création
    func openCreateSheet() {
        isEditMode = false
        currentSession = nil

        formNom = ""
        formDateDebut = Date()
        formDateFin = Date()
        formStatut = "inactive"
        formModeFrais = "fixe"
        formFrais = 0
        formCommission = 0

        showFormSheet = true
    }

    /// Prépare le formulaire pour une édition
    func openEditSheet(_ sess: Session) {
        isEditMode = true
        currentSession = sess

        formNom = sess.nom ?? ""
        formDateDebut = sess.dateDebut
        formDateFin = sess.dateFin
        formStatut = sess.statut
        formModeFrais = sess.modeFraisDepot
        formFrais = sess.fraisDepot
        formCommission = sess.commissionRate

        showFormSheet = true
    }

    /// Ferme le formulaire d'édition/création
    func closeFormSheet() {
        showFormSheet = false
        errorMessage = nil
    }

    /// Sauvegarde une session (création ou mise à jour)
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
                }
            }
        } else {
            // Création
            Task {
                do {
                    _ = try await SessionService.shared.create(
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

    /// Ouvre la boîte de dialogue de confirmation de suppression
    func openDeleteDialog(_ sess: Session) {
        sessionToDelete = sess
        showDeleteDialog = true
    }

    /// Ferme la boîte de dialogue de suppression
    func closeDeleteDialog() {
        sessionToDelete = nil
        showDeleteDialog = false
    }

    /// Confirme la suppression d’une session
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
