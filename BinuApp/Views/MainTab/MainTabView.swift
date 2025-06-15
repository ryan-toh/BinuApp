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

            PeerToPeerView()
                .tabItem {
                    Image(systemName: "phone.fill")
                    Text("Get Help")
                }

            LibraryView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Library")
                }

            AccountView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Account")
                }
        }
        .accentColor(Color("FontColor")) // ✅ selected tab item tint
        .environmentObject(ForumViewModel())
        .environmentObject(PeerToPeerViewModel())
        .environmentObject(LibraryViewModel())
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
