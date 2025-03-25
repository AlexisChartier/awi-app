import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            VStack {
                Spacer(minLength: 40)
                
                // Logo ou illustration
                Image(systemName: "lock.shield.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    .padding(.bottom, 10)

                Text("Connexion")
                    .font(.title)
                    .fontWeight(.semibold)
                
                VStack(spacing: 16) {
                    // Champ Login
                    TextField("Identifiant", text: $authVM.login)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))

                    // Champ Password
                    SecureField("Mot de passe", text: $authVM.password)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))

                    // Message d’erreur avec animation
                    if let error = authVM.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal)

                // Bouton connexion
                Button(action: {
                    authVM.loginAction()
                }) {
                    if authVM.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    } else {
                        Text("Se connecter")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 20)

                Spacer()
            }
            .padding()
        }
        .onChange(of: authVM.isAuthenticated) { _, newValue in
            if newValue {
                // Navigation déclenchée par RootView si nécessaire
            }
        }
    }
}
