import Foundation

// HELLO
struct HealthSummary: Identifiable, Decodable {
    let id = UUID()
    let category: String
    let title: String
    let summary: String
    let source: String
}
