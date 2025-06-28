import SwiftUI
import Foundation

// MARK: - Model
struct SupportCard: Identifiable {
    let id = UUID()
    let title: String
    let link: String?
    let image: String?

    init(title: String, link: String? = nil, image: String? = nil) {
        self.title = title
        self.link = link
        self.image = image
    }
}

// MARK: - Combined RSS Feed Loader (UN Women + CNA)
class CombinedFeedLoader: NSObject, XMLParserDelegate, ObservableObject {
    @Published var unWomenCards: [SupportCard] = []
    @Published var cnaCards: [SupportCard] = []

    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDescription = ""
    private var insideItem = false
    private var currentSource: String = ""

    private let keywords = ["female", "women", "feminine", "girl", "girls", "woman", "period", "sexual"]

    func loadFeeds() {
        unWomenCards = []
        cnaCards = []
        parseFeed(from: "https://www.unwomen.org/en/rss-feeds/news", source: "UN")
        parseFeed(from: "https://www.channelnewsasia.com/api/v1/rss-outbound-feed?_format=xml&category=10416", source: "CNA")
    }

    private func parseFeed(from urlString: String, source: String) {
        guard let url = URL(string: urlString), let parser = XMLParser(contentsOf: url) else {
            print("Failed to load RSS feed: \(urlString)")
            return
        }
        currentSource = source
        parser.delegate = self
        parser.parse()
    }

    // MARK: - XML Parsing
    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            insideItem = true
            currentTitle = ""
            currentLink = ""
            currentDescription = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard insideItem else { return }
        switch currentElement {
        case "title": currentTitle += string
        case "link": currentLink += string
        case "description": currentDescription += string
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            let fullText = (currentTitle + " " + currentDescription).lowercased()
            let matches = keywords.contains { fullText.contains($0) }

            if matches {
                let trimmedTitle = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedLink = currentLink.trimmingCharacters(in: .whitespacesAndNewlines)
                let card = SupportCard(title: trimmedTitle, link: trimmedLink)
                if currentSource == "UN" {
                    unWomenCards.append(card)
                } else if currentSource == "CNA" {
                    cnaCards.append(card)
                }
            }

            insideItem = false
        }
    }
}

// MARK: - Main View
struct LibraryView: View {
    let topics = ["Periods & Cramps", "Sexual Health", "Consent", "Emotional Support"]
    @StateObject private var feedLoader = CombinedFeedLoader()
    @State private var summaries: [HealthSummary] = loadSummaries()
    
    init(summaries: [HealthSummary] = loadSummaries()) {
        _summaries = State(initialValue: summaries)
    }

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

        

                        // Section 2 - WHO Local JSON Summaries
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Understand from WHO...")
                                .font(.headline)
                                .foregroundColor(Color("FontColor"))
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(summaries.prefix(7)) { item in
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(item.category)
                                                .font(.caption)
                                                .foregroundColor(Color("BGColor"))

                                            Text(item.title)
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundColor(Color("BGColor"))

                                            Text(item.summary)
                                                .font(.footnote)
                                                .foregroundColor(.black)
                                                .lineLimit(3)

                                            if let url = URL(string: item.source) {
                                                Link("Read more on WHO", destination: url)
                                                    .font(.caption)
                                                    .foregroundColor(Color("BGColor"))
                                            }
                                        }
                                        .padding()
                                        .frame(width: 280, height: 180)
                                        .background(Color("FontColor"))
                                        .cornerRadius(16)
                                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // Section 3 - UN Women
                        VStack(alignment: .leading, spacing: 12) {
                            Text("UN Women: Stay updated about women's health issues globally...")
                                .font(.headline)
                                .foregroundColor(Color("FontColor"))
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(feedLoader.unWomenCards.prefix(7)) { card in
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(card.title)
                                                .foregroundColor(Color("FontColor"))
                                                .font(.subheadline)
                                                .bold()

                                            if let urlString = card.link,
                                               let url = URL(string: urlString) {
                                                Link("Read more...", destination: url)
                                                    .font(.footnote)
                                                    .foregroundColor(.black)
                                            }
                                        }
                                        .padding()
                                        .frame(width: 280, height: 120)
                                        .background(Color.white.opacity(0.8))
                                        .cornerRadius(16)
                                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // Section 4 - CNA
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CNA: Stay updated about women's health issues in Singapore...")
                                .font(.headline)
                                .foregroundColor(Color("FontColor"))
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(feedLoader.cnaCards.prefix(7)) { card in
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(card.title)
                                                .foregroundColor(Color("FontColor"))
                                                .font(.subheadline)
                                                .bold()

                                            if let urlString = card.link,
                                               let url = URL(string: urlString) {
                                                Link("Read more...", destination: url)
                                                    .font(.footnote)
                                                    .foregroundColor(.black)
                                            }
                                        }
                                        .padding()
                                        .frame(width: 280, height: 120)
                                        .background(Color.white.opacity(0.8))
                                        .cornerRadius(16)
                                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top)
                }
            }
            .onAppear {
                feedLoader.loadFeeds()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    LibraryView(summaries: [
        HealthSummary(
            category: "Sexual Health",
            title: "What is Sexual Health?",
            summary: "Sexual health is a state of physical, emotional, mental, and social well-being. It requires respect, safety, and freedom from discrimination and violence.",
            source: "https://www.who.int/health-topics/sexual-health"
        )
    ])
}

