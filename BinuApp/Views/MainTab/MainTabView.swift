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
            
//            BeaconSenderView()
//                .tabItem {
//                    Label("Get Help", systemImage: "phone.fill")
//                }
            HelpRequestView()
                .tabItem {
                    Label("Provide Help", systemImage: "cross.case")
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
        .environmentObject(LibraryViewModel())
        .environmentObject(HelpRequestViewModel(userId: authVM.user?.id ?? ""))
    }
}


#Preview {
    MainTabView()
}
