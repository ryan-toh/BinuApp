//
//  WelcomeView.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import SwiftUI

/**
 Simple login page with some styling
 */
struct WelcomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.colorScheme) var colorScheme

    @State private var showLogin = false
    @State private var showSignUp = false

    var body: some View {
        ZStack {
            // Background
            Color("BGColor")
                .ignoresSafeArea()

            VStack {
                Spacer()

                // Logo and Tagline aligned to center-left
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 20) {
                        LogoView()
                            .scaleEffect(2.0)

                        Text("A safe space for Her, for Him.")
                            .foregroundColor(Color("FontColor"))
                            .font(.headline)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, 30)
                    Spacer()
                }
                Spacer()

                // Bottom Buttons
                VStack(spacing: 20) {
                    Button(action: { showLogin = true }) {
                        Text("Login")
                            .fontWeight(.bold)
                            .foregroundColor(Color("BGColor"))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("FontColor"))
                            .cornerRadius(25)
                    }
                    .fullScreenCover(isPresented: $showLogin) {
                        LoginView().environmentObject(authVM)
                    }

                    Button(action: { showSignUp = true }) {
                        Text("Register")
                            .fontWeight(.bold)
                            .foregroundColor(Color("BGColor"))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color("FontColor"))
                            .cornerRadius(25)
                    }
                    .fullScreenCover(isPresented: $showSignUp) {
                        SignUpView().environmentObject(authVM)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

#Preview {
    WelcomeView().environmentObject(AuthViewModel())
}
