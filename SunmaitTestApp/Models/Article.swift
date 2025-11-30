import Foundation

// MARK: - Guardian API Response
struct GuardianResponse: Codable {
    let response: GuardianData
}

struct GuardianData: Codable {
    let status: String
    let total: Int
    let startIndex: Int
    let pageSize: Int
    let currentPage: Int
    let pages: Int
    let orderBy: String
    let results: [Article]
}

// MARK: - Article Fields (для thumbnail и trailText)
struct ArticleFields: Codable, Equatable {
    let thumbnail: String?
    let trailText: String?
}

// MARK: - Article Model
struct Article: Codable, Identifiable, Equatable {
    let id: String
    let type: String
    let sectionId: String
    let sectionName: String
    let webPublicationDate: String
    let webTitle: String
    let webUrl: String
    let apiUrl: String
    let isHosted: Bool
    let pillarId: String?
    let pillarName: String?
    let fields: ArticleFields?
    
    // MARK: - Computed Properties
    
    var formattedDate: String {
        let inputFormatter = ISO8601DateFormatter()
        inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = inputFormatter.date(from: webPublicationDate) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "MMM dd, yyyy"
            return outputFormatter.string(from: date)
        }
        
        // Fallback for dates without fractional seconds
        inputFormatter.formatOptions = [.withInternetDateTime]
        if let date = inputFormatter.date(from: webPublicationDate) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "MMM dd, yyyy"
            return outputFormatter.string(from: date)
        }
        
        return webPublicationDate
    }
    
    var articleURL: URL? {
        URL(string: webUrl)
    }
    
    var thumbnailURL: URL? {
        guard let thumbnail = fields?.thumbnail else { return nil }
        return URL(string: thumbnail)
    }
}

// MARK: - API Error Response
struct APIErrorResponse: Codable {
    let error: APIErrorDetails
}

struct APIErrorDetails: Codable {
    let statusCode: Int
    let reason: String
}

