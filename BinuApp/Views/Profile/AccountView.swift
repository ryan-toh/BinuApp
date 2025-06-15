import SwiftUI

struct AccountView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var isSigningOut = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BGColor").ignoresSafeArea()

                VStack(spacing: 20) {
                    if let user = authVM.user {
                        VStack(spacing: 8) {
                            Text(user.username)
                                .font(.title2)
                                .bold()
                                .foregroundColor(.black)

                            Text(user.email)
                                .foregroundColor(.secondary)

                            Text("Gender: \(user.gender)")
                                .foregroundColor(.black)

                            Text("Age: \(user.age)")
                                .foregroundColor(.black)
                        }
                        .padding()
                        .background(Color("PostBackground"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.05), lineWidth: 1)
                        )
                    } else {
                        Text("No Profile Data")
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Button(action: {
                        isSigningOut = true
                        authVM.signOut { success in
                            isSigningOut = false
                            if !success {
                                errorMessage = authVM.authError?.localizedDescription ?? "Sign out failed. Please try again."
                                showError = true
                            }
                        }
                    }) {
                        if isSigningOut {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign Out")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
                    .disabled(isSigningOut)
                }
                .padding()
            }
            .navigationTitle("Account")
            .alert("Sign Out Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    let mockAuthVM = AuthViewModel()
    mockAuthVM.user = UserModel(
        id: "user123",
        email: "demo@mock.com",
        username: "CoolRyan",
        gender: "Male",
        age: 28
    )
    
    return AccountView()
        .environmentObject(mockAuthVM)
}
