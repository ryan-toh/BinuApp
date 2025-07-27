import Foundation

class LibraryViewModel: NSObject, ObservableObject, XMLParserDelegate {
    @Published var summaries: [HealthSummary] = []
    @Published var unWomenCards: [SupportCard] = []
    @Published var cnaCards: [SupportCard] = []
    
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDescription = ""
    private var insideItem = false
    private var currentSource: String = ""
    
    private let keywords = ["female", "women", "feminine", "girl", "girls", "woman", "period", "sexual"]

    override init() {
        super.init()
        loadLocalSummaries()
    }

    func loadAllFeeds() {
        unWomenCards = []
        cnaCards = []
        parseFeed(from: "https://www.unwomen.org/en/rss-feeds/news", source: "UN")
        parseFeed(from: "https://www.channelnewsasia.com/api/v1/rss-outbound-feed?_format=xml&category=10416", source: "CNA")
    }

    private func loadLocalSummaries() {
        summaries = [
            HealthSummary(
                category: "Sexual Health",
                title: "What is Sexual Health?",
                summary: "Sexual health is a state of physical, emotional, mental, and social well-being. It requires respect, safety, and freedom from discrimination and violence.",
                source: "https://www.who.int/health-topics/sexual-health"
            )
        ]
    }

    private func parseFeed(from urlString: String, source: String) {
        guard let url = URL(string: urlString),
              let parser = XMLParser(contentsOf: url) else {
            print("Failed to load RSS feed: \(urlString)")
            return
        }

        currentSource = source
        parser.delegate = self
        parser.parse()
    }

    // MARK: - XMLParserDelegate
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
