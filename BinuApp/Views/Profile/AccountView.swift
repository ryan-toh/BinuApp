//
//  AccountView.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var isSigningOut = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let user = authVM.user {
                    VStack(spacing: 8) {
                        Text(user.username)
                            .font(.title2)
                            .bold()
                        Text(user.email)
                            .foregroundColor(.secondary)
                        Text("Gender: \(user.gender)")
                        Text("Age: \(user.age)")
                    }
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
                .disabled(isSigningOut)
                .padding()
            }
            .padding()
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
    AccountView().environmentObject(AuthViewModel())
}
