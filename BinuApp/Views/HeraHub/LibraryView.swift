import SwiftUI

struct LibraryView: View {
    let topics = ["Periods & Cramps", "Sexual Health", "Consent", "Emotional Support"]

    // Content Cards under "support your partner during her period..."
    let supportCards: [SupportCard] = [
        .init(title: "Coping with cramps", image: "period"), // period.jpg should be in Assets
        .init(title: "Quick pain relief tips"),
        .init(title: "What’s causing her cramps"),
        .init(title: "The science behind it"),
        .init(title: "Sex during period"),
        .init(title: "How to stay safe"),
        .init(title: "Does period sex really prevent pregnancy?")
    ]
    

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BGColor").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        Text("For Him")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.black)
                            .padding(.horizontal)

                        // Section 1
                        Text("Understand....")
                            .font(.headline)
                            .foregroundColor(Color("FontColor"))
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(topics, id: \.self) { topic in
                                    NavigationLink(destination:
                                        Text("\(topic)\n(Coming Soon)")
                                            .padding()
                                            .navigationTitle(topic)
                                    ) {
                                        Text(topic)
                                            .foregroundColor(Color("BGColor"))
                                            .padding()
                                            .background(Color("FontColor"))
                                            .cornerRadius(20)
                                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Section 2
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Support your partner during her period...")
                                .font(.headline)
                                .foregroundColor(Color("FontColor"))

                            ForEach(supportCards) { card in
                                NavigationLink(destination:
                                    Text("\(card.title)\n(Coming Soon)")
                                        .padding()
                                        .navigationTitle(card.title)
                                ) {
                                    ZStack(alignment: .bottomLeading) {
                                        if let imageName = card.image {
                                            Image(imageName)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 120)
                                                .clipped()
                                        } else {
                                            Color.white
                                                .frame(height: 100)
                                        }

                                        Text(card.title)
                                            .foregroundColor(.black)
                                            .font(.subheadline)
                                            .bold()
                                            .padding()
                                            .background(Color.white.opacity(0.7))
                                            .cornerRadius(10)
                                            .padding([.bottom, .leading], 10)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                        .padding(.horizontal)

                        Spacer(minLength: 40)
                    }
                    .padding(.top)
                }
            }
        }
    }
}

// MARK: - Model
struct SupportCard: Identifiable {
    let id = UUID()
    let title: String
    let image: String?

    init(title: String, image: String? = nil) {
        self.title = title
        self.image = image
    }
}

// MARK: - Preview
#Preview {
    LibraryView()
}
