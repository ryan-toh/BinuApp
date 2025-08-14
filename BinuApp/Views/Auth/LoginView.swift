//
//  LoginView.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Color("BGColor")
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                // Back Button
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(Color("FontColor"))
                }

                // Welcome Text
                Text("Welcome Back")
                    .font(.largeTitle.bold())
                    .foregroundColor(Color("FontColor"))

                // Input Fields
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .foregroundColor(Color("FontColor"))
                        .onChange(of: email) { _ in errorMessage = "" }

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        .foregroundColor(Color("FontColor"))
                        .onChange(of: password) { _ in errorMessage = "" }
                }

                // Error Message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(Color("FontColor"))
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("FontColor").opacity(0.1))
                        )
                }

                // Login Button
                Button(action: {
                    isLoading = true
                    authVM.signIn(email: email, password: password) { success in
                        isLoading = false
                        if !success {
                            errorMessage = "Oops! We couldn’t log you in. Please check your email and password."
                            showAlert = true
                        }
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("FontColor"))
                            .cornerRadius(25)
                    } else {
                        Text("Log In")
                            .fontWeight(.bold)
                            .foregroundColor(Color("BGColor"))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("FontColor"))
                            .cornerRadius(25)
                    }
                }
                .disabled(isLoading)

                Spacer() // pushes everything up

            }
            .padding(.top, 40)
            .padding(.horizontal, 30)
        }
    }
}

#Preview {
    LoginView().environmentObject(AuthViewModel())
}
