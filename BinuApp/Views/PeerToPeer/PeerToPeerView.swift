import SwiftUI

struct PeerToPeerView: View {
    @State private var searchText: String = ""
    @State private var recentSearches: [String] = []
    private let suggestedItems = ["pads", "tampons", "contraception", "tissue", "morning after pill"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("BGColor").ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Title
                    Text("Peer to Peer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color("FontColor"))
                        .padding(.horizontal)

                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("What’s the emergency?", text: $searchText, onCommit: {
                            handleSearch()
                        })
                        .foregroundColor(.black)
                        .submitLabel(.done)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Recent Searches
                    if !recentSearches.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent")
                                .font(.headline)
                                .foregroundColor(.black)
                            
                            ForEach(recentSearches, id: \.self) { item in
                                Text(item)
                                    .foregroundColor(.black)
                                    .padding(.vertical, 2)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    // Suggestions
                    Text("Suggestions")
                        .font(.headline)
                        .foregroundColor(Color("FontColor"))
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(suggestedItems, id: \.self) { item in
                            Button(action: {
                                searchText = item
                                handleSearch()
                            }) {
                                Text(item)
                                    .foregroundColor(Color("BGColor"))
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 16)
                                    .background(Color("FontColor"))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top)
            }
        }
    }
    
    private func handleSearch() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Simulated broadcast
        print("Broadcasting request for: \(trimmed)")

        // Add to recent
        if !recentSearches.contains(trimmed) {
            recentSearches.insert(trimmed, at: 0)
            if recentSearches.count > 3 {
                recentSearches.removeLast()
            }
        }

        searchText = ""
    }
}

#Preview {
    PeerToPeerView()
}


struct WrapHStack<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content
    
    init(items: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.items = items
        self.content = content
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
            ForEach(items, id: \.self) { item in
                content(item)
            }
        }
    }
}

