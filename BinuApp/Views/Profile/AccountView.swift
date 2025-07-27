import SwiftUI

struct AccountView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var isSigningOut = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingEditProfile = false

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
                    
                    // edit profile
                    Button {
                        showingEditProfile = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil.circle.fill")
                            Text("Edit Profile")
                        }
                        .font(.body.bold())
                        .foregroundColor(Color("FontColor"))
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color("PostBackground"))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .sheet(isPresented: $showingEditProfile) {
                        EditProfileView()
                            .environmentObject(authVM)
                    }

                    
                    // sign out
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
                                .foregroundColor(Color("BGColor"))
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color("FontColor"))
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .disabled(isSigningOut)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Account")
                        .font(.title.bold())
                        .foregroundColor(Color("FontColor"))
                }
            }
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
