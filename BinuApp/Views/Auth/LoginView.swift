//
//  LoginView.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                }
                
                if let error = authVM.authError?.localizedDescription {
                    Text(error)
                        .foregroundColor(.red)
                }
                
                Button(action: {
                    isLoading = true
                    authVM.signIn(email: email, password: password) { success in
                        isLoading = false
                        if !success {
                            errorMessage = authVM.authError?.localizedDescription ?? "Login failed. Please try again."
                            showAlert = true
                        }
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Log In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isLoading)
            }
            .navigationTitle("Welcome Back")
            .alert("Login Error", isPresented: $showAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(errorMessage)
            })
        }
    }
}

#Preview {
    LoginView().environmentObject(AuthViewModel())
}

