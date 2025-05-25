//
//  TestAuthView.swift
//  BinuApp
//
//  Created by Ryan on 25/5/25.
//

import SwiftUI

struct TestAuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var statusMessage = ""
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Auth Service Tester")
                .font(.title)
                .padding(.top)

            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            HStack(spacing: 12) {
                Button(action: createUser) {
                    labelText("Sign Up")
                }
                .disabled(isProcessing)

                Button(action: signIn) {
                    labelText("Sign In")
                }
                .disabled(isProcessing)

                Button(action: signOut) {
                    labelText("Sign Out")
                }
                .disabled(isProcessing)
            }

            if isProcessing {
                ProgressView()
                    .padding()
            }

            Text(statusMessage)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()

            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private func labelText(_ text: String) -> some View {
        Text(text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
    }

    private func createUser() {
        authAction { completion in
            AuthService.createUser(email: email, password: password, completion: completion)
        }
    }

    private func signIn() {
        authAction { completion in
            AuthService.signIn(email: email, password: password, completion: completion)
        }
    }

    private func signOut() {
        authAction { completion in
            AuthService.signOut(completion: completion)
        }
    }

    private func authAction(
        _ call: (@escaping (Result<String, Error>) -> Void) -> Void
    ) {
        statusMessage = ""
        isProcessing = true

        call { result in
            DispatchQueue.main.async {
                isProcessing = false
                switch result {
                case .success(let msg):
                    statusMessage = msg
                case .failure(let error):
                    statusMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    TestAuthView()
}
