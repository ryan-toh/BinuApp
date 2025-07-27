import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        TabView {
            ForumView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
//            PeripheralView()
//                .tabItem {
//                    Image(systemName: "phone.fill")
//                    Text("Send Request")
//                }
//            CentralView()
//                .tabItem {
//                    Image(systemName: "phone")
//                    Text("Receive Request")
//                }
            LibraryView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Library for Him")
                }

            AccountView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Account")
                }
        }
        .accentColor(Color("FontColor")) // selected tab item tint
        .environmentObject(ForumViewModel())
//        .environmentObject(PeerToPeerViewModel())
 //       .environmentObject(LibraryViewModel())
    }
    
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
