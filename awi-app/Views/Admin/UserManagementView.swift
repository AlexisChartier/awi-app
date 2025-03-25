import SwiftUI

struct UserManagementView: View {
    @StateObject var vm = UserManagementViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ⚠️ Message d'erreur
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

                if vm.loading {
                    Spacer()
                    ProgressView("Chargement utilisateurs...")
                    Spacer()
                } else {
                    VStack(spacing: 16) {
                        // 🧭 Barre haute
                        HStack {
                            Text("👥 \(vm.utilisateurs.count) utilisateur(s)")
                                .font(.headline)
                            Spacer()
                            Button {
                                vm.openCreateSheet()
                            } label: {
                                Label("Ajouter", systemImage: "plus")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.horizontal)

                        // 📋 Liste utilisateurs
                        List {
                            ForEach(vm.utilisateurs, id: \.id) { user in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(user.nom)
                                            .font(.headline)
                                        Spacer()
                                        Text(user.role.rawValue.capitalized)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                    Text(user.email)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 4)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        vm.openDeleteDialog(user)
                                    } label: {
                                        Label("Supprimer", systemImage: "trash")
                                    }

                                    Button {
                                        vm.openEditSheet(user)
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
            }
            .navigationTitle("Utilisateurs")
            .onAppear {
                vm.loadUsers()
            }
            .alert("Supprimer utilisateur ?", isPresented: $vm.showDeleteDialog) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    vm.confirmDelete()
                }
            } message: {
                if let user = vm.userToDelete {
                    Text("Voulez-vous vraiment supprimer \(user.nom) ?")
                }
            }
            .sheet(isPresented: $vm.showFormSheet) {
                UserFormSheet(vm: vm)
            }
        }
    }
}



struct UserFormSheet: View {
    @ObservedObject var vm: UserManagementViewModel

    var isEditing: Bool {
        vm.isEditMode
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Informations de l'utilisateur")) {
                    TextField("Nom", text: $vm.formNom)
                    TextField("Email", text: $vm.formEmail)
                        .keyboardType(.emailAddress)
                    TextField("Téléphone", text: $vm.formTelephone)
                        .keyboardType(.phonePad)
                    TextField("Login", text: $vm.formLogin)
                }

                Section(header: Text("Rôle")) {
                    Picker("Rôle", selection: $vm.formRole) {
                        ForEach(UserRole.allCases, id: \.self) { r in
                            Text(r.rawValue.capitalized).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)
                }

                Section(header: Text("Mot de passe")) {
                    SecureField("Mot de passe", text: $vm.formPassword)
                }
            }
            .navigationTitle(isEditing ? "Modifier Utilisateur" : "Nouvel Utilisateur")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Valider") {
                        vm.saveUser()
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
