//
//  SessionManagementView.swift
//  awi-app
//
//  Created by etud on 19/03/2025.
//
import SwiftUI

struct SessionManagementView: View {
    @StateObject var vm = SessionManagementViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // ⚠️ Alerte
                if let err = vm.errorMessage {
                    HStack {
                        Label(err, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Spacer()
                        Button {
                            vm.errorMessage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.05))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }

                // 🧭 En-tête
                HStack {
                    Text("📅 \(vm.sessions.count) session(s)")
                        .font(.headline)
                    Spacer()
                    Button {
                        vm.openCreateSheet()
                    } label: {
                        Label("Nouvelle session", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)

                // 📋 Liste
                if vm.loading {
                    Spacer()
                    ProgressView("Chargement sessions...")
                    Spacer()
                } else {
                    List {
                        ForEach(vm.sessions, id: \.id) { session in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(session.nom ?? "Session sans nom")
                                        .font(.headline)
                                    Spacer()
                                    if session.statut == "active" {
                                        Label("Active", systemImage: "checkmark.seal.fill")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    } else {
                                        Label("Inactive", systemImage: "xmark.seal")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }

                                HStack {
                                    Text("📅 \(formattedDate(session.dateDebut)) → \(formattedDate(session.dateFin))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Text("💰 Frais : \(session.fraisDepot, format: .number)\(session.modeFraisDepot == "pourcentage" ? "%" : "€") • Commission : \(session.commissionRate, format: .number)%")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 6)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    vm.openDeleteDialog(session)
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }

                                Button {
                                    vm.openEditSheet(session)
                                } label: {
                                    Label("Modifier", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Sessions")
            .onAppear {
                vm.loadSessions()
            }
            .alert("Supprimer session ?", isPresented: $vm.showDeleteDialog) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    vm.confirmDelete()
                }
            } message: {
                if let session = vm.sessionToDelete {
                    Text("Voulez-vous vraiment supprimer la session « \(session.nom ?? "") » ?")
                }
            }
            .sheet(isPresented: $vm.showFormSheet) {
                SessionFormSheet(vm: vm)
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }
}



// MARK: - Sous-vue pour une rangée
struct SessionRowView: View {
    let session: Session
    let onTapEdit: () -> Void
    let onTapDelete: () -> Void

    // Un DateFormatter statique pour afficher nos dates
    private static let dateFormatter: DateFormatter = {
       let df = DateFormatter()
       df.dateFormat = "yyyy-MM-dd"
       return df
    }()

    var body: some View {
        let idString = "#\(session.id) \(session.nom ?? "")"
        // Conversion Date -> String
        let dateDebutStr = Self.dateFormatter.string(from: session.dateDebut)
        let dateFinStr   = Self.dateFormatter.string(from: session.dateFin)

        HStack {
            Text(idString)
            Spacer()
            Text(dateDebutStr)
            Text("->")
            Text(dateFinStr)
            Text("(\(session.statut))")
        }
        .contentShape(Rectangle()) // permet le onTapGesture sur tout le HStack
        .onTapGesture {
            onTapEdit()
        }
        .contextMenu {
            Button("Editer") {
                onTapEdit()
            }
            Button("Supprimer", role: .destructive) {
                onTapDelete()
            }
        }
    }
}

struct SessionFormSheet: View {
    @ObservedObject var vm: SessionManagementViewModel

    var isEditing: Bool {
        vm.isEditMode
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Informations de la session")) {
                    TextField("Nom", text: $vm.formNom)

                    DatePicker("Début", selection: $vm.formDateDebut, displayedComponents: .date)
                    DatePicker("Fin", selection: $vm.formDateFin, displayedComponents: .date)

                    Picker("Statut", selection: $vm.formStatut) {
                        Text("Inactive").tag("inactive")
                        Text("Active").tag("active")
                    }
                    .pickerStyle(.segmented)

                    TextField("Frais dépôt", value: $vm.formFrais, format: .number)
                        .keyboardType(.decimalPad)

                    Picker("Mode frais", selection: $vm.formModeFrais) {
                        Text("Pourcentage").tag("pourcentage")
                        Text("Fixe (€)").tag("fixe")
                    }
                    .pickerStyle(.segmented)

                    TextField("Commission %", value: $vm.formCommission, format: .number)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(isEditing ? "Modifier Session" : "Nouvelle Session")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Valider") {
                        vm.saveSession()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        vm.closeFormSheet()
                    }
                }
            }
        }
    }
}
