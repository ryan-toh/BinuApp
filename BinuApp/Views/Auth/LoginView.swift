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
    
    var body: some View {
        Form {
            Section(header: Text("Log In")) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                SecureField("Password", text: $password)
            }
            
            if let error = authVM.authErrorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            
            Button(action: {
                authVM.signIn(email: email, password: password)
            }) {
                Text("Log In")
                    .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Log In")
    }
}

#Preview {
    LoginView()
}
