//
//  MainTabView.swift
//  BinuApp
//
//  Created by Ryan on 1/6/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        TabView {
            ForumView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            PeerToPeerView()
                .tabItem {
                    Label("Get Help", systemImage: "phone.fill")
                }
            
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "book.fill")
                }
            
            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person.crop.circle")
                }
        }
        .environmentObject(ForumViewModel())
        .environmentObject(PeerToPeerViewModel())
        .environmentObject(LibraryViewModel())
//        .environmentObject(AccountViewModel())
    }
}


#Preview {
    MainTabView()
}
