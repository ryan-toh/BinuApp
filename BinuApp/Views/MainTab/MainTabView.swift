import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject var forumVM = ForumViewModel()
    @StateObject var postVM = PostViewModel()
    

    var body: some View {
        TabView {
            ForumView()
                .environmentObject(forumVM)
                .environmentObject(authVM)
                .environmentObject(postVM)
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
        .accentColor(Color("FontColor")) // selected tab item tint
//        .environmentObject(PeerToPeerViewModel())
 //       .environmentObject(LibraryViewModel())
    }
    
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
