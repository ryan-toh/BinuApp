//
//  AccountView.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var accountVM: AccountViewModel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if accountVM.isLoading {
                    LoadingSpinnerView()
                } else if let error = accountVM.errorMessage {
                    ErrorBannerView(message: error)
                } else if let profile = accountVM.userProfile {
                    VStack {
                        Text("Welcome, \(profile.username)")
                            .font(.title2)
                        Text("Email: \(profile.email)")
                        // … other profile fields
                    }
                    .padding()
                } else {
                    Text("No profile data.")
                }
                
                Spacer()
                
                Button(action: {
                    authVM.signOut()
                }) {
                    Text("Sign Out")
                        .foregroundColor(.red)
                }
                .padding()
            }
            .navigationTitle("Account")
            .onAppear {
                if let uid = authVM.currentUser?.uid {
                    accountVM.fetchUserProfile(uid: uid)
                }
            }
        }
    }
}


#Preview {
    AccountView()
}
