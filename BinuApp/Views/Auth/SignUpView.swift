//
//  SignUpView.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var gender = ""
    @State private var age = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Account")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                }
                Section(header: Text("Profile")) {
                    TextField("Username", text: $username)
                    TextField("Gender", text: $gender)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                }
                if let error = authVM.authError?.localizedDescription {
                    Text(error)
                        .foregroundColor(.red)
                }
                Button(action: {
                    guard let ageInt = Int(age) else {
                        errorMessage = "Please enter a valid age."
                        showAlert = true
                        return
                    }
                    isLoading = true
                    authVM.signUp(email: email, password: password, username: username, gender: gender, age: ageInt) { success in
                        isLoading = false
                        if !success {
                            errorMessage = authVM.authError?.localizedDescription ?? "Sign up failed. Please try again."
                            showAlert = true
                        }
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Create Account")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isLoading)
            }
            .navigationTitle("Sign Up")
            .alert("Sign Up Error", isPresented: $showAlert, actions: {
                Button("OK", role: .cancel) { }
            }, message: {
                Text(errorMessage)
            })
        }
    }
}

#Preview {
    SignUpView().environmentObject(AuthViewModel())
}

