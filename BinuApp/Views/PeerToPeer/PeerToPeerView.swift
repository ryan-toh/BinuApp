import SwiftUI

struct PeerToPeerView: View {
    @State private var showAlert = false
    @State private var navigateToMap = false
    @State private var selectedItem: String = ""
    @State private var customInput: String = ""
    @State private var recentRequests: [String] = []

    let username = "eungi"
    private let suggestedItems = ["Pads", "Tampons", "Contraception", "Tissue", "Morning after pill"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BGColor").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text("Peer to Peer")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(Color("FontColor"))
                        .padding(.horizontal)

                    Text("What's the emergency?")
                        .font(.headline)
                        .foregroundColor(Color("FontColor"))
                        .padding(.horizontal)

                    // Custom input box
                    HStack {
                        TextField("What do you need?", text: $customInput)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal)
                            .frame(height: 44)
                            .background(Color.white)
                            .cornerRadius(10)
                            .onSubmit {
                                handleRequest(customInput)
                            }

                        Button(action: {
                            handleRequest(customInput)
                        }) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                                .foregroundColor(Color("FontColor"))
                        }
                    }
                    .padding(.horizontal)

                    // Recent Requests
                    if !recentRequests.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recent Requests")
                                .font(.headline)
                                .foregroundColor(Color("FontColor"))
                                .padding(.horizontal)

                            ForEach(recentRequests.prefix(3), id: \.self) { request in
                                Text(request)
                                    .foregroundColor(.black)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 14)
                                    .background(Color.white.opacity(0.9))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    // Suggested buttons
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(suggestedItems, id: \.self) { item in
                            Button(action: {
                                handleRequest(item)
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

                    NavigationLink(
                        destination: BroadcastMapView(requestType: selectedItem, username: username),
                        isActive: $navigateToMap
                    ) {
                        EmptyView()
                    }
                    .hidden()
                }
                .padding(.top)
            }
            .alert("Would you like to request for \(selectedItem) from nearby women?", isPresented: $showAlert) {
                Button("No", role: .cancel) {
                    customInput = ""
                }
                Button("Yes") {
                    navigateToMap = true
                }
            }
        }
    }

    private func handleRequest(_ input: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        selectedItem = trimmed
        showAlert = true

        // Update recent requests, keeping only unique and most recent 3
        if let existingIndex = recentRequests.firstIndex(of: trimmed) {
            recentRequests.remove(at: existingIndex)
        }
        recentRequests.insert(trimmed, at: 0)
        if recentRequests.count > 3 {
            recentRequests = Array(recentRequests.prefix(3))
        }

        customInput = ""
    }
}

#Preview {
    PeerToPeerView()
}
