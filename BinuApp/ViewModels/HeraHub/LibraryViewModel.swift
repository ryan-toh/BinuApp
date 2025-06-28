import Foundation

class LibraryViewModel: ObservableObject {
    @Published var summaries: [HealthSummary] = []

    init() {
        loadLocalSummaries()
    }

    private func loadLocalSummaries() {
        summaries = [
            HealthSummary(
                category: "Sexual Health",
                title: "What is Sexual Health?",
                summary: "Sexual health is a state of physical, emotional, mental, and social well-being. It requires respect, safety, and freedom from discrimination and violence.",
                source: "https://www.who.int/health-topics/sexual-health"
            ),
            // Add more HealthSummary items as needed
        ]
    }
}
