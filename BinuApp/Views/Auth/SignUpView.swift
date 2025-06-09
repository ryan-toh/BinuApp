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
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("")) {
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
                    authVM.signUp(email: email, password: password)
                }) {
                    Text("Create Account")
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Sign Up")
        }

    }
}

#Preview {
    SignUpView().environmentObject(AuthViewModel())
}
