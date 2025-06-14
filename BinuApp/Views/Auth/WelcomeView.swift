//
//  Login.swift
//  BinuApp
//
//  Created by Ryan on 25/5/25.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.colorScheme) var colorScheme

    @State private var showLogin = false
    @State private var showSignUp = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack {
                HStack {
                    LogoView()
                    Spacer()
                }
                VStack(spacing: 5) {
                    Text("""
                         Welcome
                         to
                         Binu
                         """)
                        .font(.largeTitle.bold())
                        .foregroundColor(Color.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("""
                         Women's Health,
                         Made Accessible.
                         """)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(20)
                Spacer()
            }
            .padding(.vertical, 80)
            .padding(.leading, 20)
            
            Spacer()
            
            VStack {
                // Login Button
                Button(action: { showLogin = true }) {
                    Text("Login")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .bold()
                .controlSize(.large)
                .sheet(isPresented: $showLogin) {
                    LoginView()
                        .environmentObject(authVM)
                }
                // Sign Up Button
                Button(action: { showSignUp = true }) {
                    Text("Register")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BorderedButtonStyle())
                .bold()
                .controlSize(.large)
                .sheet(isPresented: $showSignUp) {
                    SignUpView()
                        .environmentObject(authVM)
                }
            }
            .padding(25)
            .clipShape(
                RoundedRectangle(cornerRadius: 40)
            )
            .background(
                RoundedRectangle(cornerRadius: 40)
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .opacity(0.8)
            )
        }
        .padding()
        .navigationTitle("")           // hides the title
        .navigationBarHidden(true)     // hides the bar
        .background(GIFView(gifName: "waves").opacity(0.5))
        .ignoresSafeArea()
    }
}


#Preview {
    WelcomeView().environmentObject(AuthViewModel())
}
