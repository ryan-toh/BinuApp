import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject var forumVM = ForumViewModel()
    @StateObject var postVM = PostViewModel()
    @State var centralManager: CentralManager
    

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
        .accentColor(Color("FontColor")) // selected tab item tint
    }
}

#Preview {
    MainTabView(centralManager: CentralManager())
        .environmentObject(AuthViewModel())
}
