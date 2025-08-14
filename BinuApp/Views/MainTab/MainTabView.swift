//
//  MainTabView.swift
//  BinuApp
//
//  Created by Ryan on 27/5/25.
//

import SwiftUI

/**
 The main navigation page for the app.
 */
struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject var forumVM = ForumViewModel()
    @StateObject var postVM = PostViewModel()
    @State var centralManager: CentralManager
    
    // Tab bar
    var body: some View {
        TabView {
            ForumView(centralManager: centralManager)
                .environmentObject(forumVM)
                .environmentObject(authVM)
                .environmentObject(postVM)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            LibraryView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Library for Him")
                }
            
            EmergencyView()
                .tabItem {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text("Emergency")
                }

            AccountView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Account")
                }
        }
        .accentColor(Color("FontColor"))
    }
}

#Preview {
    MainTabView(centralManager: CentralManager())
        .environmentObject(AuthViewModel())
}
