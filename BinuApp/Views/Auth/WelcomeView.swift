//
//  Login.swift
//  BinuApp
//
//  Created by Ryan on 25/5/25.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                Text("Welcome to Binu")
                    .font(.largeTitle)
                    .bold()
                Spacer()

                // Login Button
                NavigationLink("Log In", destination: LoginView())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)

                // Sign Up Button
                NavigationLink("Sign Up", destination: SignUpView())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("")           // hides the title
            .navigationBarHidden(true)     // hides the bar
        }
    }
}


#Preview {
    WelcomeView()
}
